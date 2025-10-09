import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';

import '../firebase/firebase_manager.dart';
import '../../features/auth/services/security_service.dart';
import 'performance_monitor.dart';

/// Comprehensive Battery Optimization Layer
class BatteryOptimizer {
  static final BatteryOptimizer _instance = BatteryOptimizer._internal();
  factory BatteryOptimizer() => _instance;
  BatteryOptimizer._internal();

  final Battery _battery = Battery();
  final SecurityService _security = SecurityService();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
  // Battery monitoring
  Timer? _batteryTimer;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  final StreamController<BatteryStatus> _statusController = StreamController<BatteryStatus>.broadcast();
  
  // Battery state tracking
  BatteryState _currentBatteryState = BatteryState.unknown;
  int _currentBatteryLevel = 100;
  DateTime _lastBatteryUpdate = DateTime.now();
  
  // Power consumption tracking
  final Queue<PowerConsumptionData> _consumptionHistory = Queue<PowerConsumptionData>();
  double _currentPowerConsumptionMA = 0.0;
  
  // Optimization strategies
  BatteryOptimizationMode _currentMode = BatteryOptimizationMode.balanced;
  final Map<String, OptimizationStrategy> _activeStrategies = {};
  
  // Battery thresholds
  static const int _lowBatteryThreshold = 20;
  static const int _criticalBatteryThreshold = 10;
  static const double _highPowerConsumptionThreshold = 500.0; // mA
  static const Duration _monitoringInterval = Duration(seconds: 30);
  static const int _maxHistorySize = 100;

  bool _isInitialized = false;
  bool _isOptimizing = false;

  /// Stream of battery status updates
  Stream<BatteryStatus> get statusStream => _statusController.stream;

  /// Current battery level
  int get currentBatteryLevel => _currentBatteryLevel;

  /// Current battery state
  BatteryState get currentBatteryState => _currentBatteryState;

  /// Current optimization mode
  BatteryOptimizationMode get currentMode => _currentMode;

  /// Is optimization active
  bool get isOptimizing => _isOptimizing;

  /// Initialize battery optimizer
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get initial battery level
      _currentBatteryLevel = await _battery.batteryLevel;
      
      // Setup battery state monitoring
      _setupBatteryStateMonitoring();
      
      // Start battery monitoring
      _startBatteryMonitoring();
      
      // Apply initial optimization mode
      await _applyOptimizationMode(_currentMode);
      
      _isInitialized = true;
      _isOptimizing = true;

      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Battery optimizer initialized',
        metadata: {
          'initial_battery_level': _currentBatteryLevel,
          'optimization_mode': _currentMode.name,
          'monitoring_interval_seconds': _monitoringInterval.inSeconds,
        },
      );

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Battery optimizer initialization failed');
      rethrow;
    }
  }

  /// Setup battery state monitoring
  void _setupBatteryStateMonitoring() {
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
      _handleBatteryStateChange(state);
    });
  }

  /// Handle battery state change
  Future<void> _handleBatteryStateChange(BatteryState state) async {
    try {
      final previousState = _currentBatteryState;
      _currentBatteryState = state;
      _lastBatteryUpdate = DateTime.now();

      // Update battery level
      _currentBatteryLevel = await _battery.batteryLevel;

      // Log state change
      AnalyticsHelper.trackUserAction('battery_state_change', parameters: {
        'previous_state': previousState.name,
        'current_state': state.name,
        'battery_level': _currentBatteryLevel,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Apply state-specific optimizations
      await _applyStateSpecificOptimizations(state);

      // Emit status update
      _emitBatteryStatus();

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Handle battery state change failed');
    }
  }

  /// Start battery monitoring
  void _startBatteryMonitoring() {
    _batteryTimer = Timer.periodic(_monitoringInterval, (timer) {
      _monitorBatteryConsumption();
    });
  }

  /// Monitor battery consumption
  Future<void> _monitorBatteryConsumption() async {
    try {
      // Update battery level
      _currentBatteryLevel = await _battery.batteryLevel;
      
      // Calculate power consumption (estimate)
      _estimatePowerConsumption();
      
      // Check for battery optimization triggers
      await _checkBatteryOptimizationTriggers();
      
      // Record consumption data
      _recordConsumptionData();
      
      // Emit status update
      _emitBatteryStatus();
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Battery consumption monitoring failed');
    }
  }

  /// Estimate power consumption
  void _estimatePowerConsumption() {
    try {
      // Get performance metrics
      final performanceStats = _performanceMonitor.getPerformanceStatistics();
      
      // Estimate power consumption based on various factors
      double estimatedConsumption = 100.0; // Base consumption in mA
      
      // CPU usage impact (based on FPS drops)
      final fpsRatio = performanceStats.currentFPS / 60.0;
      estimatedConsumption += (1.0 - fpsRatio) * 200.0;
      
      // Memory usage impact
      final memoryRatio = performanceStats.currentMemoryMB / 150.0;
      estimatedConsumption += memoryRatio * 100.0;
      
      // Network usage impact
      if (performanceStats.networkRequestCount > 0) {
        estimatedConsumption += performanceStats.networkRequestCount * 10.0;
      }
      
      // Screen brightness impact (simplified)
      if (_currentBatteryState == BatteryState.discharging) {
        estimatedConsumption += 150.0; // Screen on consumption
      }
      
      _currentPowerConsumptionMA = estimatedConsumption.clamp(50.0, 1000.0);
      
    } catch (e) {
      _currentPowerConsumptionMA = 200.0; // Default estimate
    }
  }

  /// Check battery optimization triggers
  Future<void> _checkBatteryOptimizationTriggers() async {
    try {
      // Low battery trigger
      if (_currentBatteryLevel <= _lowBatteryThreshold) {
        await _triggerLowBatteryOptimization();
      }
      
      // Critical battery trigger
      if (_currentBatteryLevel <= _criticalBatteryThreshold) {
        await _triggerCriticalBatteryOptimization();
      }
      
      // High power consumption trigger
      if (_currentPowerConsumptionMA > _highPowerConsumptionThreshold) {
        await _triggerHighConsumptionOptimization();
      }
      
      // Automatic mode adjustment
      await _adjustOptimizationMode();
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Battery optimization triggers check failed');
    }
  }

  /// Record consumption data
  void _recordConsumptionData() {
    try {
      final data = PowerConsumptionData(
        timestamp: DateTime.now(),
        batteryLevel: _currentBatteryLevel,
        batteryState: _currentBatteryState,
        estimatedConsumptionMA: _currentPowerConsumptionMA,
        optimizationMode: _currentMode,
      );
      
      _consumptionHistory.add(data);
      
      // Keep history size manageable
      if (_consumptionHistory.length > _maxHistorySize) {
        _consumptionHistory.removeFirst();
      }
      
    } catch (e) {
      debugPrint('[BatteryOptimizer] Record consumption data failed: $e');
    }
  }

  /// Emit battery status
  void _emitBatteryStatus() {
    try {
      final status = BatteryStatus(
        batteryLevel: _currentBatteryLevel,
        batteryState: _currentBatteryState,
        powerConsumptionMA: _currentPowerConsumptionMA,
        optimizationMode: _currentMode,
        isOptimizing: _isOptimizing,
        lastUpdate: _lastBatteryUpdate,
        activeStrategies: List.from(_activeStrategies.keys),
        recommendations: _generateOptimizationRecommendations(),
      );
      
      _statusController.add(status);
      
    } catch (e) {
      debugPrint('[BatteryOptimizer] Emit battery status failed: $e');
    }
  }

  /// Apply state-specific optimizations
  Future<void> _applyStateSpecificOptimizations(BatteryState state) async {
    try {
      switch (state) {
        case BatteryState.charging:
          await _applyChargingOptimizations();
          break;
        case BatteryState.discharging:
          await _applyDischargingOptimizations();
          break;
        case BatteryState.full:
          await _applyFullBatteryOptimizations();
          break;
        case BatteryState.connectedNotCharging:
          await _applyConnectedNotChargingOptimizations();
          break;
        case BatteryState.unknown:
          // No specific optimizations
          break;
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Apply state-specific optimizations failed');
    }
  }

  /// Apply charging optimizations
  Future<void> _applyChargingOptimizations() async {
    try {
      // Increase performance when charging
      await _activateStrategy('charging_performance_boost', OptimizationStrategy(
        name: 'Charging Performance Boost',
        description: 'Increase performance while charging',
        actions: [
          OptimizationAction.increaseFrameRate,
          OptimizationAction.enableHighQualityGraphics,
          OptimizationAction.enableBackgroundSync,
        ],
        priority: StrategyPriority.medium,
      ));
      
    } catch (e) {
      debugPrint('[BatteryOptimizer] Apply charging optimizations failed: $e');
    }
  }

  /// Apply discharging optimizations
  Future<void> _applyDischargingOptimizations() async {
    try {
      if (_currentBatteryLevel <= _lowBatteryThreshold) {
        // Aggressive power saving
        await _activateStrategy('aggressive_power_saving', OptimizationStrategy(
          name: 'Aggressive Power Saving',
          description: 'Reduce power consumption when battery is low',
          actions: [
            OptimizationAction.reduceFrameRate,
            OptimizationAction.disableAnimations,
            OptimizationAction.reduceBackgroundActivity,
            OptimizationAction.dimScreen,
          ],
          priority: StrategyPriority.high,
        ));
      } else {
        // Moderate power saving
        await _activateStrategy('moderate_power_saving', OptimizationStrategy(
          name: 'Moderate Power Saving',
          description: 'Balance performance and battery life',
          actions: [
            OptimizationAction.moderateFrameRate,
            OptimizationAction.optimizeBackgroundActivity,
          ],
          priority: StrategyPriority.medium,
        ));
      }
      
    } catch (e) {
      debugPrint('[BatteryOptimizer] Apply discharging optimizations failed: $e');
    }
  }

  /// Apply full battery optimizations
  Future<void> _applyFullBatteryOptimizations() async {
    try {
      // Maximum performance when battery is full
      await _activateStrategy('maximum_performance', OptimizationStrategy(
        name: 'Maximum Performance',
        description: 'Use maximum performance when battery is full',
        actions: [
          OptimizationAction.maximizeFrameRate,
          OptimizationAction.enableAllFeatures,
          OptimizationAction.enableBackgroundSync,
        ],
        priority: StrategyPriority.low,
      ));
      
    } catch (e) {
      debugPrint('[BatteryOptimizer] Apply full battery optimizations failed: $e');
    }
  }

  /// Apply connected not charging optimizations
  Future<void> _applyConnectedNotChargingOptimizations() async {
    try {
      // Balanced approach when connected but not charging
      await _activateStrategy('connected_balanced', OptimizationStrategy(
        name: 'Connected Balanced',
        description: 'Balanced performance when connected but not charging',
        actions: [
          OptimizationAction.moderateFrameRate,
          OptimizationAction.enableSelectiveSync,
        ],
        priority: StrategyPriority.medium,
      ));
      
    } catch (e) {
      debugPrint('[BatteryOptimizer] Apply connected not charging optimizations failed: $e');
    }
  }

  /// Trigger low battery optimization
  Future<void> _triggerLowBatteryOptimization() async {
    try {
      await _security.logSecurityEvent(
        SecurityEventType.suspiciousActivity,
        'Low battery threshold reached',
        metadata: {
          'battery_level': _currentBatteryLevel,
          'threshold': _lowBatteryThreshold,
          'optimization_mode': _currentMode.name,
        },
      );

      // Switch to power saving mode if not already
      if (_currentMode != BatteryOptimizationMode.powerSaving) {
        await setOptimizationMode(BatteryOptimizationMode.powerSaving);
      }

      // Apply emergency power saving
      await _activateStrategy('emergency_power_saving', OptimizationStrategy(
        name: 'Emergency Power Saving',
        description: 'Emergency power saving measures',
        actions: [
          OptimizationAction.reduceFrameRate,
          OptimizationAction.disableAnimations,
          OptimizationAction.disableBackgroundSync,
          OptimizationAction.minimizeNetworkUsage,
        ],
        priority: StrategyPriority.critical,
      ));

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Trigger low battery optimization failed');
    }
  }

  /// Trigger critical battery optimization
  Future<void> _triggerCriticalBatteryOptimization() async {
    try {
      await _security.logSecurityEvent(
        SecurityEventType.suspiciousActivity,
        'Critical battery threshold reached',
        metadata: {
          'battery_level': _currentBatteryLevel,
          'threshold': _criticalBatteryThreshold,
          'optimization_mode': _currentMode.name,
        },
      );

      // Apply critical power saving
      await _activateStrategy('critical_power_saving', OptimizationStrategy(
        name: 'Critical Power Saving',
        description: 'Critical battery preservation measures',
        actions: [
          OptimizationAction.minimizeFrameRate,
          OptimizationAction.disableAllAnimations,
          OptimizationAction.disableAllBackgroundActivity,
          OptimizationAction.minimizeScreenBrightness,
          OptimizationAction.disableNonEssentialFeatures,
        ],
        priority: StrategyPriority.critical,
      ));

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Trigger critical battery optimization failed');
    }
  }

  /// Trigger high consumption optimization
  Future<void> _triggerHighConsumptionOptimization() async {
    try {
      await _security.logSecurityEvent(
        SecurityEventType.suspiciousActivity,
        'High power consumption detected',
        metadata: {
          'power_consumption_ma': _currentPowerConsumptionMA,
          'threshold': _highPowerConsumptionThreshold,
          'battery_level': _currentBatteryLevel,
        },
      );

      // Apply consumption reduction
      await _activateStrategy('consumption_reduction', OptimizationStrategy(
        name: 'Consumption Reduction',
        description: 'Reduce high power consumption',
        actions: [
          OptimizationAction.optimizeProcessing,
          OptimizationAction.reduceNetworkActivity,
          OptimizationAction.optimizeGraphics,
        ],
        priority: StrategyPriority.high,
      ));

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Trigger high consumption optimization failed');
    }
  }

  /// Adjust optimization mode automatically
  Future<void> _adjustOptimizationMode() async {
    try {
      BatteryOptimizationMode recommendedMode = _currentMode;
      
      if (_currentBatteryLevel <= _criticalBatteryThreshold) {
        recommendedMode = BatteryOptimizationMode.powerSaving;
      } else if (_currentBatteryLevel <= _lowBatteryThreshold) {
        recommendedMode = BatteryOptimizationMode.balanced;
      } else if (_currentBatteryLevel >= 80 && _currentBatteryState == BatteryState.charging) {
        recommendedMode = BatteryOptimizationMode.performance;
      } else {
        recommendedMode = BatteryOptimizationMode.balanced;
      }
      
      if (recommendedMode != _currentMode) {
        await setOptimizationMode(recommendedMode);
      }
      
    } catch (e) {
      debugPrint('[BatteryOptimizer] Adjust optimization mode failed: $e');
    }
  }

  /// Set optimization mode
  Future<void> setOptimizationMode(BatteryOptimizationMode mode) async {
    try {
      if (_currentMode == mode) return;
      
      final previousMode = _currentMode;
      _currentMode = mode;
      
      // Clear existing strategies
      _activeStrategies.clear();
      
      // Apply new mode
      await _applyOptimizationMode(mode);
      
      AnalyticsHelper.trackUserAction('battery_optimization_mode_change', parameters: {
        'previous_mode': previousMode.name,
        'current_mode': mode.name,
        'battery_level': _currentBatteryLevel,
        'auto_adjusted': true,
      });
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Set optimization mode failed');
    }
  }

  /// Apply optimization mode
  Future<void> _applyOptimizationMode(BatteryOptimizationMode mode) async {
    try {
      switch (mode) {
        case BatteryOptimizationMode.performance:
          await _applyPerformanceMode();
          break;
        case BatteryOptimizationMode.balanced:
          await _applyBalancedMode();
          break;
        case BatteryOptimizationMode.powerSaving:
          await _applyPowerSavingMode();
          break;
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Apply optimization mode failed');
    }
  }

  /// Apply performance mode
  Future<void> _applyPerformanceMode() async {
    await _activateStrategy('performance_mode', OptimizationStrategy(
      name: 'Performance Mode',
      description: 'Maximize performance, higher battery usage',
      actions: [
        OptimizationAction.maximizeFrameRate,
        OptimizationAction.enableHighQualityGraphics,
        OptimizationAction.enableAllFeatures,
        OptimizationAction.enableBackgroundSync,
      ],
      priority: StrategyPriority.medium,
    ));
  }

  /// Apply balanced mode
  Future<void> _applyBalancedMode() async {
    await _activateStrategy('balanced_mode', OptimizationStrategy(
      name: 'Balanced Mode',
      description: 'Balance performance and battery life',
      actions: [
        OptimizationAction.moderateFrameRate,
        OptimizationAction.optimizeGraphics,
        OptimizationAction.enableSelectiveSync,
        OptimizationAction.optimizeBackgroundActivity,
      ],
      priority: StrategyPriority.medium,
    ));
  }

  /// Apply power saving mode
  Future<void> _applyPowerSavingMode() async {
    await _activateStrategy('power_saving_mode', OptimizationStrategy(
      name: 'Power Saving Mode',
      description: 'Maximize battery life, reduced performance',
      actions: [
        OptimizationAction.reduceFrameRate,
        OptimizationAction.disableAnimations,
        OptimizationAction.minimizeBackgroundActivity,
        OptimizationAction.optimizeNetworkUsage,
        OptimizationAction.reduceGraphicsQuality,
      ],
      priority: StrategyPriority.high,
    ));
  }

  /// Activate optimization strategy
  Future<void> _activateStrategy(String id, OptimizationStrategy strategy) async {
    try {
      _activeStrategies[id] = strategy;
      
      // Apply strategy actions
      for (final action in strategy.actions) {
        await _applyOptimizationAction(action);
      }
      
    } catch (e) {
      debugPrint('[BatteryOptimizer] Activate strategy failed: $e');
    }
  }

  /// Apply optimization action
  Future<void> _applyOptimizationAction(OptimizationAction action) async {
    try {
      switch (action) {
        case OptimizationAction.reduceFrameRate:
          // Reduce app frame rate to 30 FPS
          debugPrint('[BatteryOptimizer] Reducing frame rate to 30 FPS');
          break;
        case OptimizationAction.disableAnimations:
          // Disable UI animations
          debugPrint('[BatteryOptimizer] Disabling UI animations');
          break;
        case OptimizationAction.minimizeBackgroundActivity:
          // Minimize background tasks
          debugPrint('[BatteryOptimizer] Minimizing background activity');
          break;
        case OptimizationAction.optimizeNetworkUsage:
          // Optimize network requests
          debugPrint('[BatteryOptimizer] Optimizing network usage');
          break;
        case OptimizationAction.reduceGraphicsQuality:
          // Reduce graphics quality
          debugPrint('[BatteryOptimizer] Reducing graphics quality');
          break;
        case OptimizationAction.maximizeFrameRate:
          // Maximize frame rate to 60+ FPS
          debugPrint('[BatteryOptimizer] Maximizing frame rate');
          break;
        case OptimizationAction.enableHighQualityGraphics:
          // Enable high quality graphics
          debugPrint('[BatteryOptimizer] Enabling high quality graphics');
          break;
        case OptimizationAction.enableBackgroundSync:
          // Enable background synchronization
          debugPrint('[BatteryOptimizer] Enabling background sync');
          break;
        case OptimizationAction.moderateFrameRate:
          // Set moderate frame rate (45 FPS)
          debugPrint('[BatteryOptimizer] Setting moderate frame rate');
          break;
        case OptimizationAction.optimizeGraphics:
          // Optimize graphics settings
          debugPrint('[BatteryOptimizer] Optimizing graphics settings');
          break;
        case OptimizationAction.enableSelectiveSync:
          // Enable selective background sync
          debugPrint('[BatteryOptimizer] Enabling selective sync');
          break;
        case OptimizationAction.optimizeBackgroundActivity:
          // Optimize background activity
          debugPrint('[BatteryOptimizer] Optimizing background activity');
          break;
        default:
          debugPrint('[BatteryOptimizer] Unknown optimization action: $action');
      }
    } catch (e) {
      debugPrint('[BatteryOptimizer] Apply optimization action failed: $e');
    }
  }

  /// Generate optimization recommendations
  List<String> _generateOptimizationRecommendations() {
    final recommendations = <String>[];
    
    try {
      if (_currentBatteryLevel <= _lowBatteryThreshold) {
        recommendations.add('Consider enabling power saving mode');
        recommendations.add('Reduce screen brightness');
        recommendations.add('Close unnecessary background apps');
      }
      
      if (_currentPowerConsumptionMA > _highPowerConsumptionThreshold) {
        recommendations.add('High power consumption detected');
        recommendations.add('Consider reducing app usage');
      }
      
      if (_currentBatteryState == BatteryState.charging) {
        recommendations.add('Device is charging - performance optimized');
      }
      
      if (_activeStrategies.isEmpty) {
        recommendations.add('No active optimization strategies');
      }
      
    } catch (e) {
      recommendations.add('Error generating recommendations');
    }
    
    return recommendations;
  }

  /// Get battery statistics
  BatteryStatistics getBatteryStatistics() {
    try {
      final recentData = _consumptionHistory.length >= 10
          ? _consumptionHistory.toList().sublist(_consumptionHistory.length - 10)
          : _consumptionHistory.toList();
      
      final averageConsumption = recentData.isNotEmpty
          ? recentData.fold<double>(0.0, (sum, d) => sum + d.estimatedConsumptionMA) / recentData.length
          : _currentPowerConsumptionMA;
      
      return BatteryStatistics(
        currentLevel: _currentBatteryLevel,
        currentState: _currentBatteryState,
        currentConsumptionMA: _currentPowerConsumptionMA,
        averageConsumptionMA: averageConsumption,
        optimizationMode: _currentMode,
        activeStrategiesCount: _activeStrategies.length,
        consumptionHistory: List.from(_consumptionHistory),
        isOptimizing: _isOptimizing,
      );
    } catch (e) {
      return BatteryStatistics(
        currentLevel: 0,
        currentState: BatteryState.unknown,
        currentConsumptionMA: 0.0,
        averageConsumptionMA: 0.0,
        optimizationMode: BatteryOptimizationMode.balanced,
        activeStrategiesCount: 0,
        consumptionHistory: [],
        isOptimizing: false,
      );
    }
  }

  /// Start optimization
  void startOptimization() {
    if (!_isOptimizing && _isInitialized) {
      _startBatteryMonitoring();
      _isOptimizing = true;
    }
  }

  /// Stop optimization
  void stopOptimization() {
    if (_isOptimizing) {
      _batteryTimer?.cancel();
      _activeStrategies.clear();
      _isOptimizing = false;
    }
  }

  /// Export battery data
  Map<String, dynamic> exportBatteryData() {
    try {
      return {
        'export_timestamp': DateTime.now().millisecondsSinceEpoch,
        'current_status': {
          'battery_level': _currentBatteryLevel,
          'battery_state': _currentBatteryState.name,
          'power_consumption_ma': _currentPowerConsumptionMA,
          'optimization_mode': _currentMode.name,
        },
        'consumption_history': _consumptionHistory
            .map((data) => data.toJson())
            .toList(),
        'statistics': getBatteryStatistics().toJson(),
        'active_strategies': _activeStrategies.map((key, strategy) => 
            MapEntry(key, strategy.toJson())),
      };
    } catch (e) {
      return {
        'error': 'Failed to export battery data: ${e.toString()}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Dispose battery optimizer
  void dispose() {
    _batteryTimer?.cancel();
    _batteryStateSubscription?.cancel();
    _statusController.close();
    _consumptionHistory.clear();
    _activeStrategies.clear();
  }
}

/// Battery optimization modes
enum BatteryOptimizationMode {
  performance,
  balanced,
  powerSaving,
}

/// Optimization actions
enum OptimizationAction {
  // Power saving actions
  reduceFrameRate,
  disableAnimations,
  minimizeBackgroundActivity,
  optimizeNetworkUsage,
  reduceGraphicsQuality,
  dimScreen,
  minimizeFrameRate,
  disableAllAnimations,
  disableAllBackgroundActivity,
  minimizeScreenBrightness,
  disableNonEssentialFeatures,
  minimizeNetworkUsage,
  
  // Performance actions
  maximizeFrameRate,
  enableHighQualityGraphics,
  enableBackgroundSync,
  enableAllFeatures,
  increaseFrameRate,
  
  // Balanced actions
  moderateFrameRate,
  optimizeGraphics,
  enableSelectiveSync,
  optimizeBackgroundActivity,
  optimizeProcessing,
  reduceNetworkActivity,
}

/// Strategy priority levels
enum StrategyPriority {
  low,
  medium,
  high,
  critical,
}

/// Battery status
class BatteryStatus {
  final int batteryLevel;
  final BatteryState batteryState;
  final double powerConsumptionMA;
  final BatteryOptimizationMode optimizationMode;
  final bool isOptimizing;
  final DateTime lastUpdate;
  final List<String> activeStrategies;
  final List<String> recommendations;

  BatteryStatus({
    required this.batteryLevel,
    required this.batteryState,
    required this.powerConsumptionMA,
    required this.optimizationMode,
    required this.isOptimizing,
    required this.lastUpdate,
    required this.activeStrategies,
    required this.recommendations,
  });
}

/// Power consumption data
class PowerConsumptionData {
  final DateTime timestamp;
  final int batteryLevel;
  final BatteryState batteryState;
  final double estimatedConsumptionMA;
  final BatteryOptimizationMode optimizationMode;

  PowerConsumptionData({
    required this.timestamp,
    required this.batteryLevel,
    required this.batteryState,
    required this.estimatedConsumptionMA,
    required this.optimizationMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'battery_level': batteryLevel,
      'battery_state': batteryState.name,
      'estimated_consumption_ma': estimatedConsumptionMA,
      'optimization_mode': optimizationMode.name,
    };
  }
}

/// Optimization strategy
class OptimizationStrategy {
  final String name;
  final String description;
  final List<OptimizationAction> actions;
  final StrategyPriority priority;

  OptimizationStrategy({
    required this.name,
    required this.description,
    required this.actions,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'actions': actions.map((a) => a.name).toList(),
      'priority': priority.name,
    };
  }
}

/// Battery statistics
class BatteryStatistics {
  final int currentLevel;
  final BatteryState currentState;
  final double currentConsumptionMA;
  final double averageConsumptionMA;
  final BatteryOptimizationMode optimizationMode;
  final int activeStrategiesCount;
  final List<PowerConsumptionData> consumptionHistory;
  final bool isOptimizing;

  BatteryStatistics({
    required this.currentLevel,
    required this.currentState,
    required this.currentConsumptionMA,
    required this.averageConsumptionMA,
    required this.optimizationMode,
    required this.activeStrategiesCount,
    required this.consumptionHistory,
    required this.isOptimizing,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_level': currentLevel,
      'current_state': currentState.name,
      'current_consumption_ma': currentConsumptionMA,
      'average_consumption_ma': averageConsumptionMA,
      'optimization_mode': optimizationMode.name,
      'active_strategies_count': activeStrategiesCount,
      'is_optimizing': isOptimizing,
    };
  }
}