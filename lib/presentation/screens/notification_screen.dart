import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/enums/notification_type.dart';
import 'package:roomily/data/models/notification.dart';
import 'package:roomily/data/repositories/notification_repository.dart';
import 'package:roomily/data/repositories/notification_repository_impl.dart';
import 'package:roomily/presentation/screens/notification_detail_screen.dart';
import 'package:roomily/presentation/widgets/common/empty_state_widget.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/notification_service.dart';

import '../../data/blocs/notification/notification_cubit.dart';
import '../../data/blocs/notification/notification_state.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late NotificationCubit _notificationCubit;
  late TabController _tabController;
  bool _isLoading = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _notificationCubit = GetIt.I<NotificationService>().notificationCubit;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAllNotifications();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllNotifications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all notifications
      await _notificationCubit.loadNotifications();
      // Load unread notifications
      await _notificationCubit.loadUnreadNotifications();
      // Load read notifications
      await _notificationCubit.loadReadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải thông báo: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return Future.value();
    
    try {
      // Tải lại tất cả thông báo
      await _loadAllNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi làm mới: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocProvider.value(
      value: _notificationCubit,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          // backgroundColor: Colors.transparent,
          title: const Text('Thông báo'),
          elevation: 0,
          actions: [
            // Nút refresh
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại thông báo',
              onPressed: () {
                if (mounted) {
                  _loadAllNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang tải lại thông báo...'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                if (state.unreadNotifications.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Đánh dấu tất cả đã đọc',
                  onPressed: () {
                    _notificationCubit.markAllNotificationsAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chưa đọc'),
              Tab(text: 'Đã đọc'),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background Layer
            Positioned.fill(
              child: Image.asset(
                'assets/images/chat_background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Overlay Layer
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            // Content Layer
            Positioned.fill(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        key: GlobalKey<RefreshIndicatorState>(),
                        onRefresh: _handleRefresh,
                        child: _buildNotificationList(context, NotificationTab.all),
                      ),
                      RefreshIndicator(
                        key: GlobalKey<RefreshIndicatorState>(),
                        onRefresh: _handleRefresh,
                        child: _buildNotificationList(context, NotificationTab.unread),
                      ),
                      RefreshIndicator(
                        key: GlobalKey<RefreshIndicatorState>(),
                        onRefresh: _handleRefresh,
                        child: _buildNotificationList(context, NotificationTab.read),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context, NotificationTab tab) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state.status == NotificationStatus.error) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 100),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đã xảy ra lỗi: ${state.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadAllNotifications,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final notifications = _getNotificationsForTab(state, tab);

        if (notifications.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 100),
              EmptyStateWidget(
                icon: Icons.notifications_off_outlined,
                title: 'Không có thông báo nào',
                message: 'Hiện tại bạn không có thông báo nào trong mục này',
              ),
            ],
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            // Group notifications by date
            final notification = notifications[index];
            final bool isFirstOfDay = index == 0 || 
                !_isSameDay(notification.createdAt, notifications[index - 1].createdAt);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFirstOfDay) 
                  _buildDateHeader(notification.createdAt),
                _buildNotificationCard(notification, context),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, BuildContext context) {
    final theme = Theme.of(context);
    final iconName = _getNotificationIcon(notification);
    final notificationColor = _getNotificationColor(notification);
    final notificationTitle = _getNotificationTitle(notification);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: notification.isRead 
            ? null 
            : Border.all(color: notificationColor.withOpacity(0.7), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: _notificationCubit,
                  child: NotificationDetailScreen(
                    notificationId: notification.id,
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cột 1 - Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        notificationColor.withOpacity(0.8),
                        notificationColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: notificationColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getIconData(iconName),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Cột 2 - Header và Body
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        notification.header,
                        style: TextStyle(
                          fontWeight: notification.isRead 
                              ? FontWeight.w500 
                              : FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Body
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Cột 3 - Time và Type
                Container(
                  width: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Time và chỉ báo chưa đọc
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: notificationColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Type badge (chỉ hiển thị khi chưa đọc)
                      if (!notification.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: notificationColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notificationTitle,
                            style: TextStyle(
                              color: notificationColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        const SizedBox(height: 18), // Giữ chiều cao nhất quán
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      String displayDate;
      if (_isSameDay(date, now)) {
        displayDate = 'Hôm nay';
      } else if (_isSameDay(date, yesterday)) {
        displayDate = 'Hôm qua';
      } else {
        displayDate = DateFormat('dd/MM/yyyy').format(date);
      }
      
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            Text(
              displayDate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  bool _isSameDay(dynamic date1, dynamic date2) {
    try {
      final d1 = date1 is DateTime ? date1 : DateTime.parse(date1);
      final d2 = date2 is DateTime ? date2 : DateTime.parse(date2);
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (e) {
      return false;
    }
  }

  List<NotificationModel> _getNotificationsForTab(NotificationState state, NotificationTab tab) {
    switch (tab) {
      case NotificationTab.all:
        return state.notifications;
      case NotificationTab.unread:
        return state.unreadNotifications;
      case NotificationTab.read:
        return state.readNotifications;
    }
  }

  IconData _getIconData(String iconName) {
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

  String _getNotificationTitle(NotificationModel notification) {
    String type = _determineNotificationType(notification);
    
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
  
  String _determineNotificationType(NotificationModel notification) {
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
}

enum NotificationTab {
  all,
  unread,
  read,
} 