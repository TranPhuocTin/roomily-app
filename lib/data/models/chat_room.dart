import 'package:json_annotation/json_annotation.dart';

part 'chat_room.g.dart';

@JsonSerializable()
class ChatRoom {
  final String chatRoomId;
  final String roomName;
  final String? lastMessage;
  final String? lastMessageTime;
  final String? lastMessageSender;
  final int unreadCount;
  final bool group;

  ChatRoom({
    required this.chatRoomId,
    required this.roomName,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSender,
    required this.unreadCount,
    required this.group,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) => _$ChatRoomFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRoomToJson(this);
} 