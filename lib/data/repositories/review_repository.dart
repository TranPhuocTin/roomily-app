import '../../core/utils/result.dart';
import '../models/models.dart';
import 'package:roomily/data/models/review.dart';

abstract class ReviewRepository {
  //Get list reviews by room
  Future<Result<List<RoomReview>>> getReviewsByRoom(String roomId);
  //Post review by room
  Future<Result<Review>> postReview(String roomId, Review review);
  //Delete review by reviewId
  Future<Result<bool>> deleteReview(String reviewId);
  //Update review by reviewId
  Future<Result<Review>> updateReview(String reviewId, Review review);

  // Future<List<Review>> getReviewsByRoom(String roomId);
  Future<Review> getReview(String id);
  // Future<Review> createReview(Review review);
  // Future<Review> updateReview(Review review);
  // Future<void> deleteReview(String id);
}