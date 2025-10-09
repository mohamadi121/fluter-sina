import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Advanced Firebase Integration and Configuration System
class FirebaseManager {
  static final FirebaseManager _instance = FirebaseManager._internal();
  factory FirebaseManager() => _instance;
  FirebaseManager._internal();

  // Firebase services
  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;
  FirebasePerformance? _performance;
  FirebaseMessaging? _messaging;
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  // Configuration
  bool _isInitialized = false;
  String? _fcmToken;
  StreamSubscription<User?>? _authStateSubscription;

  /// Initialize Firebase services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase Core
      await Firebase.initializeApp();
      
      // Initialize individual services
      await _initializeAnalytics();
      await _initializeCrashlytics();
      await _initializePerformance();
      await _initializeMessaging();
      await _initializeAuth();
      await _initializeGoogleSignIn();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('Firebase services initialized successfully');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Firebase initialization error: $error');
      }
      rethrow;
    }
  }

  /// Initialize Firebase Analytics
  Future<void> _initializeAnalytics() async {
    _analytics = FirebaseAnalytics.instance;
    
    // Set default parameters
    await _analytics?.setDefaultParameters({
      'app_version': '1.0.0',
      'platform': defaultTargetPlatform.name,
    });
    
    // Enable analytics collection
    await _analytics?.setAnalyticsCollectionEnabled(true);
    
    if (kDebugMode) {
      debugPrint('Firebase Analytics initialized');
    }
  }

  /// Initialize Firebase Crashlytics
  Future<void> _initializeCrashlytics() async {
    _crashlytics = FirebaseCrashlytics.instance;
    
    // Enable automatic crash reporting
    await _crashlytics?.setCrashlyticsCollectionEnabled(true);
    
    // Set up custom keys
    await _crashlytics?.setCustomKey('initialized_at', DateTime.now().toIso8601String());
    await _crashlytics?.setCustomKey('platform', defaultTargetPlatform.name);
    
    // Set up Flutter error handling
    FlutterError.onError = (errorDetails) {
      _crashlytics?.recordFlutterFatalError(errorDetails);
    };
    
    // Set up Dart error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics?.recordError(error, stack, fatal: true);
      return true;
    };
    
    if (kDebugMode) {
      debugPrint('Firebase Crashlytics initialized');
    }
  }

  /// Initialize Firebase Performance
  Future<void> _initializePerformance() async {
    _performance = FirebasePerformance.instance;
    
    // Enable performance monitoring
    await _performance?.setPerformanceCollectionEnabled(true);
    
    if (kDebugMode) {
      debugPrint('Firebase Performance initialized');
    }
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeMessaging() async {
    _messaging = FirebaseMessaging.instance;
    
    // Request permissions
    final settings = await _messaging?.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings?.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        debugPrint('User granted permission for notifications');
      }
    }
    
    // Get FCM token
    _fcmToken = await _messaging?.getToken();
    if (kDebugMode) {
      debugPrint('FCM Token: $_fcmToken');
    }
    
    // Listen for token refresh
    _messaging?.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _onTokenRefresh(token);
    });
    
    // Set up message handlers
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
    
    if (kDebugMode) {
      debugPrint('Firebase Messaging initialized');
    }
  }

  /// Initialize Firebase Auth
  Future<void> _initializeAuth() async {
    _auth = FirebaseAuth.instance;
    
    // Listen to auth state changes
    _authStateSubscription = _auth?.authStateChanges().listen(_onAuthStateChanged);
    
    if (kDebugMode) {
      debugPrint('Firebase Auth initialized');
    }
  }

  /// Initialize Google Sign-In
  Future<void> _initializeGoogleSignIn() async {
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
      ],
    );
    
    if (kDebugMode) {
      debugPrint('Google Sign-In initialized');
    }
  }

  /// Handle foreground messages
  void _onForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Received foreground message: ${message.notification?.title}');
    }
    
    // Handle foreground notification
    _handleNotification(message);
  }

  /// Handle message when app is opened from notification
  void _onMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('App opened from notification: ${message.notification?.title}');
    }
    
    // Handle notification tap
    _handleNotificationTap(message);
  }

  /// Handle background messages
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('Background message: ${message.notification?.title}');
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) {
    if (kDebugMode) {
      debugPrint('FCM Token refreshed: $token');
    }
    
    // Send token to server
    _sendTokenToServer(token);
  }

  /// Handle auth state changes
  void _onAuthStateChanged(User? user) {
    if (user != null) {
      if (kDebugMode) {
        debugPrint('User signed in: ${user.email}');
      }
      
      // Set user properties for analytics
      _analytics?.setUserId(id: user.uid);
      _crashlytics?.setUserIdentifier(user.uid);
      
      // Track sign-in event
      logEvent('user_sign_in', parameters: {
        'method': 'firebase_auth',
        'user_id': user.uid,
      });
    } else {
      if (kDebugMode) {
        debugPrint('User signed out');
      }
      
      // Clear user properties
      _analytics?.setUserId(id: null);
      _crashlytics?.setUserIdentifier('');
      
      // Track sign-out event
      logEvent('user_sign_out');
    }
  }

  /// Handle notification display
  void _handleNotification(RemoteMessage message) {
    // Implement notification display logic
    // This would typically show an in-app notification or update UI
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Implement navigation logic based on notification data
    final data = message.data;
    
    if (data.containsKey('route')) {
      // Navigate to specific route
      _navigateToRoute(data['route']);
    }
  }

  /// Navigate to route from notification
  void _navigateToRoute(String route) {
    // Implement navigation logic
    if (kDebugMode) {
      debugPrint('Navigating to route: $route');
    }
  }

  /// Send FCM token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      // Implement API call to send token to server
      if (kDebugMode) {
        debugPrint('Sending FCM token to server: $token');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error sending FCM token: $error');
      }
    }
  }

  /// Log analytics event
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    try {
      await _analytics?.logEvent(
        name: name,
        parameters: parameters,
      );
      
      if (kDebugMode) {
        debugPrint('Analytics event logged: $name');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error logging analytics event: $error');
      }
    }
  }

  /// Log custom error
  Future<void> logError(
    dynamic exception, 
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics?.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
      
      if (kDebugMode) {
        debugPrint('Error logged to Crashlytics: $exception');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error logging to Crashlytics: $error');
      }
    }
  }

  /// Create performance trace
  Trace? createTrace(String name) {
    try {
      return _performance?.newTrace(name);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error creating performance trace: $error');
      }
      return null;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Start performance trace
      final trace = createTrace('google_sign_in');
      await trace?.start();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
      
      if (googleUser == null) {
        await trace?.stop();
        return null; // User canceled
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the credential
      final userCredential = await _auth?.signInWithCredential(credential);
      
      await trace?.stop();
      
      // Log successful sign-in
      logEvent('google_sign_in_success', parameters: {
        'user_id': userCredential?.user?.uid,
        'email': userCredential?.user?.email,
      });
      
      return userCredential;
    } catch (error) {
      // Log error
      logError(error, StackTrace.current, reason: 'Google Sign-In failed');
      
      logEvent('google_sign_in_error', parameters: {
        'error': error.toString(),
      });
      
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn?.signOut();
      
      // Sign out from Firebase
      await _auth?.signOut();
      
      logEvent('user_sign_out_success');
    } catch (error) {
      logError(error, StackTrace.current, reason: 'Sign out failed');
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _auth?.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Get analytics instance
  FirebaseAnalytics? get analytics => _analytics;

  /// Get crashlytics instance
  FirebaseCrashlytics? get crashlytics => _crashlytics;

  /// Get performance instance
  FirebasePerformance? get performance => _performance;

  /// Get messaging instance
  FirebaseMessaging? get messaging => _messaging;

  /// Get auth instance
  FirebaseAuth? get auth => _auth;

  /// Get Google Sign-In instance
  GoogleSignIn? get googleSignIn => _googleSignIn;

  /// Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      
      logEvent('fcm_topic_subscribe', parameters: {
        'topic': topic,
      });
      
      if (kDebugMode) {
        debugPrint('Subscribed to topic: $topic');
      }
    } catch (error) {
      logError(error, StackTrace.current, reason: 'Topic subscription failed');
    }
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      
      logEvent('fcm_topic_unsubscribe', parameters: {
        'topic': topic,
      });
      
      if (kDebugMode) {
        debugPrint('Unsubscribed from topic: $topic');
      }
    } catch (error) {
      logError(error, StackTrace.current, reason: 'Topic unsubscription failed');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    _authStateSubscription = null;
    _isInitialized = false;
  }
}

/// Firebase configuration constants
class FirebaseConfig {
  FirebaseConfig._();

  // Analytics events
  static const String loginEvent = 'login';
  static const String signUpEvent = 'sign_up';
  static const String purchaseEvent = 'purchase';
  static const String viewItemEvent = 'view_item';
  static const String addToCartEvent = 'add_to_cart';
  static const String beginCheckoutEvent = 'begin_checkout';

  // FCM topics
  static const String generalTopic = 'general';
  static const String promotionsTopic = 'promotions';
  static const String updatesTopic = 'updates';
  static const String deviceAlertsTopic = 'device_alerts';

  // Performance traces
  static const String appStartTrace = 'app_start';
  static const String loginTrace = 'login_flow';
  static const String apiCallTrace = 'api_call';
  static const String imageLoadTrace = 'image_load';
  static const String databaseTrace = 'database_operation';
}

/// Firebase analytics helper
class AnalyticsHelper {
  static final FirebaseManager _firebase = FirebaseManager();

  /// Track screen view
  static Future<void> trackScreenView(String screenName) async {
    await _firebase.logEvent('screen_view', parameters: {
      'screen_name': screenName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Track user action
  static Future<void> trackUserAction(String action, {Map<String, Object?>? parameters}) async {
    await _firebase.logEvent('user_action', parameters: {
      'action': action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    });
  }

  /// Track API call
  static Future<void> trackApiCall(String endpoint, {int? statusCode, int? duration}) async {
    await _firebase.logEvent('api_call', parameters: {
      'endpoint': endpoint,
      'status_code': statusCode,
      'duration_ms': duration,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Track error
  static Future<void> trackError(String errorType, String errorMessage) async {
    await _firebase.logEvent('error_occurred', parameters: {
      'error_type': errorType,
      'error_message': errorMessage,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Track performance metric
  static Future<void> trackPerformance(String metric, double value) async {
    await _firebase.logEvent('performance_metric', parameters: {
      'metric_name': metric,
      'metric_value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

/// Performance monitoring helper
class PerformanceHelper {
  static final FirebaseManager _firebase = FirebaseManager();

  /// Create and start trace
  static Trace? startTrace(String name) {
    final trace = _firebase.createTrace(name);
    trace?.start();
    return trace;
  }

  /// Stop trace with custom metrics
  static Future<void> stopTrace(Trace? trace, {Map<String, int>? metrics}) async {
    if (trace != null) {
      if (metrics != null) {
        for (final entry in metrics.entries) {
          trace.setMetric(entry.key, entry.value);
        }
      }
      await trace.stop();
    }
  }

  /// Measure operation performance
  static Future<T> measureOperation<T>(
    String traceName,
    Future<T> Function() operation,
  ) async {
    final trace = startTrace(traceName);
    try {
      final result = await operation();
      await stopTrace(trace);
      return result;
    } catch (error) {
      await stopTrace(trace, metrics: {'error': 1});
      rethrow;
    }
  }
}