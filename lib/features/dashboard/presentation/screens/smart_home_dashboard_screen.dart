import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/performance/performance_monitor.dart';
import '../../../core/performance/battery_optimizer.dart';
import '../../../core/network/websocket_service.dart';
import '../widgets/device_status_grid.dart';
import '../widgets/environmental_controls_panel.dart';
import '../widgets/quick_actions_row.dart';
import '../widgets/system_status_card.dart';
import '../widgets/energy_usage_chart.dart';

/// Smart Home Dashboard Screen with Real-time Monitoring
class SmartHomeDashboardScreen extends StatefulWidget {
  const SmartHomeDashboardScreen({super.key});

  @override
  State<SmartHomeDashboardScreen> createState() => _SmartHomeDashboardScreenState();
}

class _SmartHomeDashboardScreenState extends State<SmartHomeDashboardScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  // Services
  late final PerformanceMonitor _performanceMonitor;
  late final BatteryOptimizer _batteryOptimizer;
  late final WebSocketService _webSocketService;

  // Animation controllers
  late final AnimationController _mainAnimationController;
  late final AnimationController _refreshAnimationController;

  // Animations
  late final Animation<double> _fadeInAnimation;
  late final Animation<Offset> _slideUpAnimation;
  late final Animation<double> _refreshSpinAnimation;

  // Streams
  StreamSubscription<PerformanceMetrics>? _performanceSubscription;
  StreamSubscription<BatteryStatus>? _batterySubscription;
  StreamSubscription<WebSocketEvent>? _webSocketSubscription;

  // Dashboard state
  bool _isLoading = true;
  bool _isRefreshing = false;
  DashboardData? _dashboardData;
  List<SmartDevice> _devices = [];
  EnvironmentalData? _environmentalData;
  SystemHealth? _systemHealth;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadDashboardData();
    _setupDataStreams();
  }

  void _initializeServices() {
    _performanceMonitor = PerformanceMonitor();
    _batteryOptimizer = BatteryOptimizer();
    _webSocketService = WebSocketService();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOut,
    ));

    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutBack,
    ));

    _refreshSpinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupDataStreams() {
    _performanceSubscription = _performanceMonitor.metricsStream.listen((metrics) {
      if (mounted) {
        setState(() {
          _updateSystemHealth(metrics);
        });
      }
    });

    _batterySubscription = _batteryOptimizer.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _updateBatteryStatus(status);
        });
      }
    });

    _webSocketSubscription = _webSocketService.events.listen((event) {
      if (mounted) {
        _handleWebSocketEvent(event);
      }
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Simulate loading dashboard data
      await Future.wait([
        _loadDevices(),
        _loadEnvironmentalData(),
        _loadSystemHealth(),
      ]);

      _mainAnimationController.forward();

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load dashboard data');
    }
  }

  Future<void> _loadDevices() async {
    // Simulate loading devices
    await Future.delayed(const Duration(milliseconds: 500));
    
    _devices = [
      SmartDevice(
        id: 'living_room_light',
        name: 'Living Room Light',
        type: DeviceType.light,
        isOnline: true,
        isOn: true,
        room: 'Living Room',
        batteryLevel: null,
        lastUpdate: DateTime.now(),
      ),
      SmartDevice(
        id: 'thermostat_main',
        name: 'Main Thermostat',
        type: DeviceType.thermostat,
        isOnline: true,
        isOn: true,
        room: 'Living Room',
        temperature: 22.5,
        lastUpdate: DateTime.now(),
      ),
      SmartDevice(
        id: 'security_camera_front',
        name: 'Front Door Camera',
        type: DeviceType.camera,
        isOnline: true,
        isOn: true,
        room: 'Entrance',
        batteryLevel: 85,
        lastUpdate: DateTime.now(),
      ),
      SmartDevice(
        id: 'smart_lock_main',
        name: 'Main Door Lock',
        type: DeviceType.lock,
        isOnline: true,
        isOn: false, // Locked
        room: 'Entrance',
        batteryLevel: 67,
        lastUpdate: DateTime.now(),
      ),
    ];
  }

  Future<void> _loadEnvironmentalData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _environmentalData = EnvironmentalData(
      temperature: 22.5,
      humidity: 45.0,
      airQuality: 85,
      lightLevel: 65,
      noiseLevel: 35,
      uvIndex: 3,
      lastUpdate: DateTime.now(),
    );
  }

  Future<void> _loadSystemHealth() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final performanceStats = _performanceMonitor.getPerformanceStatistics();
    final batteryStats = _batteryOptimizer.getBatteryStatistics();
    
    _systemHealth = SystemHealth(
      overallHealth: 92,
      networkStatus: NetworkStatus.excellent,
      systemLoad: 25,
      memoryUsage: performanceStats.currentMemoryMB,
      batteryLevel: batteryStats.currentLevel,
      connectedDevices: _devices.where((d) => d.isOnline).length,
      totalDevices: _devices.length,
      lastUpdate: DateTime.now(),
    );
  }

  void _updateSystemHealth(PerformanceMetrics metrics) {
    if (_systemHealth != null) {
      _systemHealth = _systemHealth!.copyWith(
        memoryUsage: metrics.memoryUsageMB,
        systemLoad: _calculateSystemLoad(metrics),
        lastUpdate: DateTime.now(),
      );
    }
  }

  void _updateBatteryStatus(BatteryStatus status) {
    if (_systemHealth != null) {
      _systemHealth = _systemHealth!.copyWith(
        batteryLevel: status.batteryLevel,
        lastUpdate: DateTime.now(),
      );
    }
  }

  int _calculateSystemLoad(PerformanceMetrics metrics) {
    // Calculate system load based on performance metrics
    double load = 0.0;
    
    // FPS impact (lower FPS = higher load)
    load += (60 - metrics.fps) / 60 * 40;
    
    // Memory usage impact
    load += (metrics.memoryUsageMB / 200) * 30;
    
    // Network latency impact
    load += (metrics.networkLatencyMS / 3000) * 30;
    
    return load.clamp(0, 100).round();
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case WebSocketEventType.deviceUpdate:
        _handleDeviceUpdate(event);
        break;
      case WebSocketEventType.environmentalUpdate:
        _handleEnvironmentalUpdate(event);
        break;
      case WebSocketEventType.systemAlert:
        _handleSystemAlert(event);
        break;
      default:
        break;
    }
  }

  void _handleDeviceUpdate(WebSocketEvent event) {
    final deviceId = event.data['deviceId'] as String?;
    if (deviceId != null) {
      final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
        setState(() {
          _devices[deviceIndex] = _devices[deviceIndex].copyWithUpdate(event.data);
        });
      }
    }
  }

  void _handleEnvironmentalUpdate(WebSocketEvent event) {
    if (_environmentalData != null) {
      setState(() {
        _environmentalData = _environmentalData!.copyWithUpdate(event.data);
      });
    }
  }

  void _handleSystemAlert(WebSocketEvent event) {
    final alertMessage = event.data['message'] as String?;
    if (alertMessage != null) {
      _showSystemAlert(alertMessage);
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _refreshAnimationController.repeat();
    HapticFeedback.lightImpact();

    try {
      await _loadDashboardData();
    } finally {
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();
      
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSystemAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Alert'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _refreshAnimationController.dispose();
    _performanceSubscription?.cancel();
    _batterySubscription?.cancel();
    _webSocketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                  _buildSystemStatus(),
                  const SizedBox(height: 16),
                  _buildEnvironmentalControls(),
                  const SizedBox(height: 16),
                  _buildDeviceGrid(),
                  const SizedBox(height: 16),
                  _buildEnergyChart(),
                  const SizedBox(height: 100), // Bottom padding for navigation
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Smart Home Dashboard...'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedBuilder(
          animation: _fadeInAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeInAnimation.value,
              child: const Text(
                'Smart Home',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AnimatedBuilder(
          animation: _refreshSpinAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _refreshSpinAnimation.value * 2 * 3.14159,
              child: IconButton(
                onPressed: _isRefreshing ? null : _refreshDashboard,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Dashboard',
              ),
            );
          },
        ),
        IconButton(
          onPressed: () {
            // Navigate to settings
          },
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
        IconButton(
          onPressed: () {
            context.push(AppRoutes.apiConfigurationTest);
          },
          icon: const Icon(Icons.api),
          tooltip: 'API Configuration Test',
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return AnimatedBuilder(
      animation: _slideUpAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideUpAnimation.value,
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: QuickActionsRow(
              onActionTap: _handleQuickAction,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemStatus() {
    return AnimatedBuilder(
      animation: _slideUpAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideUpAnimation.value,
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: SystemStatusCard(
              systemHealth: _systemHealth,
              onTap: () {
                // Navigate to system health details
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnvironmentalControls() {
    return AnimatedBuilder(
      animation: _slideUpAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideUpAnimation.value,
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: EnvironmentalControlsPanel(
              environmentalData: _environmentalData,
              onControlChange: _handleEnvironmentalControl,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceGrid() {
    return AnimatedBuilder(
      animation: _slideUpAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideUpAnimation.value,
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: DeviceStatusGrid(
              devices: _devices,
              onDeviceTap: _handleDeviceTap,
              onDeviceToggle: _handleDeviceToggle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnergyChart() {
    return AnimatedBuilder(
      animation: _slideUpAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideUpAnimation.value,
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: EnergyUsageChart(
              onTap: () {
                // Navigate to energy analytics
              },
            ),
          ),
        );
      },
    );
  }

  void _handleQuickAction(QuickActionType action) {
    HapticFeedback.lightImpact();
    
    switch (action) {
      case QuickActionType.allLights:
        _toggleAllLights();
        break;
      case QuickActionType.security:
        _toggleSecurity();
        break;
      case QuickActionType.climate:
        _openClimateControl();
        break;
      case QuickActionType.scenes:
        _openScenes();
        break;
    }
  }

  void _toggleAllLights() {
    // Toggle all light devices
    final lightDevices = _devices.where((d) => d.type == DeviceType.light);
    final anyOn = lightDevices.any((d) => d.isOn);
    
    for (final device in lightDevices) {
      _toggleDevice(device.id, !anyOn);
    }
  }

  void _toggleSecurity() {
    // Toggle security system
  }

  void _openClimateControl() {
    // Navigate to climate control
  }

  void _openScenes() {
    // Navigate to scenes
  }

  void _handleEnvironmentalControl(EnvironmentalControlType type, double value) {
    // Handle environmental control changes
  }

  void _handleDeviceTap(SmartDevice device) {
    // Navigate to device details
  }

  void _handleDeviceToggle(String deviceId, bool isOn) {
    _toggleDevice(deviceId, isOn);
  }

  void _toggleDevice(String deviceId, bool isOn) {
    final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex != -1) {
      setState(() {
        _devices[deviceIndex] = _devices[deviceIndex].copyWith(isOn: isOn);
      });

      // Send command via WebSocket
      _webSocketService.sendMessage({
        'type': 'device_command',
        'deviceId': deviceId,
        'command': isOn ? 'turn_on' : 'turn_off',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}

// Data Models (to be moved to separate files)
class DashboardData {
  final List<SmartDevice> devices;
  final EnvironmentalData environmentalData;
  final SystemHealth systemHealth;

  DashboardData({
    required this.devices,
    required this.environmentalData,
    required this.systemHealth,
  });
}

class SmartDevice {
  final String id;
  final String name;
  final DeviceType type;
  final bool isOnline;
  final bool isOn;
  final String room;
  final double? temperature;
  final int? batteryLevel;
  final DateTime lastUpdate;

  SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.isOnline,
    required this.isOn,
    required this.room,
    this.temperature,
    this.batteryLevel,
    required this.lastUpdate,
  });

  SmartDevice copyWith({
    bool? isOnline,
    bool? isOn,
    double? temperature,
    int? batteryLevel,
  }) {
    return SmartDevice(
      id: id,
      name: name,
      type: type,
      isOnline: isOnline ?? this.isOnline,
      isOn: isOn ?? this.isOn,
      room: room,
      temperature: temperature ?? this.temperature,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastUpdate: DateTime.now(),
    );
  }

  SmartDevice copyWithUpdate(Map<String, dynamic> data) {
    return copyWith(
      isOnline: data['isOnline'] as bool?,
      isOn: data['isOn'] as bool?,
      temperature: data['temperature'] as double?,
      batteryLevel: data['batteryLevel'] as int?,
    );
  }
}

enum DeviceType {
  light,
  thermostat,
  camera,
  lock,
  sensor,
  speaker,
  switch_,
}

class EnvironmentalData {
  final double temperature;
  final double humidity;
  final int airQuality;
  final int lightLevel;
  final int noiseLevel;
  final int uvIndex;
  final DateTime lastUpdate;

  EnvironmentalData({
    required this.temperature,
    required this.humidity,
    required this.airQuality,
    required this.lightLevel,
    required this.noiseLevel,
    required this.uvIndex,
    required this.lastUpdate,
  });

  EnvironmentalData copyWithUpdate(Map<String, dynamic> data) {
    return EnvironmentalData(
      temperature: data['temperature'] as double? ?? temperature,
      humidity: data['humidity'] as double? ?? humidity,
      airQuality: data['airQuality'] as int? ?? airQuality,
      lightLevel: data['lightLevel'] as int? ?? lightLevel,
      noiseLevel: data['noiseLevel'] as int? ?? noiseLevel,
      uvIndex: data['uvIndex'] as int? ?? uvIndex,
      lastUpdate: DateTime.now(),
    );
  }
}

class SystemHealth {
  final int overallHealth;
  final NetworkStatus networkStatus;
  final int systemLoad;
  final double memoryUsage;
  final int batteryLevel;
  final int connectedDevices;
  final int totalDevices;
  final DateTime lastUpdate;

  SystemHealth({
    required this.overallHealth,
    required this.networkStatus,
    required this.systemLoad,
    required this.memoryUsage,
    required this.batteryLevel,
    required this.connectedDevices,
    required this.totalDevices,
    required this.lastUpdate,
  });

  SystemHealth copyWith({
    int? overallHealth,
    NetworkStatus? networkStatus,
    int? systemLoad,
    double? memoryUsage,
    int? batteryLevel,
    int? connectedDevices,
    int? totalDevices,
  }) {
    return SystemHealth(
      overallHealth: overallHealth ?? this.overallHealth,
      networkStatus: networkStatus ?? this.networkStatus,
      systemLoad: systemLoad ?? this.systemLoad,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      totalDevices: totalDevices ?? this.totalDevices,
      lastUpdate: DateTime.now(),
    );
  }
}

enum NetworkStatus {
  excellent,
  good,
  fair,
  poor,
  offline,
}

enum QuickActionType {
  allLights,
  security,
  climate,
  scenes,
}

enum EnvironmentalControlType {
  temperature,
  humidity,
  lighting,
  ventilation,
}