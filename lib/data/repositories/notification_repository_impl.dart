import 'package:dio/dio.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/models.dart';
import '../../core/cache/cache.dart';
import 'notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final Dio _dio;
  final Cache _cache;

  NotificationRepositoryImpl({Cache? cache, Dio? dio})
      : _dio = dio ?? DioConfig.createDio(),
        _cache = cache ?? InMemoryCache();

  @override
  Future<Result<List<NotificationModel>>> getNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.notifications());
      final notifications = (response.data as List).map((e) => NotificationModel.fromJson(e)).toList();
      return Success(notifications);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get notifications');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<List<NotificationModel>>> getReadNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.readNotifications());
      final notifications = (response.data as List).map((e) => NotificationModel.fromJson(e)).toList();
      return Success(notifications);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get read notifications');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<List<NotificationModel>>> getUnReadNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.unReadNotifications());
      final notifications = (response.data as List).map((e) => NotificationModel.fromJson(e)).toList();
      return Success(notifications);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get unread notifications');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<void>> markAllNotificationsAsRead() async {
    try{
      final response = await _dio.post(ApiConstants.markAllNotificationsAsRead());
      if(response.statusCode == 200){
        return Success('All notifications marked as read');
      }
      return Failure('Failed to mark all notifications as read');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to mark all notifications as read');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<void>> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _dio.post(ApiConstants.markNotificationAsRead(notificationId));
      if(response.statusCode == 200){
        return Success('Notification marked as read');
      }
      return Failure('Failed to mark notification as read');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to mark notification as read');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<NotificationModel>> getNotificationDetail(String notificationId) async {
    try {
      final response = await _dio.get(ApiConstants.notification(notificationId));
      final notification = NotificationModel.fromJson(response.data);
      return Success(notification);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get notification detail');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }
}