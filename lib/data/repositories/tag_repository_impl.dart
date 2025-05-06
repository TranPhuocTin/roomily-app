import 'package:dio/dio.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/models/recommended_tag.dart';
import '../../core/constants/api_constants.dart';
import 'tag_repository.dart';

class TagRepositoryImpl extends TagRepository {
  final Dio _dio;

  TagRepositoryImpl()
      : _dio = DioConfig.createDio();

  @override
  Future<Result<List<RoomTag>>> getAllTags() async {
    try {
      final result = await _dio.get(ApiConstants.allTag());

      if (result.statusCode == 200) {
        final roomTags = (result.data as List).map((e) => RoomTag.fromJson(e)).toList();
        return Success(roomTags);
      }

      return const Failure('Failed to get all tags');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get all tags');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

    @override
  Future<Result<List<RecommendedTag>>> getRecommendedTags({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.recommendedTags(),
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      final List<dynamic> tagsJson = response.data as List<dynamic>;
      final List<RecommendedTag> recommendedTags = tagsJson
          .map((tagJson) => RecommendedTag.fromJson(tagJson))
          .toList();
      
      return Success<List<RecommendedTag>>(recommendedTags);
    } catch (e) {
      return Failure<List<RecommendedTag>>(e.toString());
    }
  }
}