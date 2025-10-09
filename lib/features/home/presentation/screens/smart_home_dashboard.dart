import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../../core/theme/theme_constants.dart';
import '../../../core/widgets/responsive_builder.dart';
import '../../../core/widgets/enhanced_loading_indicator.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/firebase/firebase_manager.dart';

/// Smart Home Dashboard with Real-time Device Management
class SmartHomeDashboard extends StatefulWidget {
  const SmartHomeDashboard({Key? key}) : super(key: key);

  @override
  State<SmartHomeDashboard> createState() => _SmartHomeDashboardState();
}

class _SmartHomeDashboardState extends State<SmartHomeDashboard>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _refreshController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  // WebSocket and data management
  final WebSocketService _webSocket = WebSocketService();
  StreamSubscription? _webSocketSubscription;
  
  // Dashboard state
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  
  // Mock data - replace with real data models
  List<SmartDevice> _devices = [];
  List<EnergyReading> _energyData = [];
  Map<String, dynamic> _dashboardStats = {};
  
  // UI state
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeWebSocket();
    _loadDashboardData();
  }

  /// Initialize animation controllers
  void _initializeAnimations() {
    _refreshController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Start initial animations
    _fadeController.forward();
    _slideController.forward();
  }

  /// Initialize WebSocket connection
  void _initializeWebSocket() {
    _webSocketSubscription = _webSocket.events.listen(
      (event) => _handleWebSocketEvent(event),
    );
    
    // Connect to WebSocket for real-time updates
    _connectWebSocket();
  }

  /// Connect to WebSocket server
  Future<void> _connectWebSocket() async {
    try {
      await _webSocket.connect(
        url: 'wss://api.smarthome.example.com/ws',
        headers: {'X-Client-Type': 'mobile'},
      );
    } catch (e) {
      debugPrint('[Dashboard] WebSocket connection failed: $e');
    }
  }

  /// Handle WebSocket events
  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case WebSocketEventType.message:
        _handleRealtimeUpdate(event.data);
        break;
      case WebSocketEventType.connected:
        debugPrint('[Dashboard] WebSocket connected');
        break;
      case WebSocketEventType.disconnected:
        debugPrint('[Dashboard] WebSocket disconnected');
        break;
      case WebSocketEventType.error:
        debugPrint('[Dashboard] WebSocket error: ${event.data}');
        break;
      default:
        break;
    }
  }

  /// Handle real-time updates from WebSocket
  void _handleRealtimeUpdate(Map<String, dynamic>? data) {
    if (data == null) return;
    
    setState(() {
      final updateType = data['type'] as String?;
      
      switch (updateType) {
        case 'device_status':
          _updateDeviceStatus(data);
          break;
        case 'energy_reading':
          _updateEnergyReading(data);
          break;
        case 'dashboard_stats':
          _updateDashboardStats(data);
          break;
        default:
          break;
      }
    });
    
    // Trigger haptic feedback for important updates
    if (data['priority'] == 'high') {
      HapticFeedback.lightImpact();
    }
  }

  /// Update device status from real-time data
  void _updateDeviceStatus(Map<String, dynamic> data) {
    final deviceId = data['device_id'] as String?;
    if (deviceId == null) return;
    
    final deviceIndex = _devices.indexWhere((device) => device.id == deviceId);
    if (deviceIndex != -1) {
      _devices[deviceIndex] = _devices[deviceIndex].copyWith(
        isOnline: data['online'] ?? _devices[deviceIndex].isOnline,
        status: data['status'] ?? _devices[deviceIndex].status,
        batteryLevel: data['battery'] ?? _devices[deviceIndex].batteryLevel,
        lastUpdate: DateTime.now(),
      );
    }
  }

  /// Update energy reading from real-time data
  void _updateEnergyReading(Map<String, dynamic> data) {
    final reading = EnergyReading.fromJson(data);
    _energyData.add(reading);
    
    // Keep only last 24 hours of data
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _energyData.removeWhere((reading) => reading.timestamp.isBefore(cutoff));
  }

  /// Update dashboard statistics
  void _updateDashboardStats(Map<String, dynamic> data) {
    _dashboardStats = {
      ..._dashboardStats,
      ...data['stats'],
    };
  }

  /// Load initial dashboard data
  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Simulate API calls - replace with real API calls
      await Future.wait([
        _loadDevices(),
        _loadEnergyData(),
        _loadDashboardStats(),
      ]);

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data';
      });
      
      FirebaseManager().logError(e, StackTrace.current, reason: 'Load dashboard data failed');
    }
  }

  /// Load devices data
  Future<void> _loadDevices() async {
    // Mock data - replace with API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    _devices = [
      SmartDevice(
        id: '1',
        name: 'Living Room Lights',
        type: DeviceType.light,
        room: 'Living Room',
        isOnline: true,
        status: 'On',
        batteryLevel: null,
        energyUsage: 25.5,
        lastUpdate: DateTime.now(),
      ),
      SmartDevice(
        id: '2',
        name: 'Smart Thermostat',
        type: DeviceType.thermostat,
        room: 'Main',
        isOnline: true,
        status: '22°C',
        batteryLevel: 85,
        energyUsage: 120.0,
        lastUpdate: DateTime.now(),
      ),
      SmartDevice(
        id: '3',
        name: 'Security Camera',
        type: DeviceType.camera,
        room: 'Front Door',
        isOnline: true,
        status: 'Recording',
        batteryLevel: 67,
        energyUsage: 15.8,
        lastUpdate: DateTime.now(),
      ),
      SmartDevice(
        id: '4',
        name: 'Smart Lock',
        type: DeviceType.lock,
        room: 'Front Door',
        isOnline: false,
        status: 'Locked',
        batteryLevel: 23,
        energyUsage: 2.1,
        lastUpdate: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  /// Load energy data
  Future<void> _loadEnergyData() async {
    // Mock data - replace with API call
    await Future.delayed(const Duration(milliseconds: 300));
    
    final now = DateTime.now();
    _energyData = List.generate(24, (index) {
      return EnergyReading(
        timestamp: now.subtract(Duration(hours: 23 - index)),
        consumption: 150 + math.Random().nextDouble() * 100,
        cost: 0.12 * (150 + math.Random().nextDouble() * 100),
      );
    });
  }

  /// Load dashboard statistics
  Future<void> _loadDashboardStats() async {
    // Mock data - replace with API call
    await Future.delayed(const Duration(milliseconds: 200));
    
    _dashboardStats = {
      'total_devices': _devices.length,
      'online_devices': _devices.where((d) => d.isOnline).length,
      'total_energy_today': 2.45,
      'energy_cost_today': 0.32,
      'monthly_savings': 15.67,
      'carbon_footprint': 1.2,
    };
  }

  /// Refresh dashboard data
  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    _refreshController.repeat();
    HapticFeedback.mediumImpact();
    
    try {
      await _loadDashboardData();
    } finally {
      setState(() {
        _isRefreshing = false;
      });
      _refreshController.stop();
    }
  }

  /// Toggle device state
  Future<void> _toggleDevice(SmartDevice device) async {
    try {
      HapticFeedback.lightImpact();
      
      // Send command via WebSocket
      await _webSocket.sendJson({
        'type': 'device_command',
        'device_id': device.id,
        'command': device.status == 'On' ? 'turn_off' : 'turn_on',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Optimistic update
      final deviceIndex = _devices.indexWhere((d) => d.id == device.id);
      if (deviceIndex != -1) {
        setState(() {
          _devices[deviceIndex] = device.copyWith(
            status: device.status == 'On' ? 'Off' : 'On',
            lastUpdate: DateTime.now(),
          );
        });
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to control device: ${device.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenInfo) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: _buildBody(context, screenInfo),
          bottomNavigationBar: _buildBottomNavigation(context),
          floatingActionButton: _buildFloatingActionButton(context),
        );
      },
    );
  }

  /// Build main body
  Widget _buildBody(BuildContext context, ScreenInfo screenInfo) {
    if (_isLoading) {
      return const Center(
        child: EnhancedLoadingIndicator(
          message: 'Loading dashboard...',
        ),
      );
    }
    
    if (_errorMessage != null) {
      return _buildErrorState(context);
    }
    
    return FadeTransition(
      opacity: _fadeController,
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          children: [
            _buildOverviewTab(context, screenInfo),
            _buildDevicesTab(context, screenInfo),
            _buildEnergyTab(context, screenInfo),
            _buildSettingsTab(context, screenInfo),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build overview tab
  Widget _buildOverviewTab(BuildContext context, ScreenInfo screenInfo) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildAppBar(context, 'Smart Home Overview'),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStatsCards(context, screenInfo),
              const SizedBox(height: 24),
              _buildQuickActions(context, screenInfo),
              const SizedBox(height: 24),
              _buildRecentDevices(context, screenInfo),
              const SizedBox(height: 24),
              _buildEnergyChart(context, screenInfo),
            ]),
          ),
        ),
      ],
    );
  }

  /// Build devices tab
  Widget _buildDevicesTab(BuildContext context, ScreenInfo screenInfo) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, 'Devices'),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenInfo.isMobile ? 2 : 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final device = _devices[index];
                return _buildDeviceCard(context, device);
              },
              childCount: _devices.length,
            ),
          ),
        ),
      ],
    );
  }

  /// Build energy tab
  Widget _buildEnergyTab(BuildContext context, ScreenInfo screenInfo) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, 'Energy Management'),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildEnergyStats(context, screenInfo),
              const SizedBox(height: 24),
              _buildEnergyChart(context, screenInfo),
              const SizedBox(height: 24),
              _buildEnergyTips(context, screenInfo),
            ]),
          ),
        ),
      ],
    );
  }

  /// Build settings tab
  Widget _buildSettingsTab(BuildContext context, ScreenInfo screenInfo) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, 'Settings'),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSettingsCard(context, 'Home Configuration'),
              const SizedBox(height: 16),
              _buildSettingsCard(context, 'Notifications'),
              const SizedBox(height: 16),
              _buildSettingsCard(context, 'Energy Preferences'),
              const SizedBox(height: 16),
              _buildSettingsCard(context, 'Security & Privacy'),
            ]),
          ),
        ),
      ],
    );
  }

  /// Build app bar
  Widget _buildAppBar(BuildContext context, String title) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        if (_isRefreshing)
          Padding(
            padding: const EdgeInsets.all(16),
            child: RotationTransition(
              turns: _refreshController,
              child: const Icon(Icons.refresh),
            ),
          )
        else
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        IconButton(
          onPressed: () {
            // TODO: Show notifications
          },
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
        ),
      ],
    );
  }

  /// Build statistics cards
  Widget _buildStatsCards(BuildContext context, ScreenInfo screenInfo) {
    final stats = [
      ('Devices Online', '${_dashboardStats['online_devices']}/${_dashboardStats['total_devices']}', Icons.devices),
      ('Energy Today', '${_dashboardStats['total_energy_today']} kWh', Icons.bolt),
      ('Cost Today', '\$${_dashboardStats['energy_cost_today']?.toStringAsFixed(2)}', Icons.attach_money),
      ('Monthly Savings', '\$${_dashboardStats['monthly_savings']?.toStringAsFixed(2)}', Icons.savings),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenInfo.isMobile ? 2 : 4,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(context, stat.$1, stat.$2, stat.$3);
      },
    );
  }

  /// Build stat card
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const Spacer(),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick actions
  Widget _buildQuickActions(BuildContext context, ScreenInfo screenInfo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'All Lights Off',
                    Icons.lightbulb_outline,
                    () => _performQuickAction('lights_off'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Lock All',
                    Icons.lock_outline,
                    () => _performQuickAction('lock_all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    'Arm Security',
                    Icons.security,
                    () => _performQuickAction('arm_security'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick action button
  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  /// Perform quick action
  Future<void> _performQuickAction(String action) async {
    try {
      HapticFeedback.mediumImpact();
      
      await _webSocket.sendJson({
        'type': 'quick_action',
        'action': action,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action "$action" executed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to execute action'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Build recent devices
  Widget _buildRecentDevices(BuildContext context, ScreenInfo screenInfo) {
    final recentDevices = _devices.take(3).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Devices',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recentDevices.map((device) => _buildDeviceListTile(context, device)),
          ],
        ),
      ),
    );
  }

  /// Build device list tile
  Widget _buildDeviceListTile(BuildContext context, SmartDevice device) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: device.isOnline 
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          _getDeviceIcon(device.type),
          color: device.isOnline 
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      title: Text(device.name),
      subtitle: Text('${device.room} • ${device.status}'),
      trailing: device.type == DeviceType.light || device.type == DeviceType.thermostat
        ? Switch(
            value: device.status == 'On',
            onChanged: (value) => _toggleDevice(device),
          )
        : Text(
            device.batteryLevel != null ? '${device.batteryLevel}%' : '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      onTap: () => _showDeviceDetails(context, device),
    );
  }

  /// Build device card
  Widget _buildDeviceCard(BuildContext context, SmartDevice device) {
    return Card(
      elevation: device.isOnline ? 2 : 0,
      color: device.isOnline 
        ? null
        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: InkWell(
        onTap: () => _showDeviceDetails(context, device),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getDeviceIcon(device.type),
                    color: device.isOnline 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                  const Spacer(),
                  if (device.batteryLevel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBatteryColor(device.batteryLevel!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${device.batteryLevel}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                device.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                device.room,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: device.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    device.status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build energy chart placeholder
  Widget _buildEnergyChart(BuildContext context, ScreenInfo screenInfo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy Usage (24h)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Energy Chart Placeholder',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Chart implementation coming soon',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build energy stats
  Widget _buildEnergyStats(BuildContext context, ScreenInfo screenInfo) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Today\'s Usage',
            '${_dashboardStats['total_energy_today']} kWh',
            Icons.bolt,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'Cost Today',
            '\$${_dashboardStats['energy_cost_today']?.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
        ),
      ],
    );
  }

  /// Build energy tips
  Widget _buildEnergyTips(BuildContext context, ScreenInfo screenInfo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy Saving Tips',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTipTile(
              context,
              'Turn off lights when not in use',
              'Save up to 10% on your electricity bill',
              Icons.lightbulb_outline,
            ),
            _buildTipTile(
              context,
              'Optimize thermostat settings',
              'Adjust temperature by 2°C to save 15% energy',
              Icons.thermostat,
            ),
            _buildTipTile(
              context,
              'Use natural light during day',
              'Reduce artificial lighting needs',
              Icons.wb_sunny,
            ),
          ],
        ),
      ),
    );
  }

  /// Build tip tile
  Widget _buildTipTile(BuildContext context, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Build settings card
  Widget _buildSettingsCard(BuildContext context, String title) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.settings),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to settings page
        },
      ),
    );
  }

  /// Build bottom navigation
  Widget _buildBottomNavigation(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedTabIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedTabIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.devices_outlined),
          selectedIcon: Icon(Icons.devices),
          label: 'Devices',
        ),
        NavigationDestination(
          icon: Icon(Icons.bolt_outlined),
          selectedIcon: Icon(Icons.bolt),
          label: 'Energy',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        // TODO: Add new device
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Device'),
    );
  }

  /// Get device icon
  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
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
      case DeviceType.switch_:
        return Icons.toggle_on;
    }
  }

  /// Get battery color
  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel > 50) return Colors.green;
    if (batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  /// Show device details
  void _showDeviceDetails(BuildContext context, SmartDevice device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${device.room} • ${device.type.name}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Device details content would go here
                        Text(
                          'Device details and controls will be implemented here.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    _webSocketSubscription?.cancel();
    _webSocket.dispose();
    super.dispose();
  }
}

/// Device types
enum DeviceType {
  light,
  thermostat,
  camera,
  lock,
  sensor,
  switch_,
}

/// Smart device data model
class SmartDevice {
  final String id;
  final String name;
  final DeviceType type;
  final String room;
  final bool isOnline;
  final String status;
  final int? batteryLevel;
  final double? energyUsage;
  final DateTime lastUpdate;

  SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.room,
    required this.isOnline,
    required this.status,
    this.batteryLevel,
    this.energyUsage,
    required this.lastUpdate,
  });

  SmartDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? room,
    bool? isOnline,
    String? status,
    int? batteryLevel,
    double? energyUsage,
    DateTime? lastUpdate,
  }) {
    return SmartDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      room: room ?? this.room,
      isOnline: isOnline ?? this.isOnline,
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      energyUsage: energyUsage ?? this.energyUsage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// Energy reading data model
class EnergyReading {
  final DateTime timestamp;
  final double consumption;
  final double cost;

  EnergyReading({
    required this.timestamp,
    required this.consumption,
    required this.cost,
  });

  factory EnergyReading.fromJson(Map<String, dynamic> json) {
    return EnergyReading(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      consumption: json['consumption'].toDouble(),
      cost: json['cost'].toDouble(),
    );
  }
}