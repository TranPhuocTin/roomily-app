/// Enum defining all possible notification types in the application
enum NotificationType {
  /// Notification for new bills created
  NEW_BILL,
  
  /// Notification for new comments
  NEW_COMMENT,
  
  /// Notification for new reports
  NEW_REPORT,
  
  /// Notification when subscription expires
  SUBSCRIPTION_EXPIRY,
  
  /// Notification reminder before subscription expires
  SUBSCRIPTION_REMINDER,
}

/// Extension methods for NotificationType enum
extension NotificationTypeExtension on NotificationType {
  /// Gets a user-friendly display name for the notification type
  String get displayName {
    switch (this) {
      case NotificationType.NEW_BILL:
        return 'Hóa đơn mới';
      case NotificationType.NEW_COMMENT:
        return 'Bình luận mới';
      case NotificationType.NEW_REPORT:
        return 'Báo cáo mới';
      case NotificationType.SUBSCRIPTION_EXPIRY:
        return 'Hết hạn đăng ký';
      case NotificationType.SUBSCRIPTION_REMINDER:
        return 'Nhắc nhở đăng ký';
    }
  }
  
  /// Gets the associated icon name for this notification type
  String get iconName {
    switch (this) {
      case NotificationType.NEW_BILL:
        return 'bill_icon';
      case NotificationType.NEW_COMMENT:
        return 'comment_icon';
      case NotificationType.NEW_REPORT:
        return 'report_icon';
      case NotificationType.SUBSCRIPTION_EXPIRY:
        return 'subscription_expired_icon';
      case NotificationType.SUBSCRIPTION_REMINDER:
        return 'subscription_reminder_icon';
    }
  }
} 