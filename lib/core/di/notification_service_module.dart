import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/push_notification_service.dart';

class NotificationServiceModule {
  static void register() {
    final getIt = GetIt.instance;
    
    // Đăng ký PushNotificationService singleton
    getIt.registerLazySingleton<PushNotificationService>(
      () => PushNotificationService(),
    );
  }
} 