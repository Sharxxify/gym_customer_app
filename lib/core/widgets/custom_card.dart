import 'package:flutter/material.dart';
import '../constants/constants.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.borderRadius,
    this.border,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? AppColors.cardBackground)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.cardRadius,
        ),
        border: border ?? Border.all(color: AppColors.border),
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppDimensions.cardRadius,
          ),
          child: Padding(
            padding: padding ??
                const EdgeInsets.all(AppDimensions.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GymCard extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String location;
  final double distance;
  final double rating;
  final int reviewCount;
  final int price;
  final bool is24x7;
  final bool hasTrainer;
  final VoidCallback? onTap;

  const GymCard({
    super.key,
    this.imageUrl,
    required this.name,
    required this.location,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.is24x7 = false,
    this.hasTrainer = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.cardRadius),
            ),
            child: Container(
              height: 140,
              width: double.infinity,
              color: AppColors.surfaceLight,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.w8,
                    Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.starFilled,
                    ),
                    AppSpacing.w4,
                    Text(
                      '$rating',
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
                ),
                AppSpacing.h4,
                
                // Location and Distance
                Row(
                  children: [
                    Text(
                      location,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      '  •  ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Icon(
                      Icons.directions_walk,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.w4,
                    Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppSpacing.h8,
                
                // Tags
                Row(
                  children: [
                    if (is24x7) _buildTag(Icons.access_time, '24x7'),
                    if (is24x7) AppSpacing.w12,
                    _buildTag(Icons.currency_rupee, '$price'),
                    if (hasTrainer) AppSpacing.w12,
                    if (hasTrainer) _buildTag(Icons.person, 'trainer'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: 40,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        AppSpacing.w4,
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
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
