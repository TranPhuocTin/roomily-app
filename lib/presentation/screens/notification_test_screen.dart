// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:roomily/blocs/notification/notification_cubit.dart';
// import 'package:roomily/blocs/notification/notification_state.dart';
// import 'package:roomily/core/enums/notification_type.dart';
// import 'package:roomily/data/models/notification.dart';
// import 'package:roomily/data/repositories/notification_repository.dart';
// import 'package:roomily/data/repositories/notification_repository_impl.dart';
// import 'package:flutter/foundation.dart';
// import 'package:roomily/presentation/screens/notification_detail_screen.dart';
//
// class NotificationTestScreen extends StatefulWidget {
//   const NotificationTestScreen({super.key});
//
//   @override
//   State<NotificationTestScreen> createState() => _NotificationTestScreenState();
// }
//
// class _NotificationTestScreenState extends State<NotificationTestScreen> {
//   late NotificationCubit _notificationCubit;
//   late NotificationRepository _repository;
//   String _debugMessage = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _repository = NotificationRepositoryImpl();
//     _notificationCubit = NotificationCubit(
//       notificationRepository: _repository,
//     );
//     _loadNotifications();
//   }
//
//   Future<void> _loadNotifications() async {
//     try {
//       setState(() {
//         _debugMessage = 'Loading notifications...';
//       });
//
//       // Load all notifications first
//       await _notificationCubit.loadNotifications();
//
//       setState(() {
//         _debugMessage += '\nAll notifications loaded.';
//       });
//
//       // Then load unread notifications
//       await _notificationCubit.loadUnreadNotifications();
//
//       setState(() {
//         _debugMessage += '\nUnread notifications loaded.';
//       });
//
//       // Finally load read notifications
//       await _notificationCubit.loadReadNotifications();
//
//       setState(() {
//         _debugMessage += '\nRead notifications loaded.';
//       });
//     } catch (e) {
//       setState(() {
//         _debugMessage += '\nError: $e';
//       });
//       if (kDebugMode) {
//         print('Error loading notifications: $e');
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _notificationCubit.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: _notificationCubit,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Notification Test'),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: _loadNotifications,
//             ),
//             BlocBuilder<NotificationCubit, NotificationState>(
//               builder: (context, state) {
//                 return TextButton.icon(
//                   onPressed: state.unreadNotifications.isEmpty
//                       ? null
//                       : () => _notificationCubit.markAllNotificationsAsRead(),
//                   icon: const Icon(Icons.mark_email_read),
//                   label: const Text('Mark All Read'),
//                 );
//               },
//             ),
//           ],
//         ),
//         body: Column(
//           children: [
//             // Debug info section
//             if (kDebugMode)
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 color: Colors.amber.shade100,
//                 width: double.infinity,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
//                     Text(_debugMessage),
//                   ],
//                 ),
//               ),
//
//             // Notification list
//             Expanded(
//               child: BlocBuilder<NotificationCubit, NotificationState>(
//                 builder: (context, state) {
//                   if (state.status == NotificationStatus.loading) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//
//                   if (state.status == NotificationStatus.error) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Error: ${state.errorMessage}',
//                             style: const TextStyle(color: Colors.red),
//                           ),
//                           const SizedBox(height: 16),
//                           ElevatedButton(
//                             onPressed: _loadNotifications,
//                             child: const Text('Retry'),
//                           ),
//                         ],
//                       ),
//                     );
//                   }
//
//                   if (state.notifications.isEmpty) {
//                     return const Center(
//                       child: Text('No notifications'),
//                     );
//                   }
//
//                   return RefreshIndicator(
//                     onRefresh: _loadNotifications,
//                     child: ListView(
//                       children: [
//                         if (state.unreadNotifications.isNotEmpty) ...[
//                           const Padding(
//                             padding: EdgeInsets.all(16.0),
//                             child: Text(
//                               'Unread Notifications',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           ...state.unreadNotifications.map(
//                             (notification) => _buildNotificationTile(notification),
//                           ),
//                           const Divider(height: 32),
//                         ],
//                         if (state.readNotifications.isNotEmpty) ...[
//                           const Padding(
//                             padding: EdgeInsets.all(16.0),
//                             child: Text(
//                               'Read Notifications',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                           ...state.readNotifications.map(
//                             (notification) => _buildNotificationTile(notification),
//                           ),
//                         ],
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//         floatingActionButton: FloatingActionButton(
//           onPressed: _showFilterDialog,
//           child: const Icon(Icons.filter_list),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNotificationTile(NotificationModel notification) {
//     final iconName = _notificationCubit.getNotificationIcon(notification.type);
//     final displayName = _notificationCubit.getNotificationDisplayName(notification.type);
//
//     return ListTile(
//       leading: Icon(
//         _getIconData(iconName),
//         color: notification.isRead ? Colors.grey : Theme.of(context).primaryColor,
//       ),
//       title: Text(
//         notification.header,
//         style: TextStyle(
//           fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
//         ),
//       ),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(notification.body),
//           const SizedBox(height: 4),
//           Text(
//             displayName,
//             style: TextStyle(
//               color: Theme.of(context).primaryColor,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//       trailing: notification.isRead
//           ? null
//           : IconButton(
//               icon: const Icon(Icons.mark_email_read),
//               onPressed: () =>
//                   _notificationCubit.markNotificationAsRead(notification.id),
//             ),
//       onTap: () {
//         // Handle notification tap
//         if (!notification.isRead) {
//           _notificationCubit.markNotificationAsRead(notification.id);
//         }
//
//         // Navigate to notification detail screen
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => BlocProvider.value(
//               value: _notificationCubit,
//               child: NotificationDetailScreen(
//                 notificationId: notification.id,
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   IconData _getIconData(String iconName) {
//     // Map your icon names to IconData
//     final iconMap = {
//       'default_icon': Icons.notifications,
//       'message': Icons.message,
//       'alert': Icons.warning,
//       'info': Icons.info,
//       // Add more mappings as needed
//     };
//
//     return iconMap[iconName] ?? Icons.notifications;
//   }
//
//   Future<void> _showFilterDialog() async {
//     final selectedType = await showDialog<NotificationType>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Filter by Type'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: NotificationType.values.map((type) {
//             return ListTile(
//               leading: Icon(_getIconData(
//                 _notificationCubit.getNotificationIcon(type.toString().split('.').last),
//               )),
//               title: Text(_notificationCubit.getNotificationDisplayName(
//                 type.toString().split('.').last,
//               )),
//               onTap: () => Navigator.pop(context, type),
//             );
//           }).toList(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//         ],
//       ),
//     );
//
//     if (selectedType != null && mounted) {
//       final filteredNotifications =
//           _notificationCubit.getNotificationsByType(selectedType);
//
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Found ${filteredNotifications.length} ${_notificationCubit.getNotificationDisplayName(selectedType.toString().split('.').last)} notifications',
//           ),
//         ),
//       );
//     }
//   }
// }