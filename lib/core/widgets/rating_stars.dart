import 'package:flutter/material.dart';
import '../constants/constants.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? filledColor;
  final Color? emptyColor;
  final bool showValue;
  final MainAxisAlignment alignment;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.filledColor,
    this.emptyColor,
    this.showValue = false,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          Color color;

          if (rating >= starValue) {
            icon = Icons.star;
            color = filledColor ?? AppColors.starFilled;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
            color = filledColor ?? AppColors.starFilled;
          } else {
            icon = Icons.star_border;
            color = emptyColor ?? AppColors.starEmpty;
          }

          return Icon(icon, size: size, color: color);
        }),
        if (showValue) ...[
          AppSpacing.w4,
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingStars extends StatelessWidget {
  final int rating;
  final Function(int) onRatingChanged;
  final double size;
  final Color? filledColor;
  final Color? emptyColor;

  const InteractiveRatingStars({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
    this.filledColor,
    this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = rating >= starValue;

        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              size: size,
              color: isFilled
                  ? (filledColor ?? AppColors.starFilled)
                  : (emptyColor ?? AppColors.starEmpty),
            ),
          ),
        );
      }),
    );
  }
}

class RatingBar extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool compact;

  const RatingBar({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: AppColors.starFilled,
          ),
          AppSpacing.w4,
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryGreen,
            ),
          ),
          Text(
            ' (${_formatCount(reviewCount)})',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star,
          size: 18,
          color: AppColors.starFilled,
        ),
        AppSpacing.w4,
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.labelMedium,
        ),
        AppSpacing.w4,
        Text(
          '(${_formatCount(reviewCount)})',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
