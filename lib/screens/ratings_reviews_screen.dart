import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/formatters.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

class RatingsReviewsScreen extends StatelessWidget {
  final String gymId;
  final String gymName;
  final double rating;
  final int reviewCount;

  const RatingsReviewsScreen({
    super.key,
    required this.gymId,
    required this.gymName,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final reviews = MockData.reviews.where((r) => r.gymId == gymId).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text('Ratings & Reviews', style: AppTextStyles.heading4),
            AppSpacing.w12,
            const Icon(Icons.star, size: 16, color: AppColors.starFilled),
            AppSpacing.w4,
            Text(
              '$rating (${AppFormatters.formatReviewCount(reviewCount)})',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
      body: reviews.isEmpty
          ? const Center(
              child: Text(
                'No reviews yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildReviewCard(review);
              },
            ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceLight,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: AppTextStyles.labelMedium),
                    Row(
                      children: [
                        Text(
                          '${review.rating}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.w4,
                        RatingStars(
                          rating: review.rating,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.h12,

          // Review text
          if (review.description != null && review.description!.isNotEmpty)
            Text(
              review.description!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          AppSpacing.h8,

          // Date
          Text(
            AppFormatters.formatDateWithTime(review.createdAt),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
            ),
          ),
          AppSpacing.h8,

          // Reply button
          Text(
            'Reply',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
