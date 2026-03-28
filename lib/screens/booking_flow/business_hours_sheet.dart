import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';

class BusinessHoursSheet extends StatelessWidget {
  final String gymName;
  final List<BusinessHours> businessHours;
  final VoidCallback onContinue;

  const BusinessHoursSheet({
    super.key,
    required this.gymName,
    required this.businessHours,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final hours = businessHours.isNotEmpty
        ? businessHours
        : _getDefaultHours();

    // FIXED: Calculate max height based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75; // Max 75% of screen height

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryOlive.withOpacity(0.5),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      // FIXED: Wrap in Column with proper structure
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // FIXED: Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    gymName,
                    style: AppTextStyles.heading4,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.h16,

                  // Business hours list
                  ...hours.map((h) => _buildDayRow(h)).toList(),

                  AppSpacing.h16,
                ],
              ),
            ),
          ),

          // FIXED: Button outside scroll view, always visible
          Container(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                text: 'Continue',
                onPressed: onContinue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(BusinessHours hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 50,
            child: Text(
              hours.day,
              style: AppTextStyles.bodyMedium.copyWith(
                color: hours.isOpen
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AppSpacing.w12,

          // Toggle switch
          Container(
            width: 44,
            height: 24,
            decoration: BoxDecoration(
              color: hours.isOpen
                  ? AppColors.primaryGreen
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment:
              hours.isOpen ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: hours.isOpen
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Time boxes
          if (hours.isOpen) ...[
            _buildTimeBox(hours.openTime ?? '6:00'),
            AppSpacing.w8,
            _buildTimeBox(hours.closeTime ?? '22:00'),
          ] else ...[
            Text(
              'Closed',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        time,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<BusinessHours> _getDefaultHours() {
    return [
      BusinessHours(day: 'Mon', isOpen: true, openTime: '06:00', closeTime: '22:00'),
      BusinessHours(day: 'Tue', isOpen: true, openTime: '06:00', closeTime: '22:00'),
      BusinessHours(day: 'Wed', isOpen: true, openTime: '06:00', closeTime: '22:00'),
      BusinessHours(day: 'Thu', isOpen: true, openTime: '06:00', closeTime: '22:00'),
      BusinessHours(day: 'Fri', isOpen: true, openTime: '06:00', closeTime: '22:00'),
      BusinessHours(day: 'Sat', isOpen: true, openTime: '08:00', closeTime: '20:00'),
      BusinessHours(day: 'Sun', isOpen: true, openTime: '09:00', closeTime: '18:00'),
    ];
  }
}