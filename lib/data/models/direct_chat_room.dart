import 'package:json_annotation/json_annotation.dart';

part 'direct_chat_room.g.dart';

@JsonSerializable()
class DirectChatRoom {
  final String id;
  final String? chatKey;
  final String name;
  final String managerId;
  final String? nextSubId;
  final String type;
  final String status;
  final String? lastMessage;
  final DateTime? lastMessageTimeStamp;
  final String? lastMessageSender;
  final String roomId;
  final String? findPartnerPostId;
  final DateTime createdAt;

  DirectChatRoom({
    required this.id,
    this.chatKey,
    required this.name,
    required this.managerId,
    this.nextSubId,
    required this.type,
    required this.status,
    this.lastMessage,
    this.lastMessageTimeStamp,
    this.lastMessageSender,
    required this.roomId,
    this.findPartnerPostId,
    required this.createdAt,
  });

  factory DirectChatRoom.fromJson(Map<String, dynamic> json) {
    return DirectChatRoom(
      id: json['id'],
      chatKey: json['chatKey'],
      name: json['name'],
      managerId: json['managerId'],
      nextSubId: json['nextSubId'],
      type: json['type'],
      status: json['status'],
      lastMessage: json['lastMessage'],
      lastMessageTimeStamp: json['lastMessageTimeStamp'] != null
          ? DateTime.parse(json['lastMessageTimeStamp'])
          : null,
      lastMessageSender: json['lastMessageSender'],
      roomId: json['roomId'],
      findPartnerPostId: json['findPartnerPostId'],
      createdAt: DateTime(
        json['createdAt'][0],
        json['createdAt'][1],
        json['createdAt'][2],
        json['createdAt'][3],
        json['createdAt'][4],
        json['createdAt'][5],
        json['createdAt'][6] ~/ 1000, // Convert microseconds to milliseconds
      ),
    );
  }

  Map<String, dynamic> toJson() => _$DirectChatRoomToJson(this);
} 