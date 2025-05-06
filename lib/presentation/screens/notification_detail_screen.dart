import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/notification.dart';
import 'package:intl/intl.dart';

import '../../data/blocs/notification/notification_cubit.dart';
import '../../data/blocs/notification/notification_state.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({
    Key? key,
    required this.notificationId,
  }) : super(key: key);

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load notification detail when screen is initialized
    context.read<NotificationCubit>().getNotificationDetail(widget.notificationId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
        elevation: 0,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              final notification = state.selectedNotification;
              if (notification == null || notification.isRead) {
                return const SizedBox.shrink();
              }
              
              return IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Đánh dấu đã đọc',
                onPressed: () {
                  context.read<NotificationCubit>().markNotificationAsRead(widget.notificationId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đánh dấu thông báo là đã đọc'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == NotificationStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đã xảy ra lỗi: ${state.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.read<NotificationCubit>().getNotificationDetail(widget.notificationId),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final notification = state.selectedNotification;
          if (notification == null) {
            return const Center(child: Text('Không tìm thấy thông báo'));
          }

          return _buildNotificationDetail(notification, theme);
        },
      ),
    );
  }

  Widget _buildNotificationDetail(NotificationModel notification, ThemeData theme) {
    final iconName = _getNotificationIcon(notification);
    final displayName = _getNotificationDisplayName(notification);
    final date = _parseDate(notification.createdAt);
    final notificationColor = _getNotificationColor(notification);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with icon and title
          Container(
            width: double.infinity,
            color: theme.primaryColor.withOpacity(0.05),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            notificationColor.withOpacity(0.8),
                            notificationColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: notificationColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconData(iconName),
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.header,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: notificationColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: notificationColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Date and time section
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      date != null 
                          ? DateFormat('HH:mm - dd/MM/yyyy').format(date)
                          : 'Không có thông tin thời gian',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nội dung thông báo',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    const Spacer(),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: notificationColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map your icon names to IconData
    final iconMap = {
      'default_icon': Icons.notifications,
      'message': Icons.message,
      'alert': Icons.warning,
      'info': Icons.info,
      'bill_icon': Icons.receipt_long,
      'comment_icon': Icons.comment,
      'report_icon': Icons.report_problem,
      'subscription_expired_icon': Icons.timer_off,
      'subscription_reminder_icon': Icons.timer,
    };

    return iconMap[iconName] ?? Icons.notifications;
  }

  String _getNotificationIcon(NotificationModel notification) {
    // Determine icon based on notification content
    final headerLower = notification.header.toLowerCase();
    final bodyLower = notification.body.toLowerCase();
    
    if (headerLower.contains('hóa đơn') || bodyLower.contains('hóa đơn') || 
        headerLower.contains('bill') || bodyLower.contains('bill')) {
      return 'bill_icon';
    } else if (headerLower.contains('bình luận') || bodyLower.contains('bình luận') || 
               headerLower.contains('comment') || bodyLower.contains('comment')) {
      return 'comment_icon';
    } else if (headerLower.contains('báo cáo') || bodyLower.contains('báo cáo') || 
               headerLower.contains('report') || bodyLower.contains('report')) {
      return 'report_icon';
    } else if (headerLower.contains('hết hạn') || bodyLower.contains('hết hạn') || 
               headerLower.contains('expired') || bodyLower.contains('expired')) {
      return 'subscription_expired_icon';
    } else if (headerLower.contains('nhắc nhở') || bodyLower.contains('nhắc nhở') || 
               headerLower.contains('reminder') || bodyLower.contains('reminder')) {
      return 'subscription_reminder_icon';
    } else {
      return 'default_icon';
    }
  }

  String _getNotificationDisplayName(NotificationModel notification) {
    final type = _determineNotificationType(notification);
    
    final titleMap = {
      'NEW_REPORT': 'Báo cáo mới',
      'NEW_BILL': 'Hóa đơn mới',
      'NEW_COMMENT': 'Bình luận mới',
      'SUBSCRIPTION_EXPIRY': 'Hết hạn đăng ký',
      'SUBSCRIPTION_REMINDER': 'Nhắc nhở đăng ký',
      'DEFAULT': 'Thông báo',
    };
    
    return titleMap[type] ?? 'Thông báo';
  }

  Color _getNotificationColor(NotificationModel notification) {
    // Determine notification type based on header and body content
    String notificationType = _determineNotificationType(notification);
    
    // Map of notification types to colors
    final colorMap = {
      'NEW_REPORT': const Color(0xFFE57373),      // Đỏ đậm vừa
      'NEW_BILL': const Color(0xFFBA68C8),        // Tím đậm vừa
      'NEW_COMMENT': const Color(0xFF66BB6A),     // Xanh lá đậm vừa
      'SUBSCRIPTION_EXPIRY': const Color(0xFFF06292),  // Hồng đậm vừa
      'SUBSCRIPTION_REMINDER': const Color(0xFFFFB74D), // Cam đậm vừa
      'DEFAULT': const Color(0xFF78909C),         // Xám đậm vừa
    };
    
    return colorMap[notificationType] ?? const Color(0xFF78909C);
  }
  
  String _determineNotificationType(NotificationModel notification) {
    // Check header and body to determine what type of notification it is
    final headerLower = notification.header.toLowerCase();
    final bodyLower = notification.body.toLowerCase();
    
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

  DateTime? _parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
} 