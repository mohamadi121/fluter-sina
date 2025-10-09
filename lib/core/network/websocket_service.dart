import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';

import '../helper/secure_storage.dart';
import '../firebase/firebase_manager.dart';
import '../../features/auth/services/security_service.dart';
import 'enhanced_http_client.dart';

/// WebSocket Integration Service for Real-time Communication
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  final SecurityService _security = SecurityService();
  final EnhancedHttpClient _httpClient = EnhancedHttpClient();

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  String? _currentUrl;

  // Configuration
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const int _maxReconnectAttempts = 10;
  static const Duration _connectionTimeout = Duration(seconds: 15);

  // Event streams
  final StreamController<WebSocketEvent> _eventController = StreamController<WebSocketEvent>.broadcast();
  final StreamController<ConnectionState> _connectionController = StreamController<ConnectionState>.broadcast();

  /// Stream of WebSocket events
  Stream<WebSocketEvent> get events => _eventController.stream;

  /// Stream of connection state changes
  Stream<ConnectionState> get connectionState => _connectionController.stream;

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Connect to WebSocket server
  Future<void> connect({
    required String url,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    if (_isConnecting || _isConnected) {
      debugPrint('[WebSocket] Already connected or connecting');
      return;
    }

    try {
      _isConnecting = true;
      _currentUrl = url;
      _connectionController.add(ConnectionState.connecting);

      // Add authentication headers
      final authHeaders = await _buildAuthHeaders();
      final finalHeaders = {
        ...?headers,
        ...authHeaders,
      };

      debugPrint('[WebSocket] Connecting to: $url');

      // Create WebSocket connection
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        headers: finalHeaders,
        connectTimeout: timeout ?? _connectionTimeout,
      );

      // Wait for connection to be established
      await _channel!.ready;

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      _connectionController.add(ConnectionState.connected);

      // Setup message listener
      _setupMessageListener();

      // Start heartbeat
      _startHeartbeat();

      // Log successful connection
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'WebSocket connected successfully',
        metadata: {
          'url': url,
          'has_auth': authHeaders.isNotEmpty,
        },
      );

      // Track analytics
      AnalyticsHelper.trackUserAction('websocket_connected', parameters: {
        'url': url,
        'reconnect_attempt': _reconnectAttempts,
      });

    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(ConnectionState.disconnected);

      FirebaseManager().logError(e, StackTrace.current, reason: 'WebSocket connection failed');

      await _security.logSecurityEvent(
        SecurityEventType.suspiciousActivity,
        'WebSocket connection failed',
        metadata: {
          'url': url,
          'error': e.toString(),
          'attempt': _reconnectAttempts,
        },
      );

      // Schedule reconnection if enabled
      if (_shouldReconnect) {
        _scheduleReconnect();
      }

      rethrow;
    }
  }

  /// Setup message listener
  void _setupMessageListener() {
    _messageSubscription = _channel!.stream.listen(
      (message) => _handleMessage(message),
      onError: (error) => _handleError(error),
      onDone: () => _handleDisconnection(),
      cancelOnError: false,
    );
  }

  /// Handle incoming message
  void _handleMessage(dynamic message) {
    try {
      final event = _parseMessage(message);
      _eventController.add(event);

      // Handle special message types
      if (event.type == WebSocketEventType.pong) {
        _handlePong(event);
      } else if (event.type == WebSocketEventType.error) {
        _handleServerError(event);
      }

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'WebSocket message handling failed');
      
      _eventController.add(WebSocketEvent(
        type: WebSocketEventType.error,
        data: {'error': 'Failed to parse message', 'raw_message': message.toString()},
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Parse incoming message
  WebSocketEvent _parseMessage(dynamic message) {
    try {
      if (message is String) {
        // Try to parse as JSON
        try {
          final json = jsonDecode(message);
          return WebSocketEvent.fromJson(json);
        } catch (e) {
          // Treat as plain text message
          return WebSocketEvent(
            type: WebSocketEventType.message,
            data: {'text': message},
            timestamp: DateTime.now(),
          );
        }
      } else {
        // Binary message
        return WebSocketEvent(
          type: WebSocketEventType.binary,
          data: {'data': message},
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      return WebSocketEvent(
        type: WebSocketEventType.error,
        data: {'error': 'Failed to parse message'},
        timestamp: DateTime.now(),
      );
    }
  }

  /// Handle WebSocket error
  void _handleError(dynamic error) {
    debugPrint('[WebSocket] Error: $error');

    FirebaseManager().logError(error, StackTrace.current, reason: 'WebSocket error');

    _eventController.add(WebSocketEvent(
      type: WebSocketEventType.error,
      data: {'error': error.toString()},
      timestamp: DateTime.now(),
    ));

    // Attempt reconnection
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    debugPrint('[WebSocket] Disconnected');

    _isConnected = false;
    _connectionController.add(ConnectionState.disconnected);

    _eventController.add(WebSocketEvent(
      type: WebSocketEventType.disconnected,
      data: {},
      timestamp: DateTime.now(),
    ));

    // Stop heartbeat
    _stopHeartbeat();

    // Attempt reconnection
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Handle pong response
  void _handlePong(WebSocketEvent event) {
    debugPrint('[WebSocket] Received pong');
    
    _eventController.add(WebSocketEvent(
      type: WebSocketEventType.heartbeat,
      data: {'status': 'alive'},
      timestamp: DateTime.now(),
    ));
  }

  /// Handle server error
  void _handleServerError(WebSocketEvent event) {
    final errorData = event.data;
    
    FirebaseManager().logError(
      'WebSocket server error: ${errorData?['message']}',
      StackTrace.current,
      reason: 'WebSocket server error',
    );

    // Log security event for server errors
    _security.logSecurityEvent(
      SecurityEventType.suspiciousActivity,
      'WebSocket server error received',
      metadata: errorData,
    );
  }

  /// Build authentication headers
  Future<Map<String, String>> _buildAuthHeaders() async {
    try {
      final headers = <String, String>{};

      // Add device fingerprint
      final deviceFingerprint = await _security.getDeviceFingerprint();
      if (deviceFingerprint != null) {
        headers['X-Device-ID'] = deviceFingerprint;
      }

      // Add session token if available
      final sessionResult = await _security.validateSession();
      if (sessionResult.isValid && sessionResult.sessionToken != null) {
        headers['Authorization'] = 'Bearer ${sessionResult.sessionToken}';
      }

      // Add timestamp and request ID
      headers['X-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
      headers['X-Request-ID'] = _generateRequestId();

      return headers;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Build auth headers failed');
      return {};
    }
  }

  /// Generate unique request ID
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecondsSinceEpoch % 1000).toString();
  }

  /// Send message through WebSocket
  Future<void> send(dynamic message) async {
    if (!_isConnected || _channel == null) {
      throw WebSocketException('Not connected to WebSocket server');
    }

    try {
      String messageToSend;
      
      if (message is Map || message is List) {
        messageToSend = jsonEncode(message);
      } else {
        messageToSend = message.toString();
      }

      _channel!.sink.add(messageToSend);

      debugPrint('[WebSocket] Sent: $messageToSend');

      // Log message sent
      _eventController.add(WebSocketEvent(
        type: WebSocketEventType.sent,
        data: {'message': messageToSend},
        timestamp: DateTime.now(),
      ));

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'WebSocket send failed');
      
      _eventController.add(WebSocketEvent(
        type: WebSocketEventType.error,
        data: {'error': 'Failed to send message: ${e.toString()}'},
        timestamp: DateTime.now(),
      ));
      
      rethrow;
    }
  }

  /// Send JSON message
  Future<void> sendJson(Map<String, dynamic> data) async {
    await send(data);
  }

  /// Send ping message
  Future<void> ping() async {
    await sendJson({
      'type': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Start heartbeat timer
  void _startHeartbeat() {
    _stopHeartbeat(); // Stop existing timer if any
    
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        ping().catchError((e) {
          debugPrint('[WebSocket] Heartbeat failed: $e');
        });
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WebSocket] Max reconnect attempts reached');
      
      _connectionController.add(ConnectionState.failed);
      
      _eventController.add(WebSocketEvent(
        type: WebSocketEventType.error,
        data: {'error': 'Max reconnection attempts reached'},
        timestamp: DateTime.now(),
      ));
      
      return;
    }

    _reconnectAttempts++;
    
    final delay = _reconnectDelay * _reconnectAttempts;
    debugPrint('[WebSocket] Scheduling reconnect in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)');

    _connectionController.add(ConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && _currentUrl != null) {
        connect(url: _currentUrl!);
      }
    });
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    try {
      _shouldReconnect = false;
      
      // Cancel timers
      _stopHeartbeat();
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      // Cancel message subscription
      await _messageSubscription?.cancel();
      _messageSubscription = null;

      // Close channel
      await _channel?.sink.close();
      _channel = null;

      _isConnected = false;
      _isConnecting = false;
      _reconnectAttempts = 0;

      _connectionController.add(ConnectionState.disconnected);

      debugPrint('[WebSocket] Disconnected successfully');

      // Log disconnection
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'WebSocket disconnected',
      );

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'WebSocket disconnect failed');
    }
  }

  /// Enable automatic reconnection
  void enableReconnection() {
    _shouldReconnect = true;
  }

  /// Disable automatic reconnection
  void disableReconnection() {
    _shouldReconnect = false;
  }

  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'is_connected': _isConnected,
      'is_connecting': _isConnecting,
      'reconnect_attempts': _reconnectAttempts,
      'should_reconnect': _shouldReconnect,
      'current_url': _currentUrl,
    };
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}

/// WebSocket event types
enum WebSocketEventType {
  connected,
  disconnected,
  message,
  binary,
  error,
  sent,
  ping,
  pong,
  heartbeat,
}

/// WebSocket connection states
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// WebSocket event data class
class WebSocketEvent {
  final WebSocketEventType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  WebSocketEvent({
    required this.type,
    this.data,
    required this.timestamp,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      type: WebSocketEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WebSocketEventType.message,
      ),
      data: json['data'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

/// WebSocket exception
class WebSocketException implements Exception {
  final String message;
  
  WebSocketException(this.message);
  
  @override
  String toString() => 'WebSocketException: $message';
}