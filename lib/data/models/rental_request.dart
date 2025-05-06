import 'package:json_annotation/json_annotation.dart';

part 'rental_request.g.dart';

enum RentalRequestStatus {
    PENDING,
    APPROVED,
    REJECTED,
    CANCELED
}

@JsonSerializable()
class RentalRequest {
  final String id;
  final String requesterId;
  final String recipientId;
  final String? findPartnerPostId;
  final RentalRequestStatus status;
  final String? roomId;
  final String? chatRoomId;
  final DateTime expiresAt;

  RentalRequest({
    required this.id,
    required this.requesterId,
    required this.recipientId,
    this.findPartnerPostId,
    required this.status,
    this.roomId,
    this.chatRoomId,
    required this.expiresAt,
  });

  factory RentalRequest.fromJson(Map<String, dynamic> json) => _$RentalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RentalRequestToJson(this);
} 