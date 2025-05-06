import 'package:flutter/material.dart';
import 'package:roomily/data/models/chat_message.dart';

class MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String? currentUserId;
  final bool isLoadingMore;
  final ScrollController scrollController;

  const MessageList({
    Key? key,
    required this.messages,
    this.currentUserId,
    required this.isLoadingMore,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final bool isMe = message.senderId == currentUserId;
            final bool isSystem = message.senderId == null;
            
            if (isSystem) {
              return _buildSystemMessage(message);
            }
            
            return _buildUserMessage(message, isMe);
          },
        ),
        
        if (isLoadingMore)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black12,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    final String messageContent = message.content ?? '';
    Color bgColor = Colors.grey[100]!;
    Color textColor = Colors.black87;
    Color? borderColor = Colors.grey[300];
    IconData? iconData;

    if (messageContent.contains('accepted')) {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      borderColor = const Color(0xFF81C784);
      iconData = Icons.check_circle_outline;
    } else if (messageContent.contains('rejected') || messageContent.contains('canceled')) {
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFD32F2F);
      borderColor = const Color(0xFFEF9A9A);
      iconData = Icons.cancel_outlined;
    } else if (messageContent.contains('pending')) {
      bgColor = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFFF8F00);
      borderColor = const Color(0xFFFFCC80);
      iconData = Icons.hourglass_empty;
    } else if (messageContent.contains('sent')) {
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1976D2);
      borderColor = const Color(0xFF90CAF9);
      iconData = Icons.send;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            if (iconData != null) ...[
              Icon(
                iconData,
                color: textColor,
                size: 28,
              ),
              const SizedBox(height: 10),
            ],
            Text(
              message.displayMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.normal,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage message, bool isMe) {
    final Color messageBubbleColor = isMe
        ? const Color(0xFFE8F0FE)
        : const Color(0xFF1A73E8);
    final Color textColor = isMe ? const Color(0xFF1A73E8) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(message.senderId ?? "U")}&background=random'),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: messageBubbleColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                  bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.displayMessage,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: TextStyle(
                          color: isMe ? const Color(0xFF5F6368) : Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.read == true ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.read == true ? const Color(0xFF4CAF50) : const Color(0xFF5F6368),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(currentUserId ?? "Me")}&background=E8F0FE&color=1A73E8'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Sending...';

    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      if (messageDate == today) {
        return timeString;
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday, $timeString';
      } else {
        return '${dateTime.day}/${dateTime.month}, $timeString';
      }
    } catch (e) {
      return timestamp;
    }
  }
} 