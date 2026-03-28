import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../main_screen.dart';

class SuccessScreen extends StatelessWidget {
  final bool isFromBookingsList;

  const SuccessScreen({
    super.key,
    this.isFromBookingsList = false,
  });

  // Calculate time slot label from start_time and hours
  String _calculateTimeSlot(String? startTime, int? hours) {
    if (startTime == null || hours == null) return 'N/A';

    try {
      final start = DateTime.parse(startTime);
      final end = start.add(Duration(hours: hours));

      return '${_formatTime(start)} - ${_formatTime(end)}';
    } catch (e) {
      return 'N/A';
    }
  }

  // Format DateTime to 12-hour format with AM/PM
  String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour = hour - 12;
    } else if (hour == 0) {
      hour = 12;
    }

    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // Convert API response to BookingModel
  BookingModel? _getBookingFromProvider(BuildContext context) {
    final details = context.watch<BookingProvider>().currentBookingDetails;
    if (details == null) return null;

    // Calculate time slot from start_time and hours
    final calculatedTimeSlot = _calculateTimeSlot(
      details['start_time'],
      details['hours'],
    );

    return BookingModel(
      id: details['id'] ?? '',
      gymId: details['gym_id'] ?? '',
      gymName: details['gym_name'] ?? '',
      gymAddress: details['gym_address'] ?? '',
      type: BookingType.service,
      status: details['status'] == 'confirmed'
          ? BookingStatus.confirmed
          : BookingStatus.pending,
      serviceId: details['service_id'] ?? '',
      serviceName: details['service_name'] ?? '',
      slots: details['hours'] ?? details['slots'] ?? 1,
      bookingDate: details['booking_date'] != null
          ? DateTime.parse(details['booking_date'])
          : DateTime.now(),
      timeSlot: calculatedTimeSlot,
      bookingFor: details['booking_for'] ?? '',
      amount: (details['amount'] ?? 0).toDouble(),
      visitingFee: (details['visiting_fee'] ?? 0).toDouble(),
      tax: (details['tax'] ?? 0).toDouble(),
      totalAmount: (details['total_amount'] ?? 0).toDouble(),
      paymentMethod: details['payment_method'],
      paymentStatus: details['payment_status'],
      qrCode: details['qr_code'],
      instructions: details['instructions'] ?? '1. Arrive 5mins early to ensure timely entry\n2. Bring mobile, water bottle and workout shoes',
      createdAt: details['created_at'] != null
          ? DateTime.parse(details['created_at'])
          : DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _getBookingFromProvider(context);

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.error),
              AppSpacing.h16,
              Text(
                'No booking details available',
                style: AppTextStyles.bodyMedium,
              ),
              AppSpacing.h24,
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false,
                  );
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    // Check payment status
    final paymentStatus = booking.paymentStatus?.toLowerCase() ?? '';
    final isPaymentSuccess = paymentStatus == 'completed' || paymentStatus == 'success';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (isFromBookingsList) {
                        // If coming from bookings list, go back to it
                        Navigator.pop(context);
                      } else {
                        // Otherwise go to main screen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                              (route) => false,
                        );
                      }
                    },
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
                AppSpacing.h16,

                // Success/Failed icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isPaymentSuccess ? AppColors.primaryGreen : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPaymentSuccess ? Icons.check : Icons.close,
                    color: isPaymentSuccess ? AppColors.primaryDark : Colors.white,
                    size: 32,
                  ),
                ),
                AppSpacing.h16,
                Text(
                  isPaymentSuccess ? 'Order Confirmed' : 'Payment Failed',
                  style: AppTextStyles.heading3,
                ),
                AppSpacing.h24,

                // Gym info card
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.gymName,
                                  style: AppTextStyles.labelLarge,
                                ),
                                AppSpacing.h4,
                                Text(
                                  booking.gymAddress,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.directions,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.h16,
                      const Divider(color: AppColors.border),
                      AppSpacing.h16,

                      // Service type row
                      _buildInfoRow(
                        Icons.fitness_center,
                        'Service',
                        booking.serviceName ?? 'N/A',
                      ),
                      AppSpacing.h12,

                      // Duration row
                      _buildInfoRow(
                        Icons.schedule,
                        'Duration',
                        '${booking.slots} ${booking.slots == 1 ? 'hour' : 'hours'}',
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,

                // Date and time card
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.primaryGreen, size: 20),
                          AppSpacing.w8,
                          Text(
                            'Schedule',
                            style: AppTextStyles.labelMedium,
                          ),
                        ],
                      ),
                      AppSpacing.h12,
                      const Divider(color: AppColors.border),
                      AppSpacing.h12,
                      _buildInfoRow(
                        Icons.calendar_month,
                        'Date',
                        AppFormatters.formatDate(booking.bookingDate),
                      ),
                      AppSpacing.h12,
                      _buildInfoRow(
                        Icons.access_time,
                        'Time',
                        booking.timeSlot ?? 'N/A',
                      ),
                      AppSpacing.h12,
                      _buildInfoRow(
                        Icons.person_outline,
                        'Booking For',
                        booking.bookingFor,
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,

                // Payment details card
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment, color: AppColors.primaryGreen, size: 20),
                          AppSpacing.w8,
                          Text(
                            'Payment Details',
                            style: AppTextStyles.labelMedium,
                          ),
                        ],
                      ),
                      AppSpacing.h12,
                      const Divider(color: AppColors.border),
                      AppSpacing.h12,
                      _buildPaymentRow('Service Amount', booking.amount),
                      AppSpacing.h8,
                      _buildPaymentRow('Visiting Fee', booking.visitingFee ?? 0),
                      AppSpacing.h8,
                      _buildPaymentRow('Tax', booking.tax ?? 0),
                      AppSpacing.h12,
                      const Divider(color: AppColors.border),
                      AppSpacing.h12,
                      _buildPaymentRow(
                        'Total Paid',
                        booking.totalAmount,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,

                // QR Code card (if available)
                if (booking.qrCode != null && booking.qrCode!.isNotEmpty)
                  _buildCard(
                    child: Column(
                      children: [
                        Text(
                          'Entry QR Code',
                          style: AppTextStyles.labelMedium,
                        ),
                        AppSpacing.h16,
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.network(
                            booking.qrCode!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) {
                              return Container(
                                width: 200,
                                height: 200,
                                color: AppColors.surfaceLight,
                                child: const Icon(
                                  Icons.qr_code_2,
                                  size: 100,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        ),
                        AppSpacing.h16,
                        Text(
                          'Show this QR code at gym entrance',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                if (booking.qrCode != null && booking.qrCode!.isNotEmpty)
                  AppSpacing.h16,

                // Instructions card
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primaryGreen, size: 20),
                          AppSpacing.w8,
                          Text(
                            'Important Instructions',
                            style: AppTextStyles.labelMedium,
                          ),
                        ],
                      ),
                      AppSpacing.h12,
                      Text(
                        booking.instructions ?? '1. Arrive 5mins early to ensure timely entry\n2. Bring mobile, water bottle and workout shoes',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.h32,

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      if (isFromBookingsList) {
                        // If coming from bookings list, go back to it
                        Navigator.pop(context);
                      } else {
                        // Otherwise go to main screen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                              (route) => false,
                        );
                      }
                    },
                    child: Text(isFromBookingsList ? 'Back to Bookings' : 'Back to Home'),
                  ),
                ),
                AppSpacing.h24,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        AppSpacing.w12,
        Expanded(
          child: Column(
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
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTextStyles.labelMedium
              : AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '₹${amount.toInt()}',
          style: isBold
              ? AppTextStyles.labelLarge
              : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}