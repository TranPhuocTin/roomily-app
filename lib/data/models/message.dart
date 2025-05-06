class Message {
  final String id;
  final String senderName;
  final String senderAvatar;
  final String lastMessage;
  final String time;
  final int unreadCount;

  Message({
    required this.id,
    required this.senderName,
    required this.senderAvatar,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });
} 