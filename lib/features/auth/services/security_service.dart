import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import '../../../core/helper/secure_storage.dart';
import '../../../core/firebase/firebase_manager.dart';

/// Advanced Security Features Service
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // Security storage keys
  static const String _deviceFingerprintKey = 'device_fingerprint';
  static const String _sessionTokenKey = 'session_token';
  static const String _lastSecurityCheckKey = 'last_security_check';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _securityEventsKey = 'security_events';
  static const String _trustedDevicesKey = 'trusted_devices';
  
  // Security configurations
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 30);
  static const Duration _sessionTimeout = Duration(hours: 24);
  static const int _maxSecurityEvents = 100;

  /// Initialize security service
  Future<void> initialize() async {
    await _generateDeviceFingerprint();
    await _performSecurityCheck();
    _startSecurityMonitoring();
  }

  /// Generate unique device fingerprint
  Future<String> _generateDeviceFingerprint() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String fingerprint;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        fingerprint = _createFingerprint({
          'platform': 'android',
          'device': androidInfo.device,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'id': androidInfo.id,
          'androidId': androidInfo.androidId,
          'bootloader': androidInfo.bootloader,
          'app_version': packageInfo.version,
          'app_build': packageInfo.buildNumber,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        fingerprint = _createFingerprint({
          'platform': 'ios',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor,
          'app_version': packageInfo.version,
          'app_build': packageInfo.buildNumber,
        });
      } else {
        // Fallback for other platforms
        fingerprint = _createFingerprint({
          'platform': Platform.operatingSystem,
          'app_version': packageInfo.version,
          'app_build': packageInfo.buildNumber,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        });
      }

      await SecureStorage.writeSecureStorage(_deviceFingerprintKey, fingerprint);
      
      // Log device registration
      await logSecurityEvent(
        SecurityEventType.deviceRegistration,
        'Device fingerprint generated',
        metadata: {'fingerprint_hash': _hashFingerprint(fingerprint)},
      );
      
      return fingerprint;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Device fingerprint generation failed');
      
      // Fallback fingerprint
      final fallback = _createFingerprint({
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'random': DateTime.now().microsecondsSinceEpoch.toString(),
      });
      
      await SecureStorage.writeSecureStorage(_deviceFingerprintKey, fallback);
      return fallback;
    }
  }

  /// Create fingerprint hash from device data
  String _createFingerprint(Map<String, String> data) {
    final sortedKeys = data.keys.toList()..sort();
    final sortedData = sortedKeys.map((key) => '$key:${data[key]}').join('|');
    final bytes = utf8.encode(sortedData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hash fingerprint for logging (privacy)
  String _hashFingerprint(String fingerprint) {
    final bytes = utf8.encode(fingerprint);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // First 16 chars only
  }

  /// Get device fingerprint
  Future<String?> getDeviceFingerprint() async {
    try {
      String? fingerprint = await SecureStorage.readSecureStorage(_deviceFingerprintKey);
      
      if (fingerprint == null || fingerprint == 'ND') {
        fingerprint = await _generateDeviceFingerprint();
      }
      
      return fingerprint;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get device fingerprint failed');
      return null;
    }
  }

  /// Create secure session
  Future<String> createSession({
    required String userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final sessionData = {
        'user_id': userId,
        'device_fingerprint': await getDeviceFingerprint(),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'expires_at': DateTime.now().add(_sessionTimeout).millisecondsSinceEpoch,
        'app_version': (await PackageInfo.fromPlatform()).version,
        ...?metadata,
      };

      final sessionJson = jsonEncode(sessionData);
      final sessionBytes = utf8.encode(sessionJson);
      final sessionHash = sha256.convert(sessionBytes).toString();
      
      // Store session
      await SecureStorage.writeSecureStorage(_sessionTokenKey, sessionHash);
      
      // Log session creation
      await logSecurityEvent(
        SecurityEventType.sessionCreated,
        'New session created for user',
        metadata: {
          'user_id': userId,
          'session_hash': sessionHash.substring(0, 16),
          'device_fingerprint_hash': _hashFingerprint(sessionData['device_fingerprint'] ?? ''),
        },
      );
      
      return sessionHash;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Session creation failed');
      rethrow;
    }
  }

  /// Validate session
  Future<SessionValidationResult> validateSession() async {
    try {
      final sessionToken = await SecureStorage.readSecureStorage(_sessionTokenKey);
      
      if (sessionToken == null || sessionToken == 'ND') {
        return SessionValidationResult.invalid('No session found');
      }

      // Check if session has expired
      final lastCheckStr = await SecureStorage.readSecureStorage(_lastSecurityCheckKey);
      if (lastCheckStr != null && lastCheckStr != 'ND') {
        final lastCheck = DateTime.fromMillisecondsSinceEpoch(int.parse(lastCheckStr));
        final timeSinceCheck = DateTime.now().difference(lastCheck);
        
        if (timeSinceCheck > _sessionTimeout) {
          await _invalidateSession();
          return SessionValidationResult.expired('Session expired');
        }
      }

      // Update last check time
      await SecureStorage.writeSecureStorage(
        _lastSecurityCheckKey,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      return SessionValidationResult.valid(sessionToken);
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Session validation failed');
      return SessionValidationResult.invalid('Session validation error');
    }
  }

  /// Invalidate current session
  Future<void> _invalidateSession() async {
    try {
      await SecureStorage.deleteSecureStorage(_sessionTokenKey);
      await SecureStorage.deleteSecureStorage(_lastSecurityCheckKey);
      
      await logSecurityEvent(
        SecurityEventType.sessionInvalidated,
        'Session invalidated',
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Session invalidation failed');
    }
  }

  /// Rate limiting for authentication attempts
  Future<RateLimitResult> checkRateLimit({
    required String identifier,
    int? maxAttempts,
    Duration? timeWindow,
  }) async {
    try {
      final max = maxAttempts ?? _maxFailedAttempts;
      final window = timeWindow ?? _lockoutDuration;
      
      final attemptsKey = '${_failedAttemptsKey}_$identifier';
      final attemptsStr = await SecureStorage.readSecureStorage(attemptsKey);
      final attempts = jsonDecode(attemptsStr ?? '[]') as List<dynamic>;
      
      final now = DateTime.now();
      final cutoff = now.subtract(window);
      
      // Remove old attempts outside the time window
      final recentAttempts = attempts
          .cast<int>()
          .where((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp).isAfter(cutoff))
          .toList();
      
      if (recentAttempts.length >= max) {
        final oldestAttempt = DateTime.fromMillisecondsSinceEpoch(recentAttempts.first);
        final remainingTime = window - now.difference(oldestAttempt);
        
        return RateLimitResult.blocked(remainingTime);
      }
      
      return RateLimitResult.allowed(max - recentAttempts.length);
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Rate limit check failed');
      return RateLimitResult.allowed(1); // Fail open
    }
  }

  /// Record authentication attempt
  Future<void> recordAuthAttempt({
    required String identifier,
    required bool success,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!success) {
        // Record failed attempt
        final attemptsKey = '${_failedAttemptsKey}_$identifier';
        final attemptsStr = await SecureStorage.readSecureStorage(attemptsKey);
        final attempts = (jsonDecode(attemptsStr ?? '[]') as List<dynamic>).cast<int>();
        
        attempts.add(DateTime.now().millisecondsSinceEpoch);
        
        // Keep only recent attempts (last 24 hours)
        final cutoff = DateTime.now().subtract(const Duration(hours: 24));
        final recentAttempts = attempts
            .where((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp).isAfter(cutoff))
            .toList();
        
        await SecureStorage.writeSecureStorage(attemptsKey, jsonEncode(recentAttempts));
      } else {
        // Clear failed attempts on success
        final attemptsKey = '${_failedAttemptsKey}_$identifier';
        await SecureStorage.deleteSecureStorage(attemptsKey);
      }

      // Log security event
      await logSecurityEvent(
        success ? SecurityEventType.authSuccess : SecurityEventType.authFailure,
        success ? 'Authentication successful' : 'Authentication failed',
        metadata: {
          'identifier': identifier,
          'success': success,
          ...?metadata,
        },
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Record auth attempt failed');
    }
  }

  /// Log security event
  Future<void> logSecurityEvent(
    SecurityEventType type,
    String message, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final event = SecurityEvent(
        type: type,
        message: message,
        timestamp: DateTime.now(),
        deviceFingerprint: _hashFingerprint(await getDeviceFingerprint() ?? ''),
        metadata: metadata,
      );

      // Store locally
      await _storeSecurityEventLocally(event);

      // Send to analytics
      AnalyticsHelper.trackUserAction('security_event', parameters: {
        'event_type': type.name,
        'message': message,
        'device_fingerprint_hash': event.deviceFingerprint,
        'timestamp': event.timestamp.millisecondsSinceEpoch,
        ...?metadata,
      });

      // Send to Firebase if critical
      if (_isCriticalEvent(type)) {
        FirebaseManager().logError(
          'Critical security event: $message',
          StackTrace.current,
          reason: 'Security event: ${type.name}',
        );
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Log security event failed');
    }
  }

  /// Store security event locally
  Future<void> _storeSecurityEventLocally(SecurityEvent event) async {
    try {
      final eventsStr = await SecureStorage.readSecureStorage(_securityEventsKey);
      final events = (jsonDecode(eventsStr ?? '[]') as List<dynamic>)
          .map((e) => SecurityEvent.fromJson(e))
          .toList();

      events.add(event);

      // Keep only recent events
      if (events.length > _maxSecurityEvents) {
        events.removeRange(0, events.length - _maxSecurityEvents);
      }

      final eventsJson = jsonEncode(events.map((e) => e.toJson()).toList());
      await SecureStorage.writeSecureStorage(_securityEventsKey, eventsJson);
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Store security event failed');
    }
  }

  /// Check if event is critical
  bool _isCriticalEvent(SecurityEventType type) {
    return [
      SecurityEventType.authFailure,
      SecurityEventType.rateLimitExceeded,
      SecurityEventType.suspiciousActivity,
      SecurityEventType.deviceMismatch,
    ].contains(type);
  }

  /// Get security events
  Future<List<SecurityEvent>> getSecurityEvents({int? limit}) async {
    try {
      final eventsStr = await SecureStorage.readSecureStorage(_securityEventsKey);
      final events = (jsonDecode(eventsStr ?? '[]') as List<dynamic>)
          .map((e) => SecurityEvent.fromJson(e))
          .toList();

      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (limit != null && events.length > limit) {
        return events.take(limit).toList();
      }

      return events;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get security events failed');
      return [];
    }
  }

  /// Perform security check
  Future<SecurityCheckResult> _performSecurityCheck() async {
    try {
      final results = <String, bool>{};

      // Check device fingerprint
      final fingerprint = await getDeviceFingerprint();
      results['device_fingerprint'] = fingerprint != null;

      // Check session validity
      final sessionResult = await validateSession();
      results['session_valid'] = sessionResult.isValid;

      // Check for suspicious activity
      final events = await getSecurityEvents(limit: 50);
      final suspiciousEvents = events.where((e) => _isCriticalEvent(e.type)).length;
      results['suspicious_activity'] = suspiciousEvents < 10; // Threshold

      // Overall security score
      final passedChecks = results.values.where((v) => v).length;
      final totalChecks = results.length;
      final securityScore = (passedChecks / totalChecks * 100).round();

      await logSecurityEvent(
        SecurityEventType.securityCheck,
        'Security check performed',
        metadata: {
          'security_score': securityScore,
          'checks_passed': passedChecks,
          'total_checks': totalChecks,
          'results': results,
        },
      );

      return SecurityCheckResult(
        securityScore: securityScore,
        checks: results,
        isSecure: securityScore >= 80,
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Security check failed');
      return SecurityCheckResult(
        securityScore: 0,
        checks: {},
        isSecure: false,
      );
    }
  }

  /// Start security monitoring
  void _startSecurityMonitoring() {
    // Periodic security checks
    Timer.periodic(const Duration(hours: 1), (timer) {
      _performSecurityCheck();
    });

    // Session cleanup
    Timer.periodic(const Duration(hours: 6), (timer) {
      _cleanupExpiredSessions();
    });
  }

  /// Cleanup expired sessions and data
  Future<void> _cleanupExpiredSessions() async {
    try {
      final sessionResult = await validateSession();
      if (!sessionResult.isValid) {
        await _invalidateSession();
      }

      // Cleanup old security events
      final events = await getSecurityEvents();
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      final recentEvents = events.where((e) => e.timestamp.isAfter(cutoff)).toList();

      if (recentEvents.length != events.length) {
        final eventsJson = jsonEncode(recentEvents.map((e) => e.toJson()).toList());
        await SecureStorage.writeSecureStorage(_securityEventsKey, eventsJson);
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Cleanup expired sessions failed');
    }
  }

  /// Add device to trusted list
  Future<void> addTrustedDevice({
    required String deviceName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final fingerprint = await getDeviceFingerprint();
      if (fingerprint == null) return;

      final trustedDevice = TrustedDevice(
        fingerprint: fingerprint,
        name: deviceName,
        addedAt: DateTime.now(),
        lastUsed: DateTime.now(),
        metadata: metadata,
      );

      final devicesStr = await SecureStorage.readSecureStorage(_trustedDevicesKey);
      final devices = (jsonDecode(devicesStr ?? '[]') as List<dynamic>)
          .map((e) => TrustedDevice.fromJson(e))
          .toList();

      // Remove existing device with same fingerprint
      devices.removeWhere((d) => d.fingerprint == fingerprint);
      devices.add(trustedDevice);

      final devicesJson = jsonEncode(devices.map((e) => e.toJson()).toList());
      await SecureStorage.writeSecureStorage(_trustedDevicesKey, devicesJson);

      await logSecurityEvent(
        SecurityEventType.trustedDeviceAdded,
        'Device added to trusted list',
        metadata: {
          'device_name': deviceName,
          'device_fingerprint_hash': _hashFingerprint(fingerprint),
        },
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Add trusted device failed');
    }
  }

  /// Check if current device is trusted
  Future<bool> isDeviceTrusted() async {
    try {
      final fingerprint = await getDeviceFingerprint();
      if (fingerprint == null) return false;

      final devicesStr = await SecureStorage.readSecureStorage(_trustedDevicesKey);
      final devices = (jsonDecode(devicesStr ?? '[]') as List<dynamic>)
          .map((e) => TrustedDevice.fromJson(e))
          .toList();

      final trustedDevice = devices.where((d) => d.fingerprint == fingerprint).firstOrNull;
      
      if (trustedDevice != null) {
        // Update last used timestamp
        trustedDevice.lastUsed = DateTime.now();
        final devicesJson = jsonEncode(devices.map((e) => e.toJson()).toList());
        await SecureStorage.writeSecureStorage(_trustedDevicesKey, devicesJson);
        
        return true;
      }

      return false;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Check trusted device failed');
      return false;
    }
  }

  /// Get trusted devices
  Future<List<TrustedDevice>> getTrustedDevices() async {
    try {
      final devicesStr = await SecureStorage.readSecureStorage(_trustedDevicesKey);
      final devices = (jsonDecode(devicesStr ?? '[]') as List<dynamic>)
          .map((e) => TrustedDevice.fromJson(e))
          .toList();

      devices.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return devices;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get trusted devices failed');
      return [];
    }
  }

  /// Remove trusted device
  Future<void> removeTrustedDevice(String fingerprint) async {
    try {
      final devicesStr = await SecureStorage.readSecureStorage(_trustedDevicesKey);
      final devices = (jsonDecode(devicesStr ?? '[]') as List<dynamic>)
          .map((e) => TrustedDevice.fromJson(e))
          .toList();

      devices.removeWhere((d) => d.fingerprint == fingerprint);

      final devicesJson = jsonEncode(devices.map((e) => e.toJson()).toList());
      await SecureStorage.writeSecureStorage(_trustedDevicesKey, devicesJson);

      await logSecurityEvent(
        SecurityEventType.trustedDeviceRemoved,
        'Device removed from trusted list',
        metadata: {
          'device_fingerprint_hash': _hashFingerprint(fingerprint),
        },
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Remove trusted device failed');
    }
  }

  /// Clear all security data
  Future<void> clearSecurityData() async {
    try {
      await SecureStorage.deleteSecureStorage(_deviceFingerprintKey);
      await SecureStorage.deleteSecureStorage(_sessionTokenKey);
      await SecureStorage.deleteSecureStorage(_lastSecurityCheckKey);
      await SecureStorage.deleteSecureStorage(_securityEventsKey);
      await SecureStorage.deleteSecureStorage(_trustedDevicesKey);
      
      // Clear all failed attempts
      final keys = await SecureStorage.getAllKeys();
      for (final key in keys) {
        if (key.startsWith(_failedAttemptsKey)) {
          await SecureStorage.deleteSecureStorage(key);
        }
      }

      await logSecurityEvent(
        SecurityEventType.securityDataCleared,
        'All security data cleared',
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Clear security data failed');
    }
  }
}

/// Security event types
enum SecurityEventType {
  authSuccess,
  authFailure,
  sessionCreated,
  sessionInvalidated,
  deviceRegistration,
  deviceMismatch,
  rateLimitExceeded,
  suspiciousActivity,
  securityCheck,
  trustedDeviceAdded,
  trustedDeviceRemoved,
  securityDataCleared,
}

/// Security event data class
class SecurityEvent {
  final SecurityEventType type;
  final String message;
  final DateTime timestamp;
  final String deviceFingerprint;
  final Map<String, dynamic>? metadata;

  SecurityEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.deviceFingerprint,
    this.metadata,
  });

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      type: SecurityEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SecurityEventType.suspiciousActivity,
      ),
      message: json['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      deviceFingerprint: json['device_fingerprint'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'device_fingerprint': deviceFingerprint,
      'metadata': metadata,
    };
  }
}

/// Session validation result
class SessionValidationResult {
  final bool isValid;
  final String? sessionToken;
  final String? error;

  SessionValidationResult._({
    required this.isValid,
    this.sessionToken,
    this.error,
  });

  factory SessionValidationResult.valid(String sessionToken) {
    return SessionValidationResult._(
      isValid: true,
      sessionToken: sessionToken,
    );
  }

  factory SessionValidationResult.invalid(String error) {
    return SessionValidationResult._(
      isValid: false,
      error: error,
    );
  }

  factory SessionValidationResult.expired(String error) {
    return SessionValidationResult._(
      isValid: false,
      error: error,
    );
  }
}

/// Rate limit result
class RateLimitResult {
  final bool isAllowed;
  final int remainingAttempts;
  final Duration? blockedDuration;

  RateLimitResult._({
    required this.isAllowed,
    required this.remainingAttempts,
    this.blockedDuration,
  });

  factory RateLimitResult.allowed(int remainingAttempts) {
    return RateLimitResult._(
      isAllowed: true,
      remainingAttempts: remainingAttempts,
    );
  }

  factory RateLimitResult.blocked(Duration blockedDuration) {
    return RateLimitResult._(
      isAllowed: false,
      remainingAttempts: 0,
      blockedDuration: blockedDuration,
    );
  }
}

/// Security check result
class SecurityCheckResult {
  final int securityScore;
  final Map<String, bool> checks;
  final bool isSecure;

  SecurityCheckResult({
    required this.securityScore,
    required this.checks,
    required this.isSecure,
  });
}

/// Trusted device data class
class TrustedDevice {
  final String fingerprint;
  final String name;
  final DateTime addedAt;
  DateTime lastUsed;
  final Map<String, dynamic>? metadata;

  TrustedDevice({
    required this.fingerprint,
    required this.name,
    required this.addedAt,
    required this.lastUsed,
    this.metadata,
  });

  factory TrustedDevice.fromJson(Map<String, dynamic> json) {
    return TrustedDevice(
      fingerprint: json['fingerprint'],
      name: json['name'],
      addedAt: DateTime.fromMillisecondsSinceEpoch(json['added_at']),
      lastUsed: DateTime.fromMillisecondsSinceEpoch(json['last_used']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fingerprint': fingerprint,
      'name': name,
      'added_at': addedAt.millisecondsSinceEpoch,
      'last_used': lastUsed.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }
}