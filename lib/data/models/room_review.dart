import 'package:json_annotation/json_annotation.dart';

part 'room_review.g.dart';

@JsonSerializable()
class RoomReview {
  String id;
  String content;
  double rating;
  String roomId;
  String userId;
  String userName;
  String profilePicture;
  DateTime createdAt;
  DateTime updatedAt;

  RoomReview(
      {required this.id,
      required this.content,
      required this.rating,
      required this.roomId,
      required this.userId,
      required this.userName,
      required this.profilePicture,
      required this.createdAt,
      required this.updatedAt});

  factory RoomReview.fromJson(Map<String, dynamic> json) => _$RoomReviewFromJson(json);
  Map<String, dynamic> toJson() => _$RoomReviewToJson(this);
}
