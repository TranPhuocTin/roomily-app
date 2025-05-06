import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'review.g.dart';

@JsonSerializable()
class Review extends Equatable {
  final String id;
  final String content;
  final int rating;
  final String roomId;
  final String userId;
  final String userName;
  @JsonKey(name: 'profilePicture')
  final String profilePicture;
  final String createdAt;
  final String updatedAt;

  const Review({
    required this.id,
    required this.content,
    required this.rating,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        content,
        rating,
        roomId,
        userId,
        userName,
        profilePicture,
        createdAt,
        updatedAt,
      ];

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);
}