// enum NotificationType {
//   NEW_BILL,
//   NEW_COMMENT,
//   NEW_REPORT,
//   SUBSCRIPTION_EXPIRY,
//   SUBSCRIPTION_REMINDER,
// }
//
// extension NotificationTypeExtension on NotificationType {
//   String get iconName {
//     switch (this) {
//       case NotificationType.NEW_BILL:
//         return 'bill_icon';
//       case NotificationType.NEW_COMMENT:
//         return 'comment_icon';
//       case NotificationType.NEW_REPORT:
//         return 'report_icon';
//       case NotificationType.SUBSCRIPTION_EXPIRY:
//         return 'subscription_expired_icon';
//       case NotificationType.SUBSCRIPTION_REMINDER:
//         return 'subscription_reminder_icon';
//     }
//   }
//
//   String get displayName {
//     switch (this) {
//       case NotificationType.NEW_BILL:
//         return 'Hóa đơn mới';
//       case NotificationType.NEW_COMMENT:
//         return 'Bình luận mới';
//       case NotificationType.NEW_REPORT:
//         return 'Báo cáo mới';
//       case NotificationType.SUBSCRIPTION_EXPIRY:
//         return 'Hết hạn đăng ký';
//       case NotificationType.SUBSCRIPTION_REMINDER:
//         return 'Nhắc nhở đăng ký';
//     }
//   }
// }