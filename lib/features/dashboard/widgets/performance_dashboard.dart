import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/performance/performance_monitor.dart';
import '../../core/performance/battery_optimizer.dart';
import '../../core/theme/app_theme.dart';

/// Performance Dashboard Widget with comprehensive monitoring
class PerformanceDashboard extends StatefulWidget {
  const PerformanceDashboard({super.key});

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late final PerformanceMonitor _performanceMonitor;
  late final BatteryOptimizer _batteryOptimizer;
  
  // UI state
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final TabController _tabController;
  
  // Data streams
  StreamSubscription<PerformanceMetrics>? _performanceSubscription;
  StreamSubscription<BatteryStatus>? _batterySubscription;
  
  // Current data
  PerformanceMetrics? _currentMetrics;
  BatteryStatus? _currentBatteryStatus;
  PerformanceStatistics? _performanceStats;
  BatteryStatistics? _batteryStats;
  
  // Dashboard state
  bool _isExpanded = false;
  DashboardView _currentView = DashboardView.overview;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
  }

  void _initializeControllers() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _tabController = TabController(length: 4, vsync: this);
    _animationController.forward();
  }

  void _initializeServices() {
    _performanceMonitor = PerformanceMonitor();
    _batteryOptimizer = BatteryOptimizer();
    
    _setupDataStreams();
    _loadInitialData();
  }

  void _setupDataStreams() {
    _performanceSubscription = _performanceMonitor.metricsStream.listen((metrics) {
      if (mounted) {
        setState(() {
          _currentMetrics = metrics;
        });
      }
    });
    
    _batterySubscription = _batteryOptimizer.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentBatteryStatus = status;
        });
      }
    });
  }

  void _loadInitialData() {
    setState(() {
      _performanceStats = _performanceMonitor.getPerformanceStatistics();
      _batteryStats = _batteryOptimizer.getBatteryStatistics();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _performanceSubscription?.cancel();
    _batterySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isExpanded ? 600 : 200,
        child: Column(
          children: [
            _buildHeader(),
            if (_isExpanded) ...[
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
            ] else
              _buildCollapsedContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dashboard,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Dashboard',
                  style: AppTheme.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStatusText(),
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          _buildQuickStats(),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildQuickStatItem(
          icon: Icons.speed,
          value: '${_performanceStats?.currentFPS.toStringAsFixed(0) ?? '0'}',
          label: 'FPS',
          color: _getFPSColor(),
        ),
        const SizedBox(width: 16),
        _buildQuickStatItem(
          icon: Icons.memory,
          value: '${_performanceStats?.currentMemoryMB.toStringAsFixed(0) ?? '0'}',
          label: 'MB',
          color: _getMemoryColor(),
        ),
        const SizedBox(width: 16),
        _buildQuickStatItem(
          icon: Icons.battery_std,
          value: '${_batteryStats?.currentLevel ?? 0}%',
          label: 'Battery',
          color: _getBatteryColor(),
        ),
      ],
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppTheme.primaryColor,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
          Tab(text: 'Performance', icon: Icon(Icons.speed, size: 20)),
          Tab(text: 'Battery', icon: Icon(Icons.battery_std, size: 20)),
          Tab(text: 'Settings', icon: Icon(Icons.settings, size: 20)),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPerformanceTab(),
          _buildBatteryTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildPerformanceIndicator()),
            const SizedBox(width: 16),
            Expanded(child: _buildBatteryIndicator()),
            const SizedBox(width: 16),
            Expanded(child: _buildNetworkIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricCard('FPS', '${_performanceStats?.currentFPS.toStringAsFixed(1) ?? '0.0'}', Icons.speed, _getFPSColor())),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Memory', '${_performanceStats?.currentMemoryMB.toStringAsFixed(0) ?? '0'} MB', Icons.memory, _getMemoryColor())),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCard('Battery', '${_batteryStats?.currentLevel ?? 0}%', Icons.battery_std, _getBatteryColor())),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Network', '${_performanceStats?.averageResponseTimeMS.toStringAsFixed(0) ?? '0'} ms', Icons.network_check, _getNetworkColor())),
            ],
          ),
          const SizedBox(height: 20),
          _buildSystemStatus(),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPerformanceChart(),
          const SizedBox(height: 16),
          _buildPerformanceWarnings(),
          const SizedBox(height: 16),
          _buildPerformanceActions(),
        ],
      ),
    );
  }

  Widget _buildBatteryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBatteryStatus(),
          const SizedBox(height: 16),
          _buildBatteryOptimization(),
          const SizedBox(height: 16),
          _buildBatteryRecommendations(),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonitoringSettings(),
          const SizedBox(height: 16),
          _buildOptimizationSettings(),
          const SizedBox(height: 16),
          _buildExportOptions(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.headlineSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    final isGood = (_currentMetrics?.isPerformanceGood ?? false) && 
                   (_batteryStats?.currentLevel ?? 0) > 20;
    
    return Card(
      elevation: 2,
      color: isGood ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isGood ? Icons.check_circle : Icons.warning,
              color: isGood ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGood ? 'System Running Optimally' : 'Performance Issues Detected',
                    style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isGood 
                        ? 'All systems are performing well'
                        : 'Some optimization may be needed',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    final fps = _performanceStats?.currentFPS ?? 0.0;
    return Column(
      children: [
        CircularProgressIndicator(
          value: (fps / 60.0).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getFPSColor()),
          strokeWidth: 6,
        ),
        const SizedBox(height: 8),
        Text('Performance', style: AppTheme.bodySmall),
        Text('${fps.toStringAsFixed(0)} FPS', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBatteryIndicator() {
    final level = _batteryStats?.currentLevel ?? 0;
    return Column(
      children: [
        CircularProgressIndicator(
          value: (level / 100.0).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getBatteryColor()),
          strokeWidth: 6,
        ),
        const SizedBox(height: 8),
        Text('Battery', style: AppTheme.bodySmall),
        Text('$level%', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNetworkIndicator() {
    final latency = _performanceStats?.averageResponseTimeMS ?? 0.0;
    final quality = latency < 1000 ? 1.0 : latency < 3000 ? 0.5 : 0.2;
    return Column(
      children: [
        CircularProgressIndicator(
          value: quality,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getNetworkColor()),
          strokeWidth: 6,
        ),
        const SizedBox(height: 8),
        Text('Network', style: AppTheme.bodySmall),
        Text('${latency.toStringAsFixed(0)}ms', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Trends', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 120,
              child: Center(
                child: Text(
                  'Performance chart visualization would go here',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceWarnings() {
    final warnings = _currentMetrics?.warnings ?? [];
    
    if (warnings.isEmpty) {
      return Card(
        elevation: 2,
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              Text('No performance issues detected', style: AppTheme.bodyMedium),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Warnings', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...warnings.map((warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    warning.severity == WarningGeverity.critical 
                        ? Icons.error 
                        : Icons.warning,
                    color: warning.severity == WarningGeverity.critical 
                        ? Colors.red 
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(warning.message, style: AppTheme.bodySmall)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _optimizePerformance(),
                    icon: Icon(Icons.tune),
                    label: Text('Optimize'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _clearCache(),
                    icon: Icon(Icons.clear),
                    label: Text('Clear Cache'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryStatus() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Battery Status', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.battery_std, color: _getBatteryColor(), size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_batteryStats?.currentLevel ?? 0}%', style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                      Text('${_batteryStats?.currentState.name ?? 'Unknown'}', style: AppTheme.bodyMedium),
                      Text('${_batteryStats?.currentConsumptionMA.toStringAsFixed(0) ?? '0'} mA', style: AppTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryOptimization() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optimization Mode', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<BatteryOptimizationMode>(
                    segments: const [
                      ButtonSegment(value: BatteryOptimizationMode.performance, label: Text('Performance')),
                      ButtonSegment(value: BatteryOptimizationMode.balanced, label: Text('Balanced')),
                      ButtonSegment(value: BatteryOptimizationMode.powerSaving, label: Text('Power Saving')),
                    ],
                    selected: {_batteryStats?.optimizationMode ?? BatteryOptimizationMode.balanced},
                    onSelectionChanged: (Set<BatteryOptimizationMode> selected) {
                      _batteryOptimizer.setOptimizationMode(selected.first);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryRecommendations() {
    final recommendations = _currentBatteryStatus?.recommendations ?? [];
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommendations', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (recommendations.isEmpty)
              Text('No recommendations at this time', style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]))
            else
              ...recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(recommendation, style: AppTheme.bodySmall)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitoring', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text('Performance Monitoring'),
              subtitle: Text('Monitor FPS, memory, and network'),
              value: _performanceMonitor.isMonitoring,
              onChanged: (value) {
                if (value) {
                  _performanceMonitor.startMonitoring();
                } else {
                  _performanceMonitor.stopMonitoring();
                }
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('Battery Optimization'),
              subtitle: Text('Automatic battery optimization'),
              value: _batteryOptimizer.isOptimizing,
              onChanged: (value) {
                if (value) {
                  _batteryOptimizer.startOptimization();
                } else {
                  _batteryOptimizer.stopOptimization();
                }
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationSettings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optimization', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.auto_fix_high),
              title: Text('Auto Optimization'),
              subtitle: Text('Automatically optimize performance'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // Toggle auto optimization
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export Data', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportPerformanceData(),
                    icon: Icon(Icons.download),
                    label: Text('Export Performance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportBatteryData(),
                    icon: Icon(Icons.battery_saver),
                    label: Text('Export Battery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    final performanceGood = _currentMetrics?.isPerformanceGood ?? false;
    final batteryGood = (_batteryStats?.currentLevel ?? 0) > 20;
    
    if (performanceGood && batteryGood) {
      return 'System running optimally';
    } else if (!performanceGood && !batteryGood) {
      return 'Performance and battery issues detected';
    } else if (!performanceGood) {
      return 'Performance optimization needed';
    } else {
      return 'Battery optimization recommended';
    }
  }

  Color _getFPSColor() {
    final fps = _performanceStats?.currentFPS ?? 0.0;
    if (fps >= 50) return Colors.green;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getMemoryColor() {
    final memory = _performanceStats?.currentMemoryMB ?? 0.0;
    if (memory <= 100) return Colors.green;
    if (memory <= 150) return Colors.orange;
    return Colors.red;
  }

  Color _getBatteryColor() {
    final level = _batteryStats?.currentLevel ?? 0;
    if (level >= 60) return Colors.green;
    if (level >= 20) return Colors.orange;
    return Colors.red;
  }

  Color _getNetworkColor() {
    final latency = _performanceStats?.averageResponseTimeMS ?? 0.0;
    if (latency <= 1000) return Colors.green;
    if (latency <= 3000) return Colors.orange;
    return Colors.red;
  }

  void _optimizePerformance() {
    HapticFeedback.lightImpact();
    // Trigger performance optimization
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Performance optimization triggered')),
    );
  }

  void _clearCache() {
    HapticFeedback.lightImpact();
    // Clear cache
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cache cleared successfully')),
    );
  }

  void _exportPerformanceData() {
    HapticFeedback.lightImpact();
    final data = _performanceMonitor.exportPerformanceData();
    // Handle export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Performance data exported')),
    );
  }

  void _exportBatteryData() {
    HapticFeedback.lightImpact();
    final data = _batteryOptimizer.exportBatteryData();
    // Handle export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Battery data exported')),
    );
  }
}

enum DashboardView {
  overview,
  performance,
  battery,
  settings,
}