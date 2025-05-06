import 'package:json_annotation/json_annotation.dart';

part 'find_partner_post.g.dart';

@JsonSerializable(explicitToJson: true)
class FindPartnerPost {
  final String findPartnerPostId;
  final int currentPeople;
  final String? description;
  final int maxPeople;
  final String status;
  final String posterId;
  final String roomId;
  final String? rentedRoomId;
  final List<Participant> participants;
  final String? type;
  final String? createdAt;
  final String? updatedAt;

  FindPartnerPost({
    required this.findPartnerPostId,
    required this.currentPeople,
    this.description,
    required this.maxPeople,
    required this.status,
    required this.posterId,
    required this.roomId,
    this.rentedRoomId,
    required this.participants,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory FindPartnerPost.fromJson(Map<String, dynamic> json) => _$FindPartnerPostFromJson(json);
  Map<String, dynamic> toJson() => _$FindPartnerPostToJson(this);
}

@JsonSerializable()
class Participant {
  final String userId;
  final String fullName;
  final String address;
  final String? gender;

  Participant({
    required this.userId,
    required this.fullName,
    required this.address,
    this.gender,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => _$ParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipantToJson(this);
}
