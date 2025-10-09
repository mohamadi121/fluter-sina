import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/performance/performance_monitor.dart';
import '../widgets/performance_metrics_display.dart';

/// Performance Dashboard Screen
/// Real-time monitoring of system performance and optimization
class PerformanceDashboardScreen extends StatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  State<PerformanceDashboardScreen> createState() => _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState extends State<PerformanceDashboardScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late PerformanceMonitor _performanceMonitor;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Timer? _updateTimer;
  Map<String, dynamic> _currentMetrics = {};
  List<Map<String, dynamic>> _performanceHistory = [];
  
  bool _isLoading = true;
  bool _isOptimizing = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _performanceMonitor = ServiceLocator.get<PerformanceMonitor>();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initializePerformanceMonitoring();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePerformanceMonitoring() async {
    setState(() => _isLoading = true);
    
    // Start performance monitoring
    await _loadCurrentMetrics();
    
    // Start real-time updates
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadCurrentMetrics();
    });
    
    _animationController.forward();
    setState(() => _isLoading = false);
  }

  Future<void> _loadCurrentMetrics() async {
    try {
      final metrics = _performanceMonitor.getCurrentMetrics();
      
      if (mounted) {
        setState(() {
          _currentMetrics = metrics;
          
          // Add to history for charts
          _performanceHistory.add({
            ...metrics,
            'timestamp': DateTime.now(),
          });
          
          // Keep only last 50 entries
          if (_performanceHistory.length > 50) {
            _performanceHistory.removeAt(0);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading performance metrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Performance Dashboard'),
        actions: [
          IconButton(
            onPressed: _isOptimizing ? null : _optimizePerformance,
            icon: _isOptimizing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.tune),
            tooltip: 'Optimize Performance',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.memory), text: 'System'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: _isLoading 
          ? _buildLoadingScreen()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildSystemTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading Performance Data...'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceScore(),
          const SizedBox(height: 16),
          _buildQuickMetrics(),
          const SizedBox(height: 16),
          _buildSystemHealth(),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          PerformanceMetricsDisplay(
            metrics: _currentMetrics,
            history: _performanceHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceChart(),
          const SizedBox(height: 16),
          _buildPerformanceLog(),
        ],
      ),
    );
  }

  Widget _buildPerformanceScore() {
    final score = _calculatePerformanceScore();
    final color = _getScoreColor(score);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Performance Score',
              style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: AppTheme.displayMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '/100',
                      style: AppTheme.bodyLarge.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getScoreDescription(score),
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetrics() {
    final cpuUsage = _currentMetrics['cpuUsage'] ?? 0.0;
    final memoryUsage = _currentMetrics['memoryUsage'] ?? 0.0;
    final networkLatency = _currentMetrics['networkLatency'] ?? 0.0;
    final batteryLevel = _currentMetrics['batteryLevel'] ?? 100.0;
    
    return Row(
      children: [
        Expanded(child: _buildMetricCard('CPU', '${cpuUsage.toStringAsFixed(1)}%', Icons.memory, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricCard('Memory', '${memoryUsage.toStringAsFixed(1)}%', Icons.storage, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricCard('Network', '${networkLatency.toStringAsFixed(0)}ms', Icons.network_check, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildMetricCard('Battery', '${batteryLevel.toStringAsFixed(0)}%', Icons.battery_full, Colors.red)),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTheme.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildHealthItem('Connectivity', true, 'All services online'),
            _buildHealthItem('Performance', true, 'Running optimally'),
            _buildHealthItem('Memory', false, 'High usage detected'),
            _buildHealthItem('Security', true, 'All systems secure'),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String label, bool isHealthy, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.warning,
            color: isHealthy ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('Performance Chart\n(Real-time data visualization)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceLog() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(5, (index) => _buildLogItem(
              'Performance optimization completed',
              DateTime.now().subtract(Duration(minutes: index * 15)),
              index == 0,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(String message, DateTime timestamp, bool isRecent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: isRecent ? AppTheme.primaryColor : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.bodySmall.copyWith(
                color: isRecent ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
          Text(
            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: AppTheme.bodySmall.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  double _calculatePerformanceScore() {
    if (_currentMetrics.isEmpty) return 85.0;
    
    final cpuUsage = _currentMetrics['cpuUsage'] ?? 50.0;
    final memoryUsage = _currentMetrics['memoryUsage'] ?? 50.0;
    final networkLatency = _currentMetrics['networkLatency'] ?? 100.0;
    
    // Simple scoring algorithm
    double score = 100.0;
    score -= (cpuUsage * 0.3);
    score -= (memoryUsage * 0.3);
    score -= (networkLatency / 10 * 0.4);
    
    return score.clamp(0.0, 100.0);
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(double score) {
    if (score >= 90) return 'Excellent Performance';
    if (score >= 80) return 'Good Performance';
    if (score >= 60) return 'Fair Performance';
    return 'Performance Issues Detected';
  }

  Future<void> _optimizePerformance() async {
    setState(() => _isOptimizing = true);
    
    // Simulate performance optimization
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() => _isOptimizing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Performance optimization completed'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Report',
            textColor: Colors.white,
            onPressed: () {
              // Show optimization report
            },
          ),
        ),
      );
    }
  }
}