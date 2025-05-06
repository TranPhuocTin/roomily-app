import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/models/recommended_tag.dart';

enum TagStatus { initial, loading, loaded, error }

class TagState extends Equatable {
  final List<RoomTag> tags;
  final List<RecommendedTag> recommendedTags;
  final TagStatus status;
  final String? errorMessage;

  const TagState({
    this.tags = const [],
    this.recommendedTags = const [],
    this.status = TagStatus.initial,
    this.errorMessage,
  });

  TagState copyWith({
    List<RoomTag>? tags,
    List<RecommendedTag>? recommendedTags,
    TagStatus? status,
    String? errorMessage,
  }) {
    return TagState(
      tags: tags ?? this.tags,
      recommendedTags: recommendedTags ?? this.recommendedTags,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [tags, recommendedTags, status, errorMessage];
}