import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:roomily/core/services/local_notification_service.dart';
import 'package:roomily/data/blocs/chat_room/chat_room_cubit.dart';

/// Utility class to handle notification navigation and setup
class NotificationHandler {
  final BuildContext context;
  final LocalNotificationService _localNotificationService;
  
  NotificationHandler(this.context)
      : _localNotificationService = GetIt.I<LocalNotificationService>();
  
  /// Setup listener for notification taps
  void setupNotificationTapListener({GoRouter? router}) {
    _localNotificationService.onNotificationTap.listen((payloadString) {
      if (payloadString != null) {
        _handleNotificationTap(payloadString, router: router);
      }
    });
  }
  
  /// Handle notification tap based on payload type
  void _handleNotificationTap(String payloadString, {GoRouter? router}) {
    try {
      final payloadData = jsonDecode(payloadString);
      final String type = payloadData['type'] ?? '';
      
      switch (type) {
        case 'chat_message':
          _navigateToChatRoom(payloadData, router: router);
          break;
        // Handle other notification types here
        default:
          debugPrint('⚠️ Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }
  
  /// Navigate to chat room from notification
  void _navigateToChatRoom(Map<String, dynamic> payload, {GoRouter? router}) {
    final chatRoomId = payload['chatRoomId'];
    if (chatRoomId != null) {
      // Option 1: Use GetIt to navigate through ChatRoomCubit
      if (GetIt.I.isRegistered<ChatRoomCubit>()) {
        GetIt.I<ChatRoomCubit>().getChatRoomInfo(chatRoomId);
        return;
      }
      
      // Option 2: Use GoRouter if available
      if (router != null) {
        router.push('/chat/detail/$chatRoomId');
        return;
      }
      
      // Option 3: Use context navigation (least preferred)
      Navigator.of(context, rootNavigator: true).pushNamed(
        '/chat/detail',
        arguments: {'chatRoomId': chatRoomId},
      );
    }
  }
  
  /// Helper method to cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotificationService.cancelAllNotifications();
  }
  
  /// Helper method to cancel notifications for a specific chat room
  Future<void> cancelChatRoomNotifications(String chatRoomId) async {
    await _localNotificationService.cancelChatRoomNotifications(chatRoomId);
  }
} 