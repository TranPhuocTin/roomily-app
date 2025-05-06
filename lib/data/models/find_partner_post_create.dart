import 'package:json_annotation/json_annotation.dart';

part 'find_partner_post_create.g.dart';

enum FindPartnerPostType {
  NEW_RENTAL,
  ADDITIONAL_TENANT,
}

@JsonSerializable(explicitToJson: true)
class FindPartnerPostCreate {
  final String? description;
  final int maxPeople;
  final String roomId;
  final List<String>? currentParticipantPrivateIds;
  final FindPartnerPostType type;
  final String? rentedRoomId;

  FindPartnerPostCreate({
    this.description,
    required this.maxPeople,
    required this.roomId,
    this.currentParticipantPrivateIds,
    required this.type,
    this.rentedRoomId,
  });

  factory FindPartnerPostCreate.fromJson(Map<String, dynamic> json) => _$FindPartnerPostCreateFromJson(json);
  Map<String, dynamic> toJson() => _$FindPartnerPostCreateToJson(this);

  /// Factory method to create a FindPartnerPostCreate instance with logic for type assignment.
  factory FindPartnerPostCreate.create({
    String? description,
    required int maxPeople,
    required String roomId,
    List<String>? currentParticipantPrivateIds,
    String? rentedRoomId,
  }) {
    return FindPartnerPostCreate(
      description: description,
      maxPeople: maxPeople,
      roomId: roomId,
      currentParticipantPrivateIds: currentParticipantPrivateIds ?? [],
      rentedRoomId: rentedRoomId,
      type: rentedRoomId == null ? FindPartnerPostType.NEW_RENTAL : FindPartnerPostType.ADDITIONAL_TENANT,
    );
  }
}