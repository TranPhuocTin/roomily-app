import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:roomily/data/repositories/notification_repository_impl.dart';

import '../../data/blocs/notification/notification_cubit.dart';

/// Service to manage notifications throughout the app
class NotificationService {
  // Sử dụng getter để đảm bảo notificationCubit luôn được khởi tạo khi được truy cập
  NotificationCubit get notificationCubit {
    if (_notificationCubit == null) {
      _notificationCubit = NotificationCubit(
        notificationRepository: NotificationRepositoryImpl(),
      );
      // Tự động tải dữ liệu thông báo nếu chưa được khởi tạo
      if (!_isInitialized) {
        _loadNotifications();
      }
    }
    return _notificationCubit!;
  }
  
  NotificationCubit? _notificationCubit;
  Timer? _refreshTimer;
  bool _isInitialized = false;
  
  /// Initialize the notification service
  Future<void> initialize() async {
    // Tránh khởi tạo nhiều lần
    if (_isInitialized) return;
    
    // Đảm bảo notificationCubit đã được khởi tạo
    if (_notificationCubit == null) {
      _notificationCubit = NotificationCubit(
        notificationRepository: NotificationRepositoryImpl(),
      );
    }
    
    // Initial load of notifications
    await _loadNotifications();
    
    // Set up periodic refresh of notifications (every 2 minutes)
    // _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
    //   _loadNotifications();
    // });
    
    _isInitialized = true;
  }
  
  /// Load all notification data
  Future<void> _loadNotifications() async {
    try {
      await notificationCubit.loadNotifications();
      await notificationCubit.loadUnreadNotifications();
      await notificationCubit.loadReadNotifications();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
    }
  }
  //
  // /// Force a refresh of all notifications
  // Future<void> refreshNotifications() async {
  //   return _loadNotifications();
  // }
  
  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    _notificationCubit?.close();
    _notificationCubit = null;
    _isInitialized = false;
  }
} 