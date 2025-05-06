import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/notification.dart';

/// Enum defining the status of notification operations
enum NotificationStatus {
  /// Initial state
  initial,
  
  /// Loading state when fetching notifications
  loading,
  
  /// Success state when notifications are loaded successfully
  success,
  
  /// Error state when there is an error loading notifications
  error,
}

/// State class for notifications
class NotificationState extends Equatable {
  /// All notifications
  final List<NotificationModel> notifications;
  
  /// Unread notifications
  final List<NotificationModel> unreadNotifications;
  
  /// Read notifications
  final List<NotificationModel> readNotifications;
  
  /// Currently selected notification for detail view
  final NotificationModel? selectedNotification;
  
  /// Current status of notification operations
  final NotificationStatus status;
  
  /// Error message if any
  final String? errorMessage;
  
  /// Whether there are any unread notifications
  bool get hasUnreadNotifications => unreadNotifications.isNotEmpty;
  
  /// Number of unread notifications
  int get unreadCount => unreadNotifications.length;

  /// Constructor
  const NotificationState({
    this.notifications = const [],
    this.unreadNotifications = const [],
    this.readNotifications = const [],
    this.selectedNotification,
    this.status = NotificationStatus.initial,
    this.errorMessage,
  });

  /// Initial state factory
  factory NotificationState.initial() {
    return const NotificationState();
  }

  /// Copy with method to create a new instance with updated properties
  NotificationState copyWith({
    List<NotificationModel>? notifications,
    List<NotificationModel>? unreadNotifications,
    List<NotificationModel>? readNotifications,
    NotificationModel? selectedNotification,
    NotificationStatus? status,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      readNotifications: readNotifications ?? this.readNotifications,
      selectedNotification: selectedNotification ?? this.selectedNotification,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        unreadNotifications,
        readNotifications,
        selectedNotification,
        status,
        errorMessage,
      ];
} 