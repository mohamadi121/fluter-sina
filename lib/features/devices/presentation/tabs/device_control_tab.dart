import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../dashboard/screens/smart_home_dashboard_screen.dart';

/// Device Control Tab - Main device control interface
class DeviceControlTab extends StatefulWidget {
  final SmartDevice device;

  const DeviceControlTab({
    super.key,
    required this.device,
  });

  @override
  State<DeviceControlTab> createState() => _DeviceControlTabState();
}

class _DeviceControlTabState extends State<DeviceControlTab>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  SmartDevice get device => widget.device;
  
  // Device-specific controls
  double _lightBrightness = 100.0;
  double _thermostatTemperature = 22.0;
  bool _securityArmed = false;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializeDeviceState();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeDeviceState() {
    // Initialize device-specific state based on device type
    if (device.temperature != null) {
      _thermostatTemperature = device.temperature!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDeviceStatus(),
          const SizedBox(height: 24),
          Expanded(
            child: _buildDeviceSpecificControls(),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildDeviceStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: device.isOnline ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: device.isOnline 
                          ? (device.isOn ? _getDeviceColor() : Colors.grey[300])
                          : Colors.red[100],
                      shape: BoxShape.circle,
                      boxShadow: device.isOnline && device.isOn
                          ? [
                              BoxShadow(
                                color: _getDeviceColor().withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _getDeviceIcon(),
                      size: 30,
                      color: device.isOnline
                          ? (device.isOn ? Colors.white : Colors.grey[600])
                          : Colors.red[600],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: AppTheme.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${device.room} • ${device.isOnline ? "Online" : "Offline"}',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: device.isOn ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          device.isOn ? 'ON' : 'OFF',
                          style: AppTheme.labelSmall.copyWith(
                            color: device.isOn ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (device.batteryLevel != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.battery_std,
                          size: 16,
                          color: _getBatteryColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${device.batteryLevel}%',
                          style: AppTheme.labelSmall.copyWith(
                            color: _getBatteryColor(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSpecificControls() {
    switch (device.type) {
      case DeviceType.light:
        return _buildLightControls();
      case DeviceType.thermostat:
        return _buildThermostatControls();
      case DeviceType.camera:
        return _buildCameraControls();
      case DeviceType.lock:
        return _buildLockControls();
      case DeviceType.sensor:
        return _buildSensorControls();
      case DeviceType.speaker:
        return _buildSpeakerControls();
      case DeviceType.switch_:
        return _buildSwitchControls();
    }
  }

  Widget _buildLightControls() {
    return Column(
      children: [
        _buildControlCard(
          title: 'Brightness',
          icon: Icons.brightness_6,
          child: Column(
            children: [
              Text(
                '${_lightBrightness.toInt()}%',
                style: AppTheme.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getDeviceColor(),
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _lightBrightness,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: _getDeviceColor(),
                onChanged: device.isOnline && device.isOn
                    ? (value) {
                        setState(() {
                          _lightBrightness = value;
                        });
                        HapticFeedback.selectionClick();
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildColorPicker(),
      ],
    );
  }

  Widget _buildThermostatControls() {
    return Column(
      children: [
        _buildControlCard(
          title: 'Temperature',
          icon: Icons.thermostat,
          child: Column(
            children: [
              Text(
                '${_thermostatTemperature.toStringAsFixed(1)}°C',
                style: AppTheme.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getDeviceColor(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTemperatureButton(
                    icon: Icons.remove,
                    onPressed: () => _adjustTemperature(-0.5),
                  ),
                  Text(
                    'Target Temperature',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  _buildTemperatureButton(
                    icon: Icons.add,
                    onPressed: () => _adjustTemperature(0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildThermostatModes(),
      ],
    );
  }

  Widget _buildCameraControls() {
    return _buildControlCard(
      title: 'Camera Controls',
      icon: Icons.videocam,
      child: Column(
        children: [
          _buildActionButton(
            label: 'View Live Feed',
            icon: Icons.play_circle_filled,
            onPressed: () => _showLiveFeed(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Take Snapshot',
            icon: Icons.camera_alt,
            onPressed: () => _takeSnapshot(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'View Recordings',
            icon: Icons.video_library,
            onPressed: () => _viewRecordings(),
          ),
        ],
      ),
    );
  }

  Widget _buildLockControls() {
    return _buildControlCard(
      title: 'Lock Controls',
      icon: Icons.lock,
      child: Column(
        children: [
          Icon(
            _securityArmed ? Icons.lock : Icons.lock_open,
            size: 80,
            color: _securityArmed ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            _securityArmed ? 'LOCKED' : 'UNLOCKED',
            style: AppTheme.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: _securityArmed ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: device.isOnline ? () => _toggleLock() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _securityArmed ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(_securityArmed ? 'UNLOCK' : 'LOCK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorControls() {
    return _buildControlCard(
      title: 'Sensor Readings',
      icon: Icons.sensors,
      child: Column(
        children: [
          if (device.temperature != null)
            _buildSensorReading('Temperature', '${device.temperature!.toStringAsFixed(1)}°C', Icons.thermostat),
          _buildSensorReading('Motion', 'No Motion Detected', Icons.directions_walk),
          _buildSensorReading('Light Level', '450 lux', Icons.light_mode),
          _buildSensorReading('Humidity', '45%', Icons.water_drop),
        ],
      ),
    );
  }

  Widget _buildSpeakerControls() {
    return _buildControlCard(
      title: 'Speaker Controls',
      icon: Icons.speaker,
      child: Column(
        children: [
          _buildActionButton(
            label: 'Play Music',
            icon: Icons.play_arrow,
            onPressed: () => _playMusic(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Adjust Volume',
            icon: Icons.volume_up,
            onPressed: () => _adjustVolume(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'Voice Assistant',
            icon: Icons.mic,
            onPressed: () => _activateVoiceAssistant(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchControls() {
    return _buildControlCard(
      title: 'Switch Control',
      icon: Icons.toggle_on,
      child: Center(
        child: Transform.scale(
          scale: 2.0,
          child: Switch(
            value: device.isOn,
            onChanged: device.isOnline 
                ? (value) => _toggleSwitch()
                : null,
            activeColor: _getDeviceColor(),
          ),
        ),
      ),
    );
  }

  Widget _buildControlCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: _getDeviceColor()),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 8),
                Text(
                  'Color',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: device.isOnline && device.isOn
                      ? () {
                          HapticFeedback.lightImpact();
                          // TODO: Implement color change
                        }
                      : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _getDeviceColor().withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: device.isOnline ? onPressed : null,
        icon: Icon(icon, color: _getDeviceColor()),
        iconSize: 30,
      ),
    );
  }

  Widget _buildThermostatModes() {
    final modes = ['Auto', 'Heat', 'Cool', 'Off'];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.mode),
                const SizedBox(width: 8),
                Text(
                  'Mode',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: modes.map((mode) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: device.isOnline ? () => _setThermostatMode(mode) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mode == 'Auto' ? _getDeviceColor() : Colors.grey[200],
                        foregroundColor: mode == 'Auto' ? Colors.white : Colors.grey[700],
                      ),
                      child: Text(mode),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: device.isOnline ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorReading(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _getDeviceColor()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: _getDeviceColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: device.isOnline ? () => _scheduleDevice() : null,
            icon: const Icon(Icons.schedule),
            label: const Text('Schedule'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: device.isOnline ? () => _createAutomation() : null,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Automate'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  IconData _getDeviceIcon() {
    switch (device.type) {
      case DeviceType.light:
        return Icons.lightbulb;
      case DeviceType.thermostat:
        return Icons.thermostat;
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.lock:
        return Icons.lock;
      case DeviceType.sensor:
        return Icons.sensors;
      case DeviceType.speaker:
        return Icons.speaker;
      case DeviceType.switch_:
        return Icons.toggle_on;
    }
  }

  Color _getDeviceColor() {
    switch (device.type) {
      case DeviceType.light:
        return Colors.amber;
      case DeviceType.thermostat:
        return Colors.orange;
      case DeviceType.camera:
        return Colors.blue;
      case DeviceType.lock:
        return Colors.red;
      case DeviceType.sensor:
        return Colors.green;
      case DeviceType.speaker:
        return Colors.purple;
      case DeviceType.switch_:
        return Colors.teal;
    }
  }

  Color _getBatteryColor() {
    final batteryLevel = device.batteryLevel!;
    if (batteryLevel > 60) return Colors.green;
    if (batteryLevel > 30) return Colors.orange;
    return Colors.red;
  }

  // Device control methods
  void _adjustTemperature(double delta) {
    setState(() {
      _thermostatTemperature = (_thermostatTemperature + delta).clamp(10.0, 30.0);
    });
    HapticFeedback.selectionClick();
    // TODO: Send temperature command to device
  }

  void _toggleLock() {
    setState(() {
      _securityArmed = !_securityArmed;
    });
    HapticFeedback.mediumImpact();
    // TODO: Send lock command to device
  }

  void _toggleSwitch() {
    HapticFeedback.lightImpact();
    // TODO: Send switch toggle command
  }

  void _setThermostatMode(String mode) {
    HapticFeedback.selectionClick();
    // TODO: Set thermostat mode
  }

  void _showLiveFeed() {
    // TODO: Show camera live feed
  }

  void _takeSnapshot() {
    // TODO: Take camera snapshot
  }

  void _viewRecordings() {
    // TODO: View camera recordings
  }

  void _playMusic() {
    // TODO: Play music on speaker
  }

  void _adjustVolume() {
    // TODO: Adjust speaker volume
  }

  void _activateVoiceAssistant() {
    // TODO: Activate voice assistant
  }

  void _scheduleDevice() {
    // TODO: Schedule device
  }

  void _createAutomation() {
    // TODO: Create automation
  }
}