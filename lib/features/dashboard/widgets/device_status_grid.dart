import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../screens/smart_home_dashboard_screen.dart';

/// Device Status Grid Widget
class DeviceStatusGrid extends StatelessWidget {
  final List<SmartDevice> devices;
  final Function(SmartDevice) onDeviceTap;
  final Function(String, bool) onDeviceToggle;

  const DeviceStatusGrid({
    super.key,
    required this.devices,
    required this.onDeviceTap,
    required this.onDeviceToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Smart Devices',
                  style: AppTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${devices.where((d) => d.isOnline).length}/${devices.length} online',
                  style: AppTheme.labelMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (devices.isEmpty)
              _buildEmptyState()
            else
              _buildDeviceGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.devices,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No devices found',
              style: AppTheme.titleMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your smart devices to get started',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        return DeviceCard(
          device: devices[index],
          onTap: () => onDeviceTap(devices[index]),
          onToggle: (isOn) => onDeviceToggle(devices[index].id, isOn),
        );
      },
    );
  }
}

/// Individual Device Card
class DeviceCard extends StatefulWidget {
  final SmartDevice device;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    required this.onToggle,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            child: Container(
              decoration: BoxDecoration(
                color: widget.device.isOnline
                    ? (widget.device.isOn 
                        ? _getDeviceColor().withOpacity(0.1)
                        : Colors.grey[50])
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.device.isOnline
                      ? (widget.device.isOn 
                          ? _getDeviceColor().withOpacity(0.3)
                          : Colors.grey[300]!)
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const Spacer(),
                    _buildDeviceInfo(),
                    const SizedBox(height: 8),
                    _buildToggleButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          _getDeviceIcon(),
          color: widget.device.isOnline
              ? (widget.device.isOn ? _getDeviceColor() : Colors.grey[500])
              : Colors.grey[400],
          size: 24,
        ),
        _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: widget.device.isOnline ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.device.name,
          style: AppTheme.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.device.isOnline ? null : Colors.grey[500],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          widget.device.room,
          style: AppTheme.labelSmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
        if (widget.device.temperature != null) ...[
          const SizedBox(height: 4),
          Text(
            '${widget.device.temperature!.toStringAsFixed(1)}°C',
            style: AppTheme.labelSmall.copyWith(
              color: _getDeviceColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (widget.device.batteryLevel != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.battery_std,
                size: 12,
                color: _getBatteryColor(),
              ),
              const SizedBox(width: 2),
              Text(
                '${widget.device.batteryLevel}%',
                style: AppTheme.labelSmall.copyWith(
                  color: _getBatteryColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildToggleButton() {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: ElevatedButton(
        onPressed: widget.device.isOnline 
            ? () {
                HapticFeedback.selectionClick();
                widget.onToggle(!widget.device.isOn);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.device.isOn 
              ? _getDeviceColor()
              : Colors.grey[300],
          foregroundColor: widget.device.isOn 
              ? Colors.white
              : Colors.grey[600],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          widget.device.isOnline
              ? (widget.device.isOn ? 'ON' : 'OFF')
              : 'OFFLINE',
          style: AppTheme.labelSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon() {
    switch (widget.device.type) {
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
    switch (widget.device.type) {
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
    final batteryLevel = widget.device.batteryLevel!;
    if (batteryLevel > 60) return Colors.green;
    if (batteryLevel > 30) return Colors.orange;
    return Colors.red;
  }
}