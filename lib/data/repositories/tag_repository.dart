import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/models/recommended_tag.dart';

abstract class TagRepository {
  Future<Result<List<RoomTag>>> getAllTags();
  
  Future<Result<List<RecommendedTag>>> getRecommendedTags({
    required double latitude,
    required double longitude,
  });
}