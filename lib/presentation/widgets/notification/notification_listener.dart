import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/push_notification_service.dart';

class PushNotificationHandler extends StatefulWidget {
  final Widget child;
  
  const PushNotificationHandler({
    Key? key, 
    required this.child,
  }) : super(key: key);

  @override
  State<PushNotificationHandler> createState() => _PushNotificationHandlerState();
}

class _PushNotificationHandlerState extends State<PushNotificationHandler> {
  late final PushNotificationService _pushNotificationService;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  
  @override
  void initState() {
    super.initState();
    _pushNotificationService = GetIt.instance<PushNotificationService>();
    
    // Khởi tạo service nếu chưa được khởi tạo
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    await _pushNotificationService.initialize();
    
    // Đăng ký lắng nghe thông báo
    _messageSubscription = _pushNotificationService.messagesStream.listen(_showNotification);
  }
  
  void _showNotification(RemoteMessage message) {
    // Chỉ hiển thị notification nếu có title hoặc body
    if (message.notification?.title != null || message.notification?.body != null) {
      // Hiển thị thông báo dạng snackbar
      final snackBar = SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.notification?.title != null)
              Text(
                message.notification!.title!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            if (message.notification?.body != null)
              Text(message.notification!.body!),
          ],
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {
            // Xử lý khi nhấn vào thông báo
            _handleNotificationTap(message);
          },
        ),
      );
      
      // Hiển thị snackbar
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    // Xử lý khi người dùng nhấn vào thông báo
    final data = message.data;
    
    // Ví dụ: Nếu là thông báo liên quan đến phòng
    if (data.containsKey('roomId')) {
      // Điều hướng đến trang chi tiết phòng
      final roomId = data['roomId'];
      debugPrint('Đang chuyển đến trang chi tiết phòng: $roomId');
      
      // TODO: Thêm code điều hướng đến trang chi tiết phòng
      // Ví dụ: context.goNamed('room_detail', params: {'id': roomId});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
} 