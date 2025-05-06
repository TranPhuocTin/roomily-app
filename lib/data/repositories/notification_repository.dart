import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/notification.dart';

abstract class NotificationRepository {
  //Get list notifications
  Future<Result<List<NotificationModel>>> getNotifications();
  //Mark notification as read
  Future<Result<void>> markNotificationAsRead(String notificationId);
  //Mark all notifications as read
  Future<Result<void>> markAllNotificationsAsRead();
  //Get unread notification
  Future<Result<List<NotificationModel>>> getUnReadNotifications();
  //Get read notification
  Future<Result<List<NotificationModel>>> getReadNotifications();
  //Get notification detail
  Future<Result<NotificationModel>> getNotificationDetail(String notificationId);
}