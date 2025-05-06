import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/data/repositories/user_repository.dart';
import 'package:roomily/core/services/message_handler_service.dart';
import 'package:roomily/data/blocs/chat_room/chat_room_cubit.dart';
import 'package:roomily/presentation/screens/chat_detail_screen_v2.dart';

// Xử lý message khi app ở background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AuthService _authService;
  final UserRepository _userRepository;
  
  // Stream controller cho notification message
  final StreamController<RemoteMessage> _messageStreamController = StreamController<RemoteMessage>.broadcast();
  
  // Stream để lắng nghe các notification
  Stream<RemoteMessage> get messagesStream => _messageStreamController.stream;

  // Trạng thái khởi tạo
  bool _isInitialized = false;

  // Constructor
  PushNotificationService({
    AuthService? authService,
    UserRepository? userRepository,
  }) : _authService = authService ?? GetIt.instance<AuthService>(),
       _userRepository = userRepository ?? GetIt.instance<UserRepository>();

  // Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Khởi tạo Firebase - Không cần thiết vì đã được khởi tạo trong main.dart
    // await Firebase.initializeApp();
    
    // Cấu hình handler cho background message
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Cấu hình channel cho Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', 
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
    
    // Khởi tạo local notifications
    await _initLocalNotifications();
    
    // Cấu hình foreground notification presentation
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Yêu cầu quyền thông báo
    await _requestPermission();
    
    // Đăng ký các handlers
    _registerNotificationHandlers();
    
    _isInitialized = true;
    debugPrint('🔔 Push Notification Service initialized successfully');
  }
  
  // Khởi tạo local notifications
  Future<void> _initLocalNotifications() async {
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng bấm vào notification
        _handleNotificationClick(response);
      },
    );
  }
  
  // Yêu cầu quyền
  Future<void> _requestPermission() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }
  
  // Đăng ký các handlers
  void _registerNotificationHandlers() {
    // Xử lý khi nhận được tin nhắn và app đang chạy (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📱 [FCM] Received message while app in foreground: ${message.messageId}');
      debugPrint('📱 [FCM] Message data: ${message.data}');
      debugPrint('📱 [FCM] Message notification: ${message.notification?.title} - ${message.notification?.body}');
      _messageStreamController.add(message);
      
      // Hiển thị local notification khi app đang foreground
      _showLocalNotification(message);
    });
    
    // Xử lý khi nhấn vào notification và app ở background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 [FCM] Message clicked while app in background: ${message.messageId}');
      debugPrint('📱 [FCM] Background click data: ${message.data}');
      _messageStreamController.add(message);
    });
    
    // Kiểm tra nếu ứng dụng được mở từ notification khi ở trạng thái terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 [FCM] App opened from terminated state by notification: ${message.messageId}');
        debugPrint('📱 [FCM] Terminated notification data: ${message.data}');
        _messageStreamController.add(message);
      }
    });
  }
  
  // Hiển thị local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    debugPrint('📱 [FCM] Showing local notification: ${notification?.title}');
    
    if (notification != null && android != null && Platform.isAndroid) {
      debugPrint('📱 [FCM] Showing Android notification: ${notification.title}');
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: json.encode(message.data),
      );
      debugPrint('📱 [FCM] Android notification shown successfully');
    } else if (notification != null && Platform.isIOS) {
      debugPrint('📱 [FCM] Showing iOS notification: ${notification.title}');
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
      debugPrint('📱 [FCM] iOS notification shown successfully');
    } else {
      debugPrint('📱 [FCM] Cannot show notification: notification=${notification != null}, android=${android != null}, isAndroid=${Platform.isAndroid}');
    }
  }
  
  // Xử lý khi click vào notification
  void _handleNotificationClick(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        debugPrint('Notification clicked with data: $data');
        
        // Nếu MessageHandlerService đã được đăng ký, sử dụng nó để xử lý thông báo
        if (GetIt.instance.isRegistered<MessageHandlerService>()) {
          final messageHandlerService = GetIt.instance<MessageHandlerService>();
          messageHandlerService.initialize(); // Đảm bảo service đã được khởi tạo
          
          // Để đảm bảo rằng notification tap listener được cài đặt
          // Mặc định MessageHandlerService sẽ tự động xử lý các thông báo qua LocalNotificationService
          
          // Xử lý nếu có chatRoomId
          if (data.containsKey('chatRoomId')) {
            final chatRoomId = data['chatRoomId'];
            debugPrint('Handling navigation to chat room: $chatRoomId');
            
            // Lấy thông tin người dùng hiện tại
            final authService = GetIt.instance<AuthService>();
            final currentUserId = authService.userId;
            final List<String> userRoles = authService.roles;
            final userRole = userRoles.isNotEmpty ? userRoles.first : null;
            
            // Nếu ChatRoomCubit đã được đăng ký, sử dụng nó để điều hướng
            if (GetIt.instance.isRegistered<ChatRoomCubit>()) {
              final chatRoomCubit = GetIt.instance<ChatRoomCubit>();
              
              // Tải thông tin chat room
              chatRoomCubit.getChatRoomInfoWithoutNavigation(chatRoomId).then((_) {
                // Kiểm tra trạng thái sau khi load
                if (chatRoomCubit.state is ChatRoomInfoCached) {
                  final chatRoomInfo = (chatRoomCubit.state as ChatRoomInfoCached).chatRoomInfo;
                  
                  // Lấy navigatorKey để điều hướng
                  final navigatorKey = GetIt.instance<GlobalKey<NavigatorState>>();
                  final context = navigatorKey.currentContext;
                  
                  if (context != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreenV2(
                          chatRoomInfo: chatRoomInfo,
                          currentUserId: currentUserId,
                          userRole: userRole,
                        ),
                      ),
                    );
                    debugPrint('Successfully navigated to chat detail from notification');
                  }
                }
              });
            }
          }
          // else if (data.containsKey('roomId')) {
          //   // Xử lý điều hướng đến phòng
          //   final roomId = data['roomId'];
          //   debugPrint('Handling navigation to room: $roomId');
          //
          //   // Điều hướng đến trang chi tiết phòng
          //   final navigatorKey = GetIt.instance<GlobalKey<NavigatorState>>();
          //   final context = navigatorKey.currentContext;
          //
          //   if (context != null && GoRouter.of(context) != null) {
          //     // Điều hướng đến trang chi tiết phòng
          //     GoRouter.of(context).go('/rooms/$roomId');
          //   }
          // }
        }
      } catch (e) {
        debugPrint('Error handling notification click: $e');
      }
    }
  }

  
  // Lấy FCM token
  Future<String?> getToken() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final token = await _messaging.getToken();
    debugPrint('📱 [FCM] Token: $token');
    return token;
  }
  
  // Đăng ký topic
  Future<void> subscribeToTopic(String topic) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }
  
  // Hủy đăng ký topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
  
  // Đăng ký FCM token với server
  Future<void> registerTokenWithServer() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final userId = _authService.userId;
    if (userId == null) {
      debugPrint('📱 [FCM] Cannot register FCM token: User is not logged in');
      return;
    }
    
    final token = await _messaging.getToken();
    if (token != null) {
      // Gửi token lên server của bạn
      debugPrint('📱 [FCM] Sending FCM token to server for user $userId');
      debugPrint('📱 [FCM] Token: $token');
      
      // Sử dụng UserRepository để đăng ký token
      try {
        await _userRepository.registerFcmToken(userId, token);
        debugPrint('📱 [FCM] Token registered successfully with server');
      } catch (e) {
        debugPrint('📱 [FCM] Error registering token with server: $e');
      }
    } else {
      debugPrint('📱 [FCM] Failed to get FCM token');
    }
  }
  
  // Hủy đăng ký khi không cần thiết
  Future<void> dispose() async {
    _messageStreamController.close();
  }
} 