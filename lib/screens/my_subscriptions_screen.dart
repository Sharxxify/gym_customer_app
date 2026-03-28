import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/formatters.dart';
import '../providers/providers.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    // Use Future.microtask to defer the call after the current frame
    Future.microtask(() {
      if (mounted) {
        context.read<SubscriptionProvider>().loadActiveSubscriptions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'My Subscriptions'),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  AppSpacing.h16,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AppSpacing.h16,
                  TextButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadActiveSubscriptions();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.subscriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.diamond_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.h16,
                  const Text(
                    'No active subscriptions',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
            itemCount: provider.subscriptions.length,
            itemBuilder: (context, index) {
              final subscription = provider.subscriptions[index];
              final bool isFirst = index == 0;
              final bool isLast = index == provider.subscriptions.length - 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 1),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isFirst ? AppColors.cardGradient : null,
                  color: !isFirst ? AppColors.cardBackground : null,
                  borderRadius: isFirst
                      ? const BorderRadius.vertical(top: Radius.circular(16))
                      : isLast
                      ? const BorderRadius.vertical(bottom: Radius.circular(16))
                      : null,
                  border: Border.all(color: AppColors.border.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subscription type and status
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    subscription.type == 'membership'
                                        ? Icons.fitness_center
                                        : Icons.diamond,
                                    color: AppColors.primaryGreen,
                                    size: 18,
                                  ),
                                  AppSpacing.w8,
                                  Text(
                                    subscription.type == 'membership'
                                        ? 'Single Gym'
                                        : 'Multi-Gym',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.h4,
                              Text(
                                subscription.durationLabel,
                                style: AppTextStyles.labelLarge,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: subscription.isActive
                                ? AppColors.success.withOpacity(0.2)
                                : AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: subscription.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          child: Text(
                            subscription.isActive ? 'Active' : 'Expired',
                            style: AppTextStyles.caption.copyWith(
                              color: subscription.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Gym name (for single gym subscriptions)
                    if (subscription.gymName != null) ...[
                      AppSpacing.h12,
                      const Divider(color: AppColors.border, height: 1),
                      AppSpacing.h12,
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          AppSpacing.w8,
                          Expanded(
                            child: Text(
                              subscription.gymName!,
                              style: AppTextStyles.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    AppSpacing.h12,
                    const Divider(color: AppColors.border, height: 1),
                    AppSpacing.h12,

                    // Subscription details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailItem(
                          'Start Date',
                          AppFormatters.formatDate(subscription.startDate),
                        ),
                        _buildDetailItem(
                          'End Date',
                          AppFormatters.formatDate(subscription.endDate),
                        ),
                        _buildDetailItem(
                          'Days Left',
                          '${subscription.daysRemaining}',
                          highlight: subscription.daysRemaining <= 7,
                        ),
                      ],
                    ),

                    // Auto-renew status
                    if (subscription.autoRenew) ...[
                      AppSpacing.h12,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.autorenew,
                              size: 16,
                              color: AppColors.primaryGreen,
                            ),
                            AppSpacing.w8,
                            Text(
                              'Auto-renew enabled',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.h4,
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: highlight ? AppColors.warning : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}