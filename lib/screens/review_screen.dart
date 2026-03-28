import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';

class ReviewScreen extends StatefulWidget {
  final String gymId;
  final String gymName;

  const ReviewScreen({
    super.key,
    required this.gymId,
    required this.gymName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Review'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
        child: Column(
          children: [
            AppSpacing.h32,
            // Review illustration placeholder
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.rate_review,
                  size: 60,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            AppSpacing.h32,

            Text(
              'How was your experience with',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.h8,
            Text(
              '${widget.gymName}?',
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
            AppSpacing.h32,

            // Star rating
            InteractiveRatingStars(
              rating: _rating,
              onRatingChanged: (rating) {
                setState(() => _rating = rating);
              },
              size: 40,
            ),
            AppSpacing.h32,

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 5,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration.collapsed(
                  hintText: 'Description',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
            AppSpacing.h32,

            PrimaryButton(
              text: 'Submit Review',
              isEnabled: _rating > 0,
              onPressed: () {
                // Submit review
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review submitted!')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
