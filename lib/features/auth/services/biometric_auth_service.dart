import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:async';

import '../../../core/helper/secure_storage.dart';
import '../../../core/firebase/firebase_manager.dart';

/// Advanced Biometric Authentication Service
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Storage keys for biometric data
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricHashKey = 'biometric_hash';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const String _authAttemptsKey = 'auth_attempts';
  
  // Security configurations
  static const int _maxAuthAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 30);
  static const Duration _sessionTimeout = Duration(hours: 24);

  /// Check if biometric authentication is available
  Future<BiometricAvailability> checkAvailability() async {
    try {
      // Check if device supports biometrics
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return BiometricAvailability.notSupported;
      }

      // Check if biometrics are enrolled
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return BiometricAvailability.notEnrolled;
      }

      // Check if app has been locked out
      if (await _isLockedOut()) {
        return BiometricAvailability.lockedOut;
      }

      return BiometricAvailability.available;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Biometric availability check failed');
      return BiometricAvailability.error;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get available biometrics failed');
      return [];
    }
  }

  /// Check if biometric authentication is enabled for the app
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await SecureStorage.readSecureStorage(_biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication
  Future<BiometricResult> enableBiometric({
    required String userId,
    String? reason,
  }) async {
    try {
      // Check availability first
      final availability = await checkAvailability();
      if (availability != BiometricAvailability.available) {
        return BiometricResult.failed(
          error: _getAvailabilityErrorMessage(availability),
          errorCode: BiometricErrorCode.notAvailable,
        );
      }

      // Authenticate to enable
      final authResult = await authenticate(
        reason: reason ?? 'فعال‌سازی احراز هویت بیومتریک',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authResult.success) {
        return authResult;
      }

      // Store biometric hash for future verification
      final biometricHash = _generateBiometricHash(userId);
      await SecureStorage.writeSecureStorage(_biometricHashKey, biometricHash);
      await SecureStorage.writeSecureStorage(_biometricEnabledKey, 'true');

      // Track enablement
      AnalyticsHelper.trackUserAction('biometric_enabled', parameters: {
        'user_id': userId,
        'biometric_types': (await getAvailableBiometrics()).map((e) => e.name).toList(),
      });

      return BiometricResult.success();
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Enable biometric failed');
      return BiometricResult.failed(
        error: 'خطا در فعال‌سازی احراز هویت بیومتریک',
        errorCode: BiometricErrorCode.unknown,
      );
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await SecureStorage.deleteSecureStorage(_biometricEnabledKey);
      await SecureStorage.deleteSecureStorage(_biometricHashKey);
      await SecureStorage.deleteSecureStorage(_lastAuthTimeKey);
      await SecureStorage.deleteSecureStorage(_authAttemptsKey);

      AnalyticsHelper.trackUserAction('biometric_disabled');
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Disable biometric failed');
    }
  }

  /// Authenticate using biometrics
  Future<BiometricResult> authenticate({
    required String reason,
    AuthenticationOptions? options,
  }) async {
    try {
      // Check if locked out
      if (await _isLockedOut()) {
        return BiometricResult.failed(
          error: 'دستگاه به دلیل تلاش‌های متعدد قفل شده است',
          errorCode: BiometricErrorCode.lockedOut,
        );
      }

      // Perform authentication
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: options ?? const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        await _onAuthenticationSuccess();
        return BiometricResult.success();
      } else {
        await _onAuthenticationFailure();
        return BiometricResult.failed(
          error: 'احراز هویت ناموفق',
          errorCode: BiometricErrorCode.userCancel,
        );
      }
    } on PlatformException catch (e) {
      await _onAuthenticationFailure();
      
      final errorCode = _mapPlatformException(e);
      final errorMessage = _getErrorMessage(errorCode);
      
      return BiometricResult.failed(
        error: errorMessage,
        errorCode: errorCode,
      );
    } catch (e) {
      await _onAuthenticationFailure();
      FirebaseManager().logError(e, StackTrace.current, reason: 'Biometric authentication failed');
      
      return BiometricResult.failed(
        error: 'خطای غیرمنتظره در احراز هویت',
        errorCode: BiometricErrorCode.unknown,
      );
    }
  }

  /// Quick authentication for already enabled users
  Future<BiometricResult> quickAuthenticate() async {
    if (!await isBiometricEnabled()) {
      return BiometricResult.failed(
        error: 'احراز هویت بیومتریک فعال نیست',
        errorCode: BiometricErrorCode.notEnabled,
      );
    }

    // Check if session is still valid
    if (await _isSessionValid()) {
      return BiometricResult.success(fromCache: true);
    }

    return authenticate(reason: 'تأیید هویت برای ورود');
  }

  /// Verify biometric hash (additional security layer)
  Future<bool> verifyBiometricHash(String userId) async {
    try {
      final storedHash = await SecureStorage.readSecureStorage(_biometricHashKey);
      if (storedHash == null || storedHash == 'ND') {
        return false;
      }

      final expectedHash = _generateBiometricHash(userId);
      return storedHash == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// Generate biometric hash for additional security
  String _generateBiometricHash(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$userId:biometric:$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if device is locked out due to failed attempts
  Future<bool> _isLockedOut() async {
    try {
      final attemptsStr = await SecureStorage.readSecureStorage(_authAttemptsKey);
      final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;

      if (attempts >= _maxAuthAttempts) {
        final lastAttemptStr = await SecureStorage.readSecureStorage(_lastAuthTimeKey);
        if (lastAttemptStr != null && lastAttemptStr != 'ND') {
          final lastAttempt = DateTime.fromMillisecondsSinceEpoch(int.parse(lastAttemptStr));
          final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
          
          if (timeSinceLastAttempt < _lockoutDuration) {
            return true;
          } else {
            // Reset attempts after lockout period
            await _resetAuthAttempts();
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if current session is still valid
  Future<bool> _isSessionValid() async {
    try {
      final lastAuthStr = await SecureStorage.readSecureStorage(_lastAuthTimeKey);
      if (lastAuthStr == null || lastAuthStr == 'ND') {
        return false;
      }

      final lastAuth = DateTime.fromMillisecondsSinceEpoch(int.parse(lastAuthStr));
      final timeSinceAuth = DateTime.now().difference(lastAuth);
      
      return timeSinceAuth < _sessionTimeout;
    } catch (e) {
      return false;
    }
  }

  /// Handle successful authentication
  Future<void> _onAuthenticationSuccess() async {
    try {
      await SecureStorage.writeSecureStorage(
        _lastAuthTimeKey, 
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      await _resetAuthAttempts();

      AnalyticsHelper.trackUserAction('biometric_auth_success');
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Auth success handling failed');
    }
  }

  /// Handle failed authentication
  Future<void> _onAuthenticationFailure() async {
    try {
      final attemptsStr = await SecureStorage.readSecureStorage(_authAttemptsKey);
      final attempts = (int.tryParse(attemptsStr ?? '0') ?? 0) + 1;
      
      await SecureStorage.writeSecureStorage(_authAttemptsKey, attempts.toString());
      await SecureStorage.writeSecureStorage(
        _lastAuthTimeKey, 
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      AnalyticsHelper.trackUserAction('biometric_auth_failure', parameters: {
        'attempts': attempts,
        'max_attempts': _maxAuthAttempts,
      });
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Auth failure handling failed');
    }
  }

  /// Reset authentication attempts
  Future<void> _resetAuthAttempts() async {
    try {
      await SecureStorage.writeSecureStorage(_authAttemptsKey, '0');
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Reset auth attempts failed');
    }
  }

  /// Map platform exception to error code
  BiometricErrorCode _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return BiometricErrorCode.notAvailable;
      case 'NotEnrolled':
        return BiometricErrorCode.notEnrolled;
      case 'PasscodeNotSet':
        return BiometricErrorCode.passcodeNotSet;
      case 'UserCancel':
        return BiometricErrorCode.userCancel;
      case 'UserFallback':
        return BiometricErrorCode.userFallback;
      case 'BiometricOnlyNotSupported':
        return BiometricErrorCode.biometricOnlyNotSupported;
      case 'DeviceNotSupported':
        return BiometricErrorCode.deviceNotSupported;
      case 'ApplicationLockout':
        return BiometricErrorCode.lockedOut;
      case 'BiometricLockout':
        return BiometricErrorCode.lockedOut;
      case 'NoFingerprintEnrolled':
        return BiometricErrorCode.notEnrolled;
      default:
        return BiometricErrorCode.unknown;
    }
  }

  /// Get error message for error code
  String _getErrorMessage(BiometricErrorCode errorCode) {
    switch (errorCode) {
      case BiometricErrorCode.notAvailable:
        return 'احراز هویت بیومتریک در دسترس نیست';
      case BiometricErrorCode.notEnrolled:
        return 'هیچ روش بیومتریک ثبت نشده است';
      case BiometricErrorCode.passcodeNotSet:
        return 'رمز عبور دستگاه تنظیم نشده است';
      case BiometricErrorCode.userCancel:
        return 'کاربر احراز هویت را لغو کرد';
      case BiometricErrorCode.userFallback:
        return 'کاربر از روش جایگزین استفاده کرد';
      case BiometricErrorCode.biometricOnlyNotSupported:
        return 'احراز هویت فقط بیومتریک پشتیبانی نمی‌شود';
      case BiometricErrorCode.deviceNotSupported:
        return 'دستگاه از احراز هویت بیومتریک پشتیبانی نمی‌کند';
      case BiometricErrorCode.lockedOut:
        return 'دستگاه به دلیل تلاش‌های ناموفق قفل شده است';
      case BiometricErrorCode.notEnabled:
        return 'احراز هویت بیومتریک فعال نشده است';
      case BiometricErrorCode.unknown:
        return 'خطای ناشناخته در احراز هویت';
    }
  }

  /// Get availability error message
  String _getAvailabilityErrorMessage(BiometricAvailability availability) {
    switch (availability) {
      case BiometricAvailability.notSupported:
        return 'دستگاه از احراز هویت بیومتریک پشتیبانی نمی‌کند';
      case BiometricAvailability.notEnrolled:
        return 'هیچ روش بیومتریک ثبت نشده است';
      case BiometricAvailability.lockedOut:
        return 'دستگاه به دلیل تلاش‌های ناموفق قفل شده است';
      case BiometricAvailability.error:
        return 'خطا در بررسی وضعیت احراز هویت بیومتریک';
      case BiometricAvailability.available:
        return 'احراز هویت بیومتریک در دسترس است';
    }
  }

  /// Get remaining lockout time
  Future<Duration?> getRemainingLockoutTime() async {
    if (!await _isLockedOut()) {
      return null;
    }

    try {
      final lastAttemptStr = await SecureStorage.readSecureStorage(_lastAuthTimeKey);
      if (lastAttemptStr != null && lastAttemptStr != 'ND') {
        final lastAttempt = DateTime.fromMillisecondsSinceEpoch(int.parse(lastAttemptStr));
        final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
        final remaining = _lockoutDuration - timeSinceLastAttempt;
        
        return remaining.isNegative ? null : remaining;
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get lockout time failed');
    }

    return null;
  }

  /// Get authentication attempts count
  Future<int> getAuthAttempts() async {
    try {
      final attemptsStr = await SecureStorage.readSecureStorage(_authAttemptsKey);
      return int.tryParse(attemptsStr ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

/// Biometric availability status
enum BiometricAvailability {
  available,
  notSupported,
  notEnrolled,
  lockedOut,
  error,
}

/// Biometric error codes
enum BiometricErrorCode {
  notAvailable,
  notEnrolled,
  passcodeNotSet,
  userCancel,
  userFallback,
  biometricOnlyNotSupported,
  deviceNotSupported,
  lockedOut,
  notEnabled,
  unknown,
}

/// Biometric authentication result
class BiometricResult {
  final bool success;
  final String? error;
  final BiometricErrorCode? errorCode;
  final bool fromCache;

  const BiometricResult._({
    required this.success,
    this.error,
    this.errorCode,
    this.fromCache = false,
  });

  factory BiometricResult.success({bool fromCache = false}) {
    return BiometricResult._(
      success: true,
      fromCache: fromCache,
    );
  }

  factory BiometricResult.failed({
    required String error,
    required BiometricErrorCode errorCode,
  }) {
    return BiometricResult._(
      success: false,
      error: error,
      errorCode: errorCode,
    );
  }
}

/// Biometric settings widget for user preferences
class BiometricSettingsWidget extends StatefulWidget {
  const BiometricSettingsWidget({
    super.key,
    required this.userId,
    this.onChanged,
  });

  final String userId;
  final Function(bool enabled)? onChanged;

  @override
  State<BiometricSettingsWidget> createState() => _BiometricSettingsWidgetState();
}

class _BiometricSettingsWidgetState extends State<BiometricSettingsWidget> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  
  bool _isEnabled = false;
  bool _isLoading = false;
  BiometricAvailability _availability = BiometricAvailability.error;
  List<BiometricType> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availability = await _biometricService.checkAvailability();
      final enabled = await _biometricService.isBiometricEnabled();
      final types = await _biometricService.getAvailableBiometrics();

      setState(() {
        _availability = availability;
        _isEnabled = enabled;
        _availableTypes = types;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (value) {
        final result = await _biometricService.enableBiometric(
          userId: widget.userId,
          reason: 'فعال‌سازی احراز هویت بیومتریک برای ورود آسان',
        );

        if (result.success) {
          setState(() {
            _isEnabled = true;
          });
          widget.onChanged?.call(true);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('احراز هویت بیومتریک فعال شد'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.error ?? 'خطا در فعال‌سازی'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        await _biometricService.disableBiometric();
        setState(() {
          _isEnabled = false;
        });
        widget.onChanged?.call(false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('احراز هویت بیومتریک غیرفعال شد'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getBiometricTypesText() {
    if (_availableTypes.isEmpty) return 'هیچ روش بیومتریک';
    
    final typeNames = _availableTypes.map((type) {
      switch (type) {
        case BiometricType.face:
          return 'تشخیص چهره';
        case BiometricType.fingerprint:
          return 'اثر انگشت';
        case BiometricType.iris:
          return 'تشخیص عنبیه';
        case BiometricType.strong:
          return 'بیومتریک قوی';
        case BiometricType.weak:
          return 'بیومتریک ضعیف';
      }
    }).toList();
    
    return typeNames.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fingerprint_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'احراز هویت بیومتریک',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_availability == BiometricAvailability.available)
                  Switch(
                    value: _isEnabled,
                    onChanged: _toggleBiometric,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusText(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_availableTypes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'روش‌های موجود: ${_getBiometricTypesText()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_availability) {
      case BiometricAvailability.available:
        return _isEnabled 
            ? 'احراز هویت بیومتریک فعال است'
            : 'احراز هویت بیومتریک غیرفعال است';
      case BiometricAvailability.notSupported:
        return 'دستگاه از احراز هویت بیومتریک پشتیبانی نمی‌کند';
      case BiometricAvailability.notEnrolled:
        return 'هیچ روش بیومتریک ثبت نشده است';
      case BiometricAvailability.lockedOut:
        return 'دستگاه به دلیل تلاش‌های ناموفق قفل شده است';
      case BiometricAvailability.error:
        return 'خطا در بررسی وضعیت احراز هویت بیومتریک';
    }
  }
}