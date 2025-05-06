import 'dart:async';
import 'dart:convert';
import 'package:roomily/main.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:get_it/get_it.dart';
import 'auth_service.dart';

class StompService {
  static final StompService _instance = StompService._internal();
  factory StompService() => _instance;


  static const String _webSocketUrl = 'https://api.roomily.tech/ws';  // SockJS endpoint
  // static const String _webSocketUrl = 'https://sadly-stirred-marmoset.ngrok-free.app/ws';  // SockJS endpoint

  static const Duration _reconnectDelay = Duration(seconds: 2);
  static const int _maxReconnectAttempts = 5;

  
  late StompClient _stompClient;
  final _connectionStatusController = StreamController<bool>.broadcast();
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;
  StreamSubscription? _authStateSubscription;
  
  // Add subscription management
  final Map<String, StompUnsubscribe> _activeSubscriptions = {};
  
  // Expose connection status stream
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool get isConnected => _stompClient.connected;
  
  StompService._internal() {
    print('[STOMP Service] Initializing StompService');
    _initializeStompClient();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    try {
      final authService = GetIt.instance<AuthService>();
      _authStateSubscription = authService.authStateChanges.listen((isAuthenticated) {
        print('[STOMP Service] Auth state changed: $isAuthenticated');
        if (isAuthenticated) {
          // User logged in or token refreshed
          print('[STOMP Service] User authenticated, reinitializing STOMP client with new token');
          _reinitializeStompClient();
        } else {
          // User logged out
          print('[STOMP Service] User logged out, disconnecting STOMP client');
          disconnect();
        }
      });
    } catch (e) {
      print('[STOMP Service] Error setting up auth state listener: $e');
    }
  }

  void _reinitializeStompClient() {
    print('[STOMP Service] Reinitializing STOMP client');
    // Unsubscribe from all active subscriptions
    _unsubscribeAll();
    
    // Disconnect existing client if connected
    if (_stompClient.connected) {
      print('[STOMP Service] Disconnecting existing STOMP client');
      _stompClient.deactivate();
    }
    
    // Initialize a new client
    _initializeStompClient();
    
    // Connect with new client
    print('[STOMP Service] Connecting with new STOMP client');
    connect();
  }

  void _onConnect(StompFrame frame) {
    print('[STOMP Service] Connected to STOMP server');
    print('[STOMP Service] Connection frame: ${frame.command}');
    print('[STOMP Service] Connection headers: ${frame.headers}');
    _connectionStatusController.add(true);
    _reconnectAttempts = 0;
  }

  void _onDisconnect(StompFrame? frame) {
    print('[STOMP Service] Disconnected from STOMP server');
    if (frame != null) {
      print('[STOMP Service] Disconnect frame: ${frame.command}');
      print('[STOMP Service] Disconnect headers: ${frame.headers}');
    }
    _connectionStatusController.add(false);
    
    if (!_isDisposed) {
      print('[STOMP Service] Service not disposed, attempting reconnect');
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[STOMP Service] Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_isDisposed && !_stompClient.connected) {
        print('[STOMP Service] Attempting to reconnect... (Attempt ${_reconnectAttempts + 1})');
        _reconnectAttempts++;
        connect();
      }
    });
  }

  void _initializeStompClient() {
    print('[STOMP Service] Initializing STOMP client');
    print('[STOMP Service] WebSocket URL: $_webSocketUrl');

    // Get current token
    String? token;
    try {
      token = GetIt.instance<AuthService>().token;
      print('[STOMP Service] Using token: ${token != null ? "Valid token" : "No token"}');
    } catch (e) {
      print('[STOMP Service] Error getting auth token: $e');
    }
    
    Map<String, String> headers = {};
    if (token != null) {
      headers = {'Authorization': 'Bearer $token'};
    }
    
    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: _webSocketUrl,
        onConnect: _onConnect,
        beforeConnect: () async {
          print('[STOMP Service] Before connect callback triggered');
          await Future.delayed(const Duration(milliseconds: 200));
          print('[STOMP Service] Initiating connection...');
        },
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onDisconnect: _onDisconnect,
        onWebSocketError: (dynamic error) {
          print('[STOMP Service] WebSocket Error: $error');
          if (error is Error) {
            print('[STOMP Service] WebSocket Error Stack: ${error.stackTrace}');
          }
          _onDisconnect(null);
        },
        onStompError: (frame) {
          print('[STOMP Service] STOMP Error: ${frame.body}');
          print('[STOMP Service] STOMP Error Headers: ${frame.headers}');
        },
        onDebugMessage: (String message) {
          print('[STOMP Service Debug] $message');
        },
        reconnectDelay: Duration(milliseconds: _reconnectDelay.inMilliseconds),
      ),
    );
    print('[STOMP Service] STOMP client initialized');
  }

  // Connect to STOMP server
  void connect() {
    if (_isDisposed) {
      print('[STOMP Service] Cannot connect - service has been disposed');
      throw Exception('StompService has been disposed');
    }
    
    if (_stompClient.connected) {
      print('[STOMP Service] Already connected to STOMP server');
      return;
    }

    try {
      print('[STOMP Service] Activating STOMP client connection');
      _stompClient.activate();
    } catch (e) {
      print('[STOMP Service] Error connecting to STOMP: $e');
      if (e is Error) {
        print('[STOMP Service] Connection error stack trace: ${e.stackTrace}');
      }
      _onDisconnect(null);
    }
  }

  // Disconnect from STOMP server
  void disconnect() {
    print('[STOMP Service] Initiating disconnect');
    _reconnectTimer?.cancel();
    if (_stompClient.connected) {
      _stompClient.deactivate();
    }
  }

  // Add method to unsubscribe from all subscriptions
  void _unsubscribeAll() {
    print('[STOMP Service] Unsubscribing from all active subscriptions');
    for (var subscription in _activeSubscriptions.values) {
      try {
        subscription();
      } catch (e) {
        print('[STOMP Service] Error unsubscribing: $e');
      }
    }
    _activeSubscriptions.clear();
  }

  // Modify subscribe method to track subscriptions
  StompUnsubscribe subscribe(
    String destination,
    void Function(StompFrame) callback,
  ) {
    print('[STOMP Service] Attempting to subscribe to: $destination');
    if (!_stompClient.connected) {
      print('[STOMP Service] Cannot subscribe - STOMP client not connected');
      throw Exception('STOMP client not connected');
    }
    
    try {
      // Unsubscribe if already subscribed
      if (_activeSubscriptions.containsKey(destination)) {
        print('[STOMP Service] Already subscribed to $destination, unsubscribing first');
        _activeSubscriptions[destination]!();
        _activeSubscriptions.remove(destination);
      }

      final subscription = _stompClient.subscribe(
        destination: destination,
        callback: (frame) {
          print('[STOMP Service] Received message on $destination');
          print('[STOMP Service] Message headers: ${frame.headers}');
          callback(frame);
        },
      );
      
      // Store the subscription
      _activeSubscriptions[destination] = subscription;
      print('[STOMP Service] Successfully subscribed to: $destination');
      return subscription;
    } catch (e) {
      print('[STOMP Service] Error subscribing to $destination: $e');
      if (e is Error) {
        print('[STOMP Service] Subscription error stack trace: ${e.stackTrace}');
      }
      rethrow;
    }
  }

  // Send message to a destination
  void send(String destination, dynamic message) {
    print('[STOMP Service] Attempting to send message to: $destination');
    if (!_stompClient.connected) {
      print('[STOMP Service] Cannot send message - STOMP client not connected');
      throw Exception('STOMP client not connected');
    }
    
    try {
      final encodedMessage = json.encode(message);
      print('[STOMP Service] Sending message: $encodedMessage');
      _stompClient.send(
        destination: destination,
        body: encodedMessage,
      );
      print('[STOMP Service] Message sent successfully to: $destination');
    } catch (e) {
      print('[STOMP Service] Error sending message to $destination: $e');
      if (e is Error) {
        print('[STOMP Service] Send error stack trace: ${e.stackTrace}');
      }
      rethrow;
    }
  }

  // Dispose resources
  void dispose() {
    print('[STOMP Service] Disposing StompService');
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _authStateSubscription?.cancel();
    _unsubscribeAll();
    disconnect();
    _connectionStatusController.close();
  }
} 