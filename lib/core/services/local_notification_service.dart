import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/data/models/chat_message.dart';
import 'package:roomily/data/models/chat_room.dart';

class LocalNotificationService {
  // Singleton instance
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  
  // GetIt instance
  final GetIt _getIt = GetIt.instance;
  
  // Flutter Local Notifications plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Notification Details
  NotificationDetails? _platformChannelSpecifics;
  
  // Channel ID and Name
  final String _channelId = 'messages';
  final String _channelName = 'Chat Messages';
  final String _channelDescription = 'This channel is used for chat message notifications';
  
  // Initialization status
  bool _isInitialized = false;
  
  // Stream controller for notification taps
  final StreamController<String?> _selectNotificationController = 
      StreamController<String?>.broadcast();
  
  // Stream to listen to notification taps
  Stream<String?> get onNotificationTap => _selectNotificationController.stream;
  
  // Constructor
  LocalNotificationService._internal();
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔄 LocalNotifications: Already initialized, skipping initialization');
      }
      return;
    }
    
    try {
      if (kDebugMode) {
        print('🚀 LocalNotifications: Initializing local notification service');
      }
      
      // Initialize notification settings for Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      // Initialize notification settings for iOS
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );
          
      // Combined initialization settings
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // Initialize the plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );
      
      // Configure notification channel for Android
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
            
        // Create the Android notification channel
        await _createNotificationChannel();
      }
      
      // Configure notification permissions for iOS
      if (Platform.isIOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
      
      // Create platform specifics for notifications
      _createNotificationDetails();
      
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ LocalNotifications: Local notification service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LocalNotifications: Error initializing local notification service: $e');
      }
    }
  }
  
  // Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'messages', // id
      'Chat Messages', // name
      description: 'This channel is used for chat message notifications', // description
      importance: Importance.high,
    );
    
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  // Create notification details
  void _createNotificationDetails() {
    // Android specific details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'messages',
      'Chat Messages',
      channelDescription: 'This channel is used for chat message notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    // iOS specific details
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    // Combined platform specifics
    _platformChannelSpecifics = const NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
  }
  
  // Handle when a notification is tapped
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      if (kDebugMode) {
        print('🔔 LocalNotifications: Notification tapped with payload: $payload');
      }
      _selectNotificationController.add(payload);
    }
  }
  
  // Show notification for a chat message
  Future<void> showMessageNotification(ChatMessage message, String senderName, String? roomName) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        if (kDebugMode) {
          print('❌ LocalNotifications: Failed to initialize: $e');
        }
        return; // Skip showing notification if initialization fails
      }
    }
    
    // Check if platform specifics is initialized
    if (_platformChannelSpecifics == null) {
      _createNotificationDetails();
    }
    
    try {
      String title = senderName;
      String body = message.content ?? 'New message';
      
      if (message.senderId == null) {
        title = roomName ?? 'Roomily';
        body = 'System notification: ${message.content}';
      }
      
      // Create payload with chat room ID for navigation
      final Map<String, dynamic> payloadData = {
        'chatRoomId': message.chatRoomId,
        'messageId': message.id,
        'type': 'chat_message'
      };
      
      final String payload = jsonEncode(payloadData);
      
      // Show notification
      await _flutterLocalNotificationsPlugin.show(
        message.chatRoomId.hashCode, // Notification ID based on chat room ID
        title,
        body,
        _platformChannelSpecifics,
        payload: payload,
      );
      
      if (kDebugMode) {
        print('🔔 LocalNotifications: Message notification sent for ${message.chatRoomId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LocalNotifications: Error showing message notification: $e');
      }
    }
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    if (kDebugMode) {
      print('🧹 LocalNotifications: All notifications cleared');
    }
  }
  
  // Cancel notifications for a specific chat room
  Future<void> cancelChatRoomNotifications(String chatRoomId) async {
    await _flutterLocalNotificationsPlugin.cancel(chatRoomId.hashCode);
    if (kDebugMode) {
      print('🧹 LocalNotifications: Notifications for chat room $chatRoomId cleared');
    }
  }
  
  // Dispose resources
  void dispose() {
    if (!_selectNotificationController.isClosed) {
      _selectNotificationController.close();
    }
    if (kDebugMode) {
      print('♻️ LocalNotifications: Disposing LocalNotificationService');
    }
  }
} 