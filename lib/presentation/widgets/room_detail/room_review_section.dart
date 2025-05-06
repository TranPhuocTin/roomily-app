import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:roomily/data/models/room_review.dart';

import '../../../data/blocs/home/room_review_cubit.dart';
import '../../../data/blocs/home/room_review_state.dart';

class RoomReviewSection extends StatelessWidget {
  const RoomReviewSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<RoomReviewCubit, RoomReviewState>(
          builder: (context, state) {
            if (state is RoomReviewLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is RoomReviewLoaded) {
              final reviews = state.reviews;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reviews',
                              style: AppTextStyles.heading5,
                            ),
                            if (reviews.length > 3)
                              TextButton(
                                onPressed: () {
                                  // Navigate to all reviews
                                },
                                child: Text(
                                  'See all (${reviews.length})',
                                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (reviews.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildRatingBars(_calculateRatingDistribution(reviews)),
                        ],
                      ],
                    ),
                  ),
                  if (reviews.isNotEmpty)
                    ...List.generate(reviews.take(3).length, (index) {
                      final review = reviews[index];
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildReviewItem(review),
                          ),
                        ],
                      );
                    })
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No reviews yet',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else if (state is RoomReviewError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${state.message}'),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildRatingBars(Map<int, int> ratingDistribution) {
    final totalRatings = ratingDistribution.values.fold(0, (sum, count) => sum + count);
    
    return Column(
      children: [5, 4, 3, 2, 1].map((rating) {
        final count = ratingDistribution[rating] ?? 0;
        final percentage = totalRatings > 0 ? count / totalRatings : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                '$rating',
                style: AppTextStyles.bodyMediumRegular,
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppColors.grey200,
                    color: Colors.amber,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: AppTextStyles.bodySmallRegular.copyWith(
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewItem(RoomReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(review.profilePicture),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: AppTextStyles.bodyMediumSemiBold,
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(review.createdAt),
                    style: AppTextStyles.bodySmallRegular.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toString(),
                    style: AppTextStyles.bodySmallSemiBold.copyWith(
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          review.content,
          style: AppTextStyles.bodyMediumRegular,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDummyReviewItem(
    String name,
    String avatarUrl,
    String comment,
    int rating,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyMediumSemiBold,
                    ),
                    Text(
                      date,
                      style: AppTextStyles.bodySmallRegular.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: AppTextStyles.bodyMediumSemiBold,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: AppTextStyles.bodyMediumRegular,
          ),
        ],
      ),
    );
  }

  String _calculateAverageRating(List<dynamic> reviews) {
    if (reviews.isEmpty) return '0.0 (0)';
    
    double totalRating = 0;
    for (var review in reviews) {
      totalRating += review.rating;
    }
    
    double average = totalRating / reviews.length;
    return '${average.toStringAsFixed(1)} (${reviews.length})';
  }

  Map<int, int> _calculateRatingDistribution(List<dynamic> reviews) {
    final Map<int, int> distribution = {
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };
    
    for (var review in reviews) {
      int rating = review.rating.round();
      distribution.update(rating, (value) => value + 1);
    }
    
    return distribution;
  }
} 