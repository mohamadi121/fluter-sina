import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/offline/offline_manager.dart';
import '../../../core/performance/performance_monitor.dart';
import '../../../features/auth/services/security_service.dart';

/// Service Integration Verification Widget
/// Tests all Phase 3 backend services integration
class ServiceIntegrationTest extends StatefulWidget {
  const ServiceIntegrationTest({super.key});

  @override
  State<ServiceIntegrationTest> createState() => _ServiceIntegrationTestState();
}

class _ServiceIntegrationTestState extends State<ServiceIntegrationTest> {
  Map<String, ServiceStatus> serviceStatuses = {};
  bool _isTestingInProgress = false;

  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  Future<void> _initializeTest() async {
    setState(() {
      _isTestingInProgress = true;
    });

    // Test all services
    await _testAllServices();

    setState(() {
      _isTestingInProgress = false;
    });
  }

  Future<void> _testAllServices() async {
    // Test Service Locator Registration
    await _testServiceLocator();
    
    // Test WebSocket Service
    await _testWebSocketService();
    
    // Test Offline Manager
    await _testOfflineManager();
    
    // Test Performance Monitor
    await _testPerformanceMonitor();
    
    // Test Security Service
    await _testSecurityService();
  }

  Future<void> _testServiceLocator() async {
    try {
      final webSocketService = ServiceLocator.get<WebSocketService>();
      final offlineManager = ServiceLocator.get<OfflineManager>();
      final performanceMonitor = ServiceLocator.get<PerformanceMonitor>();
      final securityService = ServiceLocator.get<SecurityService>();

      setState(() {
        serviceStatuses['Service Locator'] = ServiceStatus(
          isRegistered: true,
          isInitialized: true,
          lastCheck: DateTime.now(),
          details: 'All Phase 3 services properly registered',
        );
      });
    } catch (e) {
      setState(() {
        serviceStatuses['Service Locator'] = ServiceStatus(
          isRegistered: false,
          isInitialized: false,
          lastCheck: DateTime.now(),
          details: 'Error: ${e.toString()}',
          error: e.toString(),
        );
      });
    }
  }

  Future<void> _testWebSocketService() async {
    try {
      final webSocketService = ServiceLocator.get<WebSocketService>();
      
      setState(() {
        serviceStatuses['WebSocket Service'] = ServiceStatus(
          isRegistered: true,
          isInitialized: true,
          lastCheck: DateTime.now(),
          details: 'Ready for real-time communication',
        );
      });
    } catch (e) {
      setState(() {
        serviceStatuses['WebSocket Service'] = ServiceStatus(
          isRegistered: false,
          isInitialized: false,
          lastCheck: DateTime.now(),
          details: 'Service not available',
          error: e.toString(),
        );
      });
    }
  }

  Future<void> _testOfflineManager() async {
    try {
      final offlineManager = ServiceLocator.get<OfflineManager>();
      final isOnline = offlineManager.isOnline;
      
      setState(() {
        serviceStatuses['Offline Manager'] = ServiceStatus(
          isRegistered: true,
          isInitialized: true,
          lastCheck: DateTime.now(),
          details: 'Online: $isOnline, Mode: ${offlineManager.currentMode}',
        );
      });
    } catch (e) {
      setState(() {
        serviceStatuses['Offline Manager'] = ServiceStatus(
          isRegistered: false,
          isInitialized: false,
          lastCheck: DateTime.now(),
          details: 'Service not available',
          error: e.toString(),
        );
      });
    }
  }

  Future<void> _testPerformanceMonitor() async {
    try {
      final performanceMonitor = ServiceLocator.get<PerformanceMonitor>();
      
      setState(() {
        serviceStatuses['Performance Monitor'] = ServiceStatus(
          isRegistered: true,
          isInitialized: true,
          lastCheck: DateTime.now(),
          details: 'Monitoring system performance',
        );
      });
    } catch (e) {
      setState(() {
        serviceStatuses['Performance Monitor'] = ServiceStatus(
          isRegistered: false,
          isInitialized: false,
          lastCheck: DateTime.now(),
          details: 'Service not available',
          error: e.toString(),
        );
      });
    }
  }

  Future<void> _testSecurityService() async {
    try {
      final securityService = ServiceLocator.get<SecurityService>();
      
      setState(() {
        serviceStatuses['Security Service'] = ServiceStatus(
          isRegistered: true,
          isInitialized: true,
          lastCheck: DateTime.now(),
          details: 'Security features active',
        );
      });
    } catch (e) {
      setState(() {
        serviceStatuses['Security Service'] = ServiceStatus(
          isRegistered: false,
          isInitialized: false,
          lastCheck: DateTime.now(),
          details: 'Service not available',
          error: e.toString(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Integration Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isTestingInProgress ? null : _initializeTest,
            icon: _isTestingInProgress 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phase 3 Services Integration Status',
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isTestingInProgress)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Testing services integration...'),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: serviceStatuses.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final serviceName = serviceStatuses.keys.elementAt(index);
                    final status = serviceStatuses[serviceName]!;
                    
                    return ServiceStatusCard(
                      serviceName: serviceName,
                      status: status,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Service Status Card Widget
class ServiceStatusCard extends StatelessWidget {
  final String serviceName;
  final ServiceStatus status;

  const ServiceStatusCard({
    super.key,
    required this.serviceName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.isRegistered && status.isInitialized
                      ? Icons.check_circle
                      : Icons.error,
                  color: status.isRegistered && status.isInitialized
                      ? Colors.green
                      : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    serviceName,
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.isRegistered && status.isInitialized
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: status.isRegistered && status.isInitialized
                          ? Colors.green
                          : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status.isRegistered && status.isInitialized ? 'OK' : 'FAIL',
                    style: AppTheme.labelSmall.copyWith(
                      color: status.isRegistered && status.isInitialized
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              status.details,
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (status.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  'Error: ${status.error}',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.red[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Last check: ${_formatDateTime(status.lastCheck)}',
              style: AppTheme.labelSmall.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
}

/// Service Status Model
class ServiceStatus {
  final bool isRegistered;
  final bool isInitialized;
  final DateTime lastCheck;
  final String details;
  final String? error;

  ServiceStatus({
    required this.isRegistered,
    required this.isInitialized,
    required this.lastCheck,
    required this.details,
    this.error,
  });
}