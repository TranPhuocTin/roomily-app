import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/data/models/rental_request.dart';

part 'chat_room_info.g.dart';

enum ChatRoomType {
  DIRECT,
  GROUP,
}

@JsonSerializable()
class ChatRoomInfo {
  final String chatRoomId;
  final String roomName;
  final String? managerId;
  final ChatRoomType chatRoomType;
  final String chatRoomStatus;
  final String? roomId;
  final String? findPartnerPostId;
  RentalRequest? rentalRequest;
  final DateTime createdAt;

  ChatRoomInfo({
    required this.chatRoomId,
    required this.roomName,
    this.managerId,
    required this.chatRoomType,
    required this.chatRoomStatus,
    this.roomId,
    this.findPartnerPostId,
    this.rentalRequest,
    required this.createdAt,
  });

  // Method to update the rental request
  void updateRentalRequest(RentalRequest newRentalRequest) {
    rentalRequest = newRentalRequest;
  }

  factory ChatRoomInfo.fromJson(Map<String, dynamic> json) => _$ChatRoomInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRoomInfoToJson(this);
}