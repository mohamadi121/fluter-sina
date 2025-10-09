import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/websocket_service.dart';
import '../../../features/auth/services/security_service.dart';
import '../screens/smart_home_dashboard_screen.dart';
import '../tabs/device_control_tab.dart';

/// Device Management Screen for detailed device control
class DeviceManagementScreen extends StatefulWidget {
  final SmartDevice device;

  const DeviceManagementScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late WebSocketService _webSocketService;
  late SecurityService _securityService;

  SmartDevice? _currentDevice;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _webSocketService = ServiceLocator.get<WebSocketService>();
    _securityService = ServiceLocator.get<SecurityService>();
    _currentDevice = widget.device;
    
    _initializeDeviceConnection();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeDeviceConnection() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Authenticate device access
      final hasAccess = await _securityService.authenticateDeviceAccess(_currentDevice!.id);
      
      if (!hasAccess) {
        setState(() {
          _error = 'Access denied to this device';
          _isLoading = false;
        });
        return;
      }

      // Connect to device via WebSocket for real-time updates
      await _webSocketService.subscribeToDevice(_currentDevice!.id);
      
      // Listen for device updates
      _webSocketService.events.listen((event) {
        if (event.type == WebSocketEventType.deviceUpdate && 
            event.data['deviceId'] == _currentDevice!.id) {
          _updateDeviceState(event.data);
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateDeviceState(Map<String, dynamic> data) {
    setState(() {
      _currentDevice = SmartDevice(
        id: _currentDevice!.id,
        name: data['name'] ?? _currentDevice!.name,
        type: _currentDevice!.type,
        room: data['room'] ?? _currentDevice!.room,
        isOn: data['isOn'] ?? _currentDevice!.isOn,
        isOnline: data['isOnline'] ?? _currentDevice!.isOnline,
        temperature: data['temperature']?.toDouble(),
        batteryLevel: data['batteryLevel']?.toInt(),
      );
    });
  }

  Future<void> _toggleDevice() async {
    if (_currentDevice == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newState = !_currentDevice!.isOn;
      
      // Send command via WebSocket
      await _webSocketService.sendDeviceCommand(_currentDevice!.id, {
        'action': 'toggle',
        'state': newState,
      });

      // Update local state optimistically
      setState(() {
        _currentDevice = SmartDevice(
          id: _currentDevice!.id,
          name: _currentDevice!.name,
          type: _currentDevice!.type,
          room: _currentDevice!.room,
          isOn: newState,
          isOnline: _currentDevice!.isOnline,
          temperature: _currentDevice!.temperature,
          batteryLevel: _currentDevice!.batteryLevel,
        );
        _isLoading = false;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentDevice?.name ?? 'Device',
            style: AppTheme.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _currentDevice?.room ?? '',
            style: AppTheme.labelSmall.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _currentDevice?.isOnline == true ? _toggleDevice : null,
          icon: Icon(
            _currentDevice?.isOn == true ? Icons.power_off : Icons.power,
            color: _currentDevice?.isOnline == true 
                ? Colors.white 
                : Colors.white54,
          ),
        ),
        IconButton(
          onPressed: () => _showDeviceMenu(context),
          icon: const Icon(Icons.more_vert),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'Control', icon: Icon(Icons.tune)),
          Tab(text: 'Settings', icon: Icon(Icons.settings)),
          Tab(text: 'Automation', icon: Icon(Icons.auto_awesome)),
          Tab(text: 'History', icon: Icon(Icons.history)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        DeviceControlTab(device: _currentDevice!),
        DeviceSettingsTab(device: _currentDevice!),
        DeviceAutomationTab(device: _currentDevice!),
        DeviceHistoryTab(device: _currentDevice!),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting to device...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Device Connection Failed',
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _initializeDeviceConnection,
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviceMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DeviceMenuBottomSheet(device: _currentDevice!),
    );
  }
}

/// Device Menu Bottom Sheet
class DeviceMenuBottomSheet extends StatelessWidget {
  final SmartDevice device;

  const DeviceMenuBottomSheet({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename Device'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement rename functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Device'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement reset functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Device Information'),
            onTap: () {
              Navigator.pop(context);
              _showDeviceInfo(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Remove Device', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeviceRemoval(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDeviceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Device ID', device.id),
            _buildInfoRow('Type', device.type.toString().split('.').last),
            _buildInfoRow('Room', device.room),
            _buildInfoRow('Status', device.isOnline ? 'Online' : 'Offline'),
            _buildInfoRow('State', device.isOn ? 'On' : 'Off'),
            if (device.temperature != null)
              _buildInfoRow('Temperature', '${device.temperature!.toStringAsFixed(1)}°C'),
            if (device.batteryLevel != null)
              _buildInfoRow('Battery', '${device.batteryLevel}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmDeviceRemoval(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text('Are you sure you want to remove "${device.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
              // TODO: Implement device removal
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// Tab content widgets will be implemented in separate files
class DeviceSettingsTab extends StatelessWidget {
  final SmartDevice device;
  
  const DeviceSettingsTab({super.key, required this.device});
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Device Settings Tab - Coming Soon'));
  }
}

class DeviceAutomationTab extends StatelessWidget {
  final SmartDevice device;
  
  const DeviceAutomationTab({super.key, required this.device});
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Device Automation Tab - Coming Soon'));
  }
}

class DeviceHistoryTab extends StatelessWidget {
  final SmartDevice device;
  
  const DeviceHistoryTab({super.key, required this.device});
  
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Device History Tab - Coming Soon'));
  }
}

// WebSocket Service Extension
extension WebSocketDeviceExtension on WebSocketService {
  Future<void> subscribeToDevice(String deviceId) async {
    // TODO: Implement device subscription
  }

  Future<void> sendDeviceCommand(String deviceId, Map<String, dynamic> command) async {
    // TODO: Implement device command sending
  }
}

// Security Service Extension  
extension SecurityDeviceExtension on SecurityService {
  Future<bool> authenticateDeviceAccess(String deviceId) async {
    // TODO: Implement device access authentication
    return true; // Placeholder
  }
}