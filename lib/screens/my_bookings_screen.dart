import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/formatters.dart';
import '../providers/providers.dart';
import 'booking_flow/success_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BookingProvider>().loadBookings();
  }

  Future<void> _viewBookingDetails(String bookingId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );

    try {
      final provider = context.read<BookingProvider>();
      final details = await provider.getBookingDetails(bookingId);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (details != null) {
        // Navigate to success screen with booking details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SuccessScreen(isFromBookingsList: true),
          ),
        );
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to load booking details'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'My Bookings'),
      body: Consumer<BookingProvider>(
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
                  Text(
                    provider.error!,
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.h16,
                  TextButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadBookings();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.bookings.isEmpty) {
            return const Center(
              child: Text(
                'No bookings yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
            itemCount: provider.bookings.length,
            itemBuilder: (context, index) {
              final booking = provider.bookings[index];
              return GestureDetector(
                onTap: () => _viewBookingDetails(booking.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: index == 0
                        ? AppColors.cardGradient
                        : null,
                    color: index != 0 ? AppColors.cardBackground : null,
                    borderRadius: index == 0
                        ? const BorderRadius.vertical(top: Radius.circular(16))
                        : index == provider.bookings.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(16))
                        : null,
                    border: Border.all(color: AppColors.border.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.serviceName ?? booking.membershipType ?? 'Booking',
                              style: AppTextStyles.labelMedium,
                            ),
                            AppSpacing.h4,
                            Text(
                              AppFormatters.formatDateWithTime(booking.bookingDate),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹ ${booking.totalAmount.toInt()}',
                            style: AppTextStyles.labelLarge,
                          ),
                          AppSpacing.h4,
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}