import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'time_slot_screen.dart';

class SlotCountScreen extends StatelessWidget {
  final GymModel gym;
  final ServiceModel service;

  const SlotCountScreen({
    super.key,
    required this.gym,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Consumer<BookingProvider>(
            builder: (context, provider, child) {
              final pricePerSlot = service.pricePerSlot;
              final totalPrice = pricePerSlot * provider.slotCount;

              return Container(
                margin: const EdgeInsets.all(AppDimensions.screenPaddingH),
                padding: const EdgeInsets.all(AppDimensions.paddingXXL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryOlive.withOpacity(0.3),
                      AppColors.cardBackground,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    AppSpacing.h16,

                    Text(
                      service.name,
                      style: AppTextStyles.heading3,
                    ),
                    AppSpacing.h32,

                    Text(
                      'Select Number of Slots',
                      style: AppTextStyles.labelLarge,
                    ),
                    AppSpacing.h16,

                    // Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCounterButton(
                          Icons.remove,
                              () => provider.decrementSlots(),
                        ),
                        AppSpacing.w16,
                        Container(
                          width: 60,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              '${provider.slotCount}',
                              style: AppTextStyles.heading4,
                            ),
                          ),
                        ),
                        AppSpacing.w16,
                        _buildCounterButton(
                          Icons.add,
                              () => provider.incrementSlots(),
                        ),
                      ],
                    ),
                    AppSpacing.h24,

                    // Price summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${provider.slotCount} hr',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        AppSpacing.w8,
                        Text(
                          '•',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        AppSpacing.w8,
                        Text(
                          '₹ $totalPrice',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h32,

                    PrimaryButton(
                      text: 'Continue',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimeSlotScreen(
                              gym: gym,
                              service: service,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}