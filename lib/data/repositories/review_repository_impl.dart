import 'package:dio/dio.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/review.dart';
import 'package:roomily/data/repositories/review_repository.dart';

import '../../core/cache/cache.dart';
import '../../core/constants/api_constants.dart';
import 'package:roomily/data/models/models.dart';

class ReviewRepositoryImpl extends ReviewRepository {
  final Dio _dio;
  final Cache _cache;

  ReviewRepositoryImpl({Dio? dio, Cache? cache})
      : _dio = dio ?? Dio(),
        _cache = cache ?? InMemoryCache();

  @override
  Future<Result<bool>> deleteReview(String reviewId) async {
    try {
      final response = await _dio.delete('${ApiConstants.baseUrl}${ApiConstants.deleteReview(reviewId)}');
      if (response.statusCode == 200) {
        return Success(true);
      }
      return Failure('Failed to delete review');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to delete review');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<List<RoomReview>>> getReviewsByRoom(String roomId) async {
    try {
      // final response = await _dio.get('${ApiConstants.baseUrl}${ApiConstants.reviews(roomId)}');
      // final reviews = (response.data as List).map((e) => RoomReview.fromJson(e)).toList();
      return Success(mockRoomReviews);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get reviews');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<Review>> postReview(String roomId, Review review) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.postReview(roomId)}',
        data: review.toJson(),
      );
      if (response.statusCode == 200) {
        return Success(Review.fromJson(response.data));
      }
      return Failure('Failed to post review');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to post review');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<Review>> updateReview(String reviewId, Review review) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.updateReview(reviewId)}',
        data: review.toJson(),
      );
      if (response.statusCode == 200) {
        return Success(Review.fromJson(response.data));
      }
      return Failure('Failed to update review');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to update review');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Review> createReview(Review review) {
    // TODO: implement createReview
    throw UnimplementedError();
  }

  @override
  Future<Review> getReview(String id) {
    // TODO: implement getReview
    throw UnimplementedError();
  }
}

final mockRoomReviews = [
  RoomReview(
    id: '1',
    content: 'Phòng đẹp, sạch sẽ, rất thoải mái.',
    rating: 4.5,
    roomId: '1',
    userId: '1001',
    userName: 'Nguyễn Văn A',
    profilePicture: 'https://randomuser.me/api/portraits/men/1.jpg',
    createdAt: DateTime.now().subtract(Duration(days: 3)),
    updatedAt: DateTime.now().subtract(Duration(days: 3)),
  ),
  RoomReview(
    id: '2',
    content: 'Chủ nhà thân thiện, vị trí thuận tiện.',
    rating: 5.0,
    roomId: '1',
    userId: '1002',
    userName: 'Trần Thị B',
    profilePicture: 'https://randomuser.me/api/portraits/women/2.jpg',
    createdAt: DateTime.now().subtract(Duration(days: 5)),
    updatedAt: DateTime.now().subtract(Duration(days: 5)),
  ),
  RoomReview(
    id: '3',
    content: 'Giá hơi cao so với tiện ích.',
    rating: 3.5,
    roomId: '1',
    userId: '1003',
    userName: 'Lê Văn C',
    profilePicture: 'https://randomuser.me/api/portraits/men/3.jpg',
    createdAt: DateTime.now().subtract(Duration(days: 7)),
    updatedAt: DateTime.now().subtract(Duration(days: 7)),
  ),
  RoomReview(
    id: '4',
    content: 'Phòng hơi nhỏ nhưng sạch sẽ.',
    rating: 4.0,
    roomId: '1',
    userId: '1004',
    userName: 'Phạm Thị D',
    profilePicture: 'https://randomuser.me/api/portraits/women/4.jpg',
    createdAt: DateTime.now().subtract(Duration(days: 10)),
    updatedAt: DateTime.now().subtract(Duration(days: 10)),
  ),
  RoomReview(
    id: '5',
    content: 'Ổn, không có gì để chê.',
    rating: 4.2,
    roomId: '1',
    userId: '1005',
    userName: 'Đỗ Minh E',
    profilePicture: 'https://randomuser.me/api/portraits/men/5.jpg',
    createdAt: DateTime.now().subtract(Duration(days: 14)),
    updatedAt: DateTime.now().subtract(Duration(days: 14)),
  ),
  RoomReview(
    id: '6',
    content: 'Phòng như mô tả, rất thích!',
    rating: 5.0,
    roomId: '1',
    userId: '1006',
    userName: 'Võ Thị F',
    profilePicture: 'https://randomuser.me/api/portraits/women/6.jpg',
    createdAt: DateTime.now().subtract(Duration(days: 20)),
    updatedAt: DateTime.now().subtract(Duration(days: 20)),
  ),
];