import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:roomily/core/enums/notification_type.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/notification.dart';
import 'package:roomily/data/repositories/notification_repository.dart';

import 'notification_state.dart';

/// Cubit class that manages notification states and operations
class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _notificationRepository;

  /// Constructor
  NotificationCubit({
    required NotificationRepository notificationRepository,
  })  : _notificationRepository = notificationRepository,
        super(NotificationState.initial());

  /// Loads all notifications
  Future<void> loadNotifications() async {
    if (kDebugMode) {
      print('Loading all notifications...');
    }
    
    emit(state.copyWith(status: NotificationStatus.loading));

    final result = await _notificationRepository.getNotifications();

    if (result is Success<List<NotificationModel>>) {
      if (kDebugMode) {
        print('Successfully loaded ${result.data.length} notifications');
      }
      emit(state.copyWith(
        notifications: result.data,
        status: NotificationStatus.success,
      ));
    } else if (result is Failure) {
      final errorMessage = (result as Failure).message;
      if (kDebugMode) {
        print('Failed to load notifications: $errorMessage');
      }
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: errorMessage,
      ));
    }
  }

  /// Loads unread notifications
  Future<void> loadUnreadNotifications() async {
    if (kDebugMode) {
      print('Loading unread notifications...');
    }
    
    // Don't set loading state here to avoid overwriting previous state
    // Only update the unread notifications part of the state

    final result = await _notificationRepository.getUnReadNotifications();

    if (result is Success<List<NotificationModel>>) {
      if (kDebugMode) {
        print('Successfully loaded ${result.data.length} unread notifications');
      }
      emit(state.copyWith(
        unreadNotifications: result.data,
        // Keep the current status if it's success, otherwise set to success
        status: state.status == NotificationStatus.error 
            ? NotificationStatus.error 
            : NotificationStatus.success,
      ));
    } else if (result is Failure) {
      final errorMessage = (result as Failure).message;
      if (kDebugMode) {
        print('Failed to load unread notifications: $errorMessage');
      }
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: errorMessage,
      ));
    }
  }

  /// Loads read notifications
  Future<void> loadReadNotifications() async {
    if (kDebugMode) {
      print('Loading read notifications...');
    }
    
    // Don't set loading state here to avoid overwriting previous state
    // Only update the read notifications part of the state

    final result = await _notificationRepository.getReadNotifications();

    if (result is Success<List<NotificationModel>>) {
      if (kDebugMode) {
        print('Successfully loaded ${result.data.length} read notifications');
      }
      emit(state.copyWith(
        readNotifications: result.data,
        // Keep the current status if it's success, otherwise set to success
        status: state.status == NotificationStatus.error 
            ? NotificationStatus.error 
            : NotificationStatus.success,
      ));
    } else if (result is Failure) {
      final errorMessage = (result as Failure).message;
      if (kDebugMode) {
        print('Failed to load read notifications: $errorMessage');
      }
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: errorMessage,
      ));
    }
  }

  /// Marks a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    emit(state.copyWith(status: NotificationStatus.loading));

    final result = await _notificationRepository.markNotificationAsRead(notificationId);

    if (result is Success) {
      // Update the local state to reflect the change
      final updatedUnreadNotifications = state.unreadNotifications
          .where((notification) => notification.id != notificationId)
          .toList();

      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          // Create a new notification with isRead set to true
          return NotificationModel(
            id: notification.id,
            header: notification.header,
            body: notification.body,
            isRead: true,
            createdAt: notification.createdAt,
            userId: notification.userId,
          );
        }
        return notification;
      }).toList();

      // Find the notification that was marked as read
      final markedNotification = state.notifications.firstWhere(
        (notification) => notification.id == notificationId,
        orElse: () => throw Exception('Notification not found'),
      );

      // Create a new notification with isRead set to true
      final updatedNotification = NotificationModel(
        id: markedNotification.id,
        header: markedNotification.header,
        body: markedNotification.body,
        isRead: true,
        createdAt: markedNotification.createdAt,
        userId: markedNotification.userId,
      );

      // Add to read notifications
      final updatedReadNotifications = [...state.readNotifications, updatedNotification];

      emit(state.copyWith(
        unreadNotifications: updatedUnreadNotifications,
        readNotifications: updatedReadNotifications,
        notifications: updatedNotifications,
        status: NotificationStatus.success,
      ));
    } else if (result is Failure) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: (result as Failure).message,
      ));
    }
  }

  /// Marks all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    emit(state.copyWith(status: NotificationStatus.loading));

    final result = await _notificationRepository.markAllNotificationsAsRead();

    if (result is Success) {
      // Update all notifications to be read
      final updatedNotifications = state.notifications.map((notification) {
        return NotificationModel(
          id: notification.id,
          header: notification.header,
          body: notification.body,
          isRead: true,
          createdAt: notification.createdAt,
          userId: notification.userId,
        );
      }).toList();

      emit(state.copyWith(
        unreadNotifications: const [],
        readNotifications: updatedNotifications,
        notifications: updatedNotifications,
        status: NotificationStatus.success,
      ));
    } else if (result is Failure) {
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: (result as Failure).message,
      ));
    }
  }

  /// Gets notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    // Since we no longer have a type field, we'll need to determine type based on other properties
    // For example, we might use the notification header or body content
    final typeString = type.toString().split('.').last;
    
    // Use header or body to determine notification type
    return state.notifications
        .where((notification) => 
          _determineNotificationType(notification.header, notification.body) == typeString)
        .toList();
  }

  /// Gets notification icon by header/body content
  String getNotificationIcon(NotificationModel notification) {
    // Determine the type based on notification content
    String notificationType = _determineNotificationType(notification.header, notification.body);
    
    // Map the determined type to an icon
    switch (notificationType) {
      case 'NEW_BILL':
        return 'bill_icon';
      case 'NEW_COMMENT':
        return 'comment_icon';
      case 'NEW_REPORT':
        return 'report_icon';
      case 'SUBSCRIPTION_EXPIRY':
        return 'subscription_expired_icon';
      case 'SUBSCRIPTION_REMINDER':
        return 'subscription_reminder_icon';
      default:
        return 'default_icon';
    }
  }

  /// Gets notification display name based on header/body content
  String getNotificationDisplayName(NotificationModel notification) {
    // Determine the type based on notification content
    String notificationType = _determineNotificationType(notification.header, notification.body);
    
    // Map the determined type to a display name
    switch (notificationType) {
      case 'NEW_BILL':
        return 'Hóa đơn mới';
      case 'NEW_COMMENT':
        return 'Bình luận mới';
      case 'NEW_REPORT':
        return 'Báo cáo mới';
      case 'SUBSCRIPTION_EXPIRY':
        return 'Hết hạn đăng ký';
      case 'SUBSCRIPTION_REMINDER':
        return 'Nhắc nhở đăng ký';
      default:
        return 'Thông báo';
    }
  }

  /// Private helper method to determine notification type from content
  String _determineNotificationType(String header, String body) {
    // Check header and body to determine what type of notification it is
    final headerLower = header.toLowerCase();
    final bodyLower = body.toLowerCase();
    
    if (headerLower.contains('hóa đơn') || bodyLower.contains('hóa đơn') || 
        headerLower.contains('bill') || bodyLower.contains('bill')) {
      return 'NEW_BILL';
    } else if (headerLower.contains('bình luận') || bodyLower.contains('bình luận') || 
               headerLower.contains('comment') || bodyLower.contains('comment')) {
      return 'NEW_COMMENT';
    } else if (headerLower.contains('báo cáo') || bodyLower.contains('báo cáo') || 
               headerLower.contains('report') || bodyLower.contains('report')) {
      return 'NEW_REPORT';
    } else if (headerLower.contains('hết hạn') || bodyLower.contains('hết hạn') || 
               headerLower.contains('expired') || bodyLower.contains('expired')) {
      return 'SUBSCRIPTION_EXPIRY';
    } else if (headerLower.contains('nhắc nhở') || bodyLower.contains('nhắc nhở') || 
               headerLower.contains('reminder') || bodyLower.contains('reminder')) {
      return 'SUBSCRIPTION_REMINDER';
    } else {
      return 'DEFAULT';
    }
  }

  /// Gets notification detail by ID
  Future<void> getNotificationDetail(String notificationId) async {
    if (kDebugMode) {
      print('Loading notification detail for ID: $notificationId');
    }
    
    emit(state.copyWith(status: NotificationStatus.loading));

    final result = await _notificationRepository.getNotificationDetail(notificationId);

    if (result is Success<NotificationModel>) {
      if (kDebugMode) {
        print('Successfully loaded notification detail: ${result.data.header}');
      }
      
      // If notification is not read, mark it as read
      if (!result.data.isRead) {
        await markNotificationAsRead(notificationId);
      }
      
      emit(state.copyWith(
        selectedNotification: result.data,
        status: NotificationStatus.success,
      ));
    } else if (result is Failure) {
      final errorMessage = (result as Failure).message;
      if (kDebugMode) {
        print('Failed to load notification detail: $errorMessage');
      }
      emit(state.copyWith(
        status: NotificationStatus.error,
        errorMessage: errorMessage,
      ));
    }
  }
} 