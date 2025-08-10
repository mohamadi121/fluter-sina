/// Environment configuration using dart-define
/// Usage: flutter run --dart-define=ENVIRONMENT=dev --dart-define=BASE_URL=https://api.asoud.ir
class EnvConfig {
  EnvConfig._();

  /// Environment type (dev, staging, prod)
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  /// Base API URL
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.asoud.ir',
  );

  /// WebSocket base URL
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://api.asoud.ir/ws',
  );

  /// Enable debug logs
  static const bool enableLogs = String.fromEnvironment(
    'ENABLE_LOGS',
    defaultValue: 'false',
  ) == 'true';

  /// Enable UI/UX preview features
  static const bool uiUxPreview = String.fromEnvironment(
    'UIUX_PREVIEW',
    defaultValue: 'false',
  ) == 'true';

  /// API timeout in seconds
  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30,
  );

  /// Check if running in development
  static bool get isDev => environment == 'dev';

  /// Check if running in staging
  static bool get isStaging => environment == 'staging';

  /// Check if running in production
  static bool get isProd => environment == 'prod';

  /// Get configuration summary for debugging
  static Map<String, dynamic> get summary => {
        'environment': environment,
        'baseUrl': baseUrl,
        'wsBaseUrl': wsBaseUrl,
        'enableLogs': enableLogs,
        'uiUxPreview': uiUxPreview,
        'apiTimeout': apiTimeout,
      };
}
