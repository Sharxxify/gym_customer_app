import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/providers.dart';
import 'success_screen.dart';

class PaymentProgressScreen extends StatefulWidget {
  final String bookingId;
  final String paymentUrl;

  const PaymentProgressScreen({
    super.key,
    required this.bookingId,
    required this.paymentUrl,
  });

  @override
  State<PaymentProgressScreen> createState() => _PaymentProgressScreenState();
}

class _PaymentProgressScreenState extends State<PaymentProgressScreen> {
  bool _isVerifying = false;
  bool _paymentUrlOpened = false;

  @override
  void initState() {
    super.initState();
    _openPaymentUrl();
  }

  Future<void> _openPaymentUrl() async {
    try {
      final uri = Uri.parse(widget.paymentUrl);
      final canOpen = await canLaunchUrl(uri);

      if (canOpen) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        setState(() => _paymentUrlOpened = true);

        // Wait 7 seconds then verify payment
        await Future.delayed(const Duration(seconds: 7));

        if (mounted) {
          await _verifyPayment();
        }
      } else {
        throw Exception("Cannot open payment URL");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening payment: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _verifyPayment() async {
    setState(() => _isVerifying = true);

    try {
      final provider = context.read<BookingProvider>();

      // Directly fetch booking details without verify step
      final bookingDetails = await provider.getBookingDetails(widget.bookingId);

      if (!mounted) return;

      if (bookingDetails != null) {
        // Navigate to success screen (will check payment_status there)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SuccessScreen(),
          ),
        );
      } else {
        _showError("Failed to fetch details");
      }
    } catch (e) {
      if (mounted) {
        _showError("Error fetching booking: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _verifyPayment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation during verification
        if (_isVerifying) return false;

        // Show confirmation dialog
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text('Cancel Payment?'),
            content: const Text(
              'Are you sure you want to cancel the payment? Your booking will not be confirmed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No, Continue'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
        );

        return shouldPop ?? false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const CustomAppBar(title: 'Payment'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Payment icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payment,
                    size: 60,
                    color: AppColors.primaryGreen,
                  ),
                ),
                AppSpacing.h32,

                // Status text
                Text(
                  _isVerifying
                      ? 'Verifying Payment...'
                      : _paymentUrlOpened
                      ? 'Complete Payment in Browser'
                      : 'Opening Payment Gateway...',
                  style: AppTextStyles.heading3,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.h16,

                Text(
                  _isVerifying
                      ? 'Please wait while we verify your payment'
                      : _paymentUrlOpened
                      ? 'Complete your payment in the browser window.\nReturn to the app once done.'
                      : 'Redirecting to payment gateway...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.h32,

                // Loading indicator
                if (_isVerifying || !_paymentUrlOpened)
                  const CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),

                AppSpacing.h32,

                // Manual verify button (shown after payment URL opened)
                if (_paymentUrlOpened && !_isVerifying)
                  PrimaryButton(
                    text: 'I Completed Payment',
                    onPressed: _verifyPayment,
                  ),

                AppSpacing.h16,

                // Booking ID for reference
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      AppSpacing.w8,
                      Flexible(
                        child: Text(
                          'Booking ID: ${widget.bookingId}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}