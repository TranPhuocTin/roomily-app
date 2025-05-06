import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  final String? id;
  @JsonKey(name: 'message')
  final String? content;
  @JsonKey(name: 'createdAt')
  final String? timestamp;
  @JsonKey(name: 'imageUrl')
  final String? image;
  final bool isAdConversion;
  final String? adClickId;
  final String? chatRoomId;
  final String? senderId;
  final String? metadata;
  final bool? read;
  final int? subId;

  ChatMessage({
    this.id,
    this.content,
    this.timestamp,
    this.image,
    this.isAdConversion = false,
    this.chatRoomId,
    this.adClickId,
    this.senderId,
    this.metadata,
    this.read,
    this.subId,
  });

  // Factory constructor for creating a message to send
  factory ChatMessage.forSending({
    required String content,
    required String senderId,
    required String chatRoomId,
    required bool isAdConversation,
    String? adClickId,
    String? image,
    String? metadata,
  }) {
    return ChatMessage(
      content: content,
      chatRoomId: chatRoomId,
      senderId: senderId,
      isAdConversion: isAdConversation,
      adClickId: adClickId,
      image: image,
      metadata: metadata,
    );
  }

  // Convert from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

  // Convert to JSON
  Map<String, dynamic> toJson() {
    if (id == null) {
      // Case: Sending message (POST)
      return {
        'content': content,
        'senderId': senderId,
        'chatRoomId': chatRoomId,
        if (image != null) 'image': image,
        if(adClickId != null) 'adClickId': adClickId,
        if (metadata != null) 'metadata': metadata,
      };
    } else {
      // Case: Received message (GET)
      return _$ChatMessageToJson(this);
    }
  }

  // Get display message
  String get displayMessage => content ?? '';
}

// @JsonSerializable()
// class UserInfo {
//   final String? id;
//   final String? privateId;
//   final String? username;
//   final String? password;
//   final String? fullName;
//   final String? email;
//   final String? phone;
//   final String? profilePicture;
//   final String? address;
//   final double? rating;
//   final String? status;
//   final bool? isVerified;
//   final double? balance;
//   final List<UserRole>? roles;

//   UserInfo({
//     this.id,
//     this.privateId,
//     this.username,
//     this.password,
//     this.fullName,
//     this.email,
//     this.phone,
//     this.profilePicture,
//     this.address,
//     this.rating,
//     this.status,
//     this.isVerified,
//     this.balance,
//     this.roles,
//   });

//   factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);
//   Map<String, dynamic> toJson() => _$UserInfoToJson(this);
// }

// @JsonSerializable()
// class UserRole {
//   final String? id;
//   final String? name;

//   UserRole({this.id, this.name});

//   factory UserRole.fromJson(Map<String, dynamic> json) => _$UserRoleFromJson(json);
//   Map<String, dynamic> toJson() => _$UserRoleToJson(this);
// } 