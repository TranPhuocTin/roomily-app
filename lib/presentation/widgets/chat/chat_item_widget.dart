import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/data/blocs/user/user_cubit.dart';
import 'package:roomily/data/blocs/user/user_state.dart';

class ChatItemWidget extends StatefulWidget {
  final String name;
  final String message;
  final bool isOnline;
  final String avatar;
  final String? lastMessageTime;
  final int unreadCount;
  final String? lastMessageSender;
  final bool isGroup;
  final String? chatRoomId;

  const ChatItemWidget({
    Key? key,
    required this.name,
    required this.message,
    required this.isOnline,
    required this.avatar,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.lastMessageSender,
    this.isGroup = false,
    this.chatRoomId,
  }) : super(key: key);

  @override
  State<ChatItemWidget> createState() => _ChatItemWidgetState();
}

class _ChatItemWidgetState extends State<ChatItemWidget> {
  String? _senderName;
  bool _isLoadingSender = false;

  @override
  void initState() {
    super.initState();
    _fetchSenderName();
  }

  @override
  void didUpdateWidget(ChatItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastMessageSender != widget.lastMessageSender) {
      _fetchSenderName();
    }
  }

  // Tìm nạp tên người gửi từ ID
  Future<void> _fetchSenderName() async {
    if (widget.lastMessageSender == null || widget.lastMessageSender!.isEmpty) {
      return;
    }
    
    try {
      setState(() => _isLoadingSender = true);
      
      // Lấy UserCubit từ GetIt
      if (GetIt.instance.isRegistered<UserCubit>()) {
        final userCubit = GetIt.instance<UserCubit>();
        await userCubit.getUserInfoById(widget.lastMessageSender!);
        
        if (userCubit.state is UserInfoByIdLoaded) {
          final user = (userCubit.state as UserInfoByIdLoaded).user;
          setState(() => _senderName = user.fullName);
        }
      }
    } catch (e) {
      debugPrint('Error fetching sender name: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSender = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = formatMessageTime(widget.lastMessageTime);
    
    final bool isCurrentUser = widget.lastMessageSender == 'currentUser';
    
    final primaryColor = Theme.of(context).primaryColor;
    
    // Xử lý tin nhắn preview với tên người gửi hợp lý
    String messagePreview = '';
    if (isCurrentUser) {
      messagePreview = 'Bạn: ${widget.message}';
    } else if (widget.lastMessageSender != null && widget.isGroup) {
      // Sử dụng tên người gửi đã được tìm nạp thay vì ID
      String senderDisplay = _senderName ?? 'Unknown';
      if (_isLoadingSender) senderDisplay = '...';
      
      messagePreview = '$senderDisplay: ${widget.message}';
    } else {
      messagePreview = widget.message;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'avatar_${widget.chatRoomId ?? DateTime.now().millisecondsSinceEpoch.toString()}_${widget.avatar.isEmpty ? widget.name : widget.avatar}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.avatar.isEmpty
                          ? Color.lerp(primaryColor, Colors.grey[300], 0.6)
                          : null,
                      gradient: widget.avatar.isEmpty
                          ? LinearGradient(
                              colors: [
                                primaryColor.withOpacity(0.8),
                                Color.lerp(primaryColor, Colors.blue, 0.5) ?? primaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: widget.avatar.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(widget.avatar),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: widget.avatar.isEmpty
                        ? Center(
                            child: Text(
                              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.isGroup)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.group,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: widget.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                            color: Colors.grey[850],
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.unreadCount > 0 ? primaryColor : Colors.grey[500],
                          fontWeight: widget.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          messagePreview,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            color: widget.unreadCount > 0 ? Colors.grey[800] : Colors.grey[600],
                            fontWeight: widget.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      if (widget.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatMessageTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return '';
    }

    try {
      final DateTime messageTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(messageTime);

      if (difference.inDays == 0) {
        final dateFormat = DateFormat.jm();
        return dateFormat.format(messageTime);
      } else if (difference.inDays == 1) {
        return 'Hôm qua';
      } else if (difference.inDays < 7) {
        final dateFormat = DateFormat.E();
        return dateFormat.format(messageTime);
      } else {
        final dateFormat = DateFormat.MMMd();
        return dateFormat.format(messageTime);
      }
    } catch (e) {
      return timestamp;
    }
  }
}
