import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'success_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfirmationScreen extends StatefulWidget {
  final GymModel gym;
  final ServiceModel service;

  const ConfirmationScreen({
    super.key,
    required this.gym,
    required this.service,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> with WidgetsBindingObserver {
  bool _isWaitingForPaymentReturn = false;
  String? _pendingBookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Detect when user returns to app from browser
    if (state == AppLifecycleState.resumed && _isWaitingForPaymentReturn) {
      _handlePaymentReturn();
    }
  }

  Future<void> _handlePaymentReturn() async {
    if (!mounted) return;

    setState(() {
      _isWaitingForPaymentReturn = false;
    });

    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryGreen),
              const SizedBox(height: 24),
              Text(
                'Processing Payment',
                style: AppTextStyles.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we confirm your payment...',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wait 7 seconds
    debugPrint("⏳ Waiting 7 seconds after user returned to app...");
    await Future.delayed(const Duration(seconds: 7));

    if (!mounted) return;

    final provider = context.read<BookingProvider>();

    // Verify payment
    debugPrint("🔍 Verifying payment...");
    final verified = await provider.verifyPayment(_pendingBookingId!);

    if (!mounted) return;

    // Close processing dialog
    Navigator.of(context).pop();

    if (verified) {
      // Fetch booking details
      debugPrint("✅ Payment verified, fetching booking details...");
      await provider.getBookingDetails(_pendingBookingId!);

      if (!mounted) return;

      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SuccessScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verification failed. Please check your bookings.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Booking Confirmation'),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          final selectedDate = provider.selectedDate ?? DateTime.now();
          final selectedSlot = provider.selectedTimeSlot;
          final slotCount = provider.slotCount;

          // Format date
          final dateStr = '${_getDayName(selectedDate.weekday)}, ${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gym Details
                      Text(
                        'Gym Details',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.h8,
                      _buildSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: widget.gym.images.isNotEmpty
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.gym.images.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) {
                                        return const Icon(
                                          Icons.fitness_center,
                                          color: AppColors.textSecondary,
                                        );
                                      },
                                    ),
                                  )
                                      : const Icon(
                                    Icons.fitness_center,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                AppSpacing.w12,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.gym.name,
                                        style: AppTextStyles.labelMedium,
                                      ),
                                      AppSpacing.h4,
                                      Text(
                                        widget.gym.locality,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.h16,

                      // Service Details
                      Text(
                        'Service',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.h8,
                      _buildSection(
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: widget.service.image != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.service.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) {
                                    return const Icon(
                                      Icons.fitness_center,
                                      color: AppColors.textSecondary,
                                      size: 24,
                                    );
                                  },
                                ),
                              )
                                  : const Icon(
                                Icons.fitness_center,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                            ),
                            AppSpacing.w12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.service.name, style: AppTextStyles.labelMedium),
                                  AppSpacing.h4,
                                  Text(
                                    '₹${widget.service.pricePerSlot} per slot',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.h16,

                      // Date & Time
                      Text(
                        'Date & Time',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.h8,
                      _buildSection(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20, color: AppColors.primaryGreen),
                                AppSpacing.w12,
                                Expanded(
                                  child: Text(
                                    dateStr,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            if (selectedSlot != null) ...[
                              AppSpacing.h12,
                              const Divider(color: AppColors.border),
                              AppSpacing.h12,
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 20, color: AppColors.primaryGreen),
                                  AppSpacing.w12,
                                  Expanded(
                                    child: Text(
                                      selectedSlot.label,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            AppSpacing.h12,
                            const Divider(color: AppColors.border),
                            AppSpacing.h12,
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 20, color: AppColors.primaryGreen),
                                AppSpacing.w12,
                                Expanded(
                                  child: Text(
                                    '$slotCount ${slotCount > 1 ? "slots" : "slot"} selected',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.h16,

                      // Booking For
                      Text(
                        'Booking For',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.h8,
                      _buildSection(
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: AppColors.primaryGreen),
                            AppSpacing.w12,
                            Text(
                              context.read<AuthProvider>().user?.name ?? 'User',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.h24,

                      // Payment Breakup
                      Text(
                        'Payment Breakup',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.h8,
                      _buildSection(
                        child: Column(
                          children: [
                            _buildPaymentRow(
                              '${widget.service.name} (x$slotCount)',
                              provider.serviceTotal,
                            ),
                            AppSpacing.h12,
                            _buildPaymentRow('Visiting Fee', provider.visitingFee),
                            AppSpacing.h12,
                            _buildPaymentRow('Tax (18%)', provider.tax),
                            AppSpacing.h12,
                            const Divider(color: AppColors.border),
                            AppSpacing.h12,
                            _buildPaymentRow(
                              'Total Amount',
                              provider.totalAmount,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Confirm button
              Container(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: PrimaryButton(
                    text: 'Confirm & Pay ₹${provider.totalAmount.toInt()}',
                    isLoading: provider.isLoading,
                    onPressed: () async {
                      provider.setBookingFor(
                        context.read<AuthProvider>().user?.name ?? 'Guest',
                      );

                      // Call API
                      final response = await provider.createServiceBooking();

                      if (!context.mounted) return;

                      if (response == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.error ?? 'Failed to create booking'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final booking = response['booking'];
                      final paymentLinkUrl = booking['payment_link_url'];  // Extract from booking object
                      final bookingId = booking['id'];

                      debugPrint("📋 Booking: $booking");
                      debugPrint("📋 Booking ID: $bookingId");
                      debugPrint("📋 Payment Link URL: $paymentLinkUrl");

                      if (paymentLinkUrl == null || paymentLinkUrl.toString().isEmpty) {
                        // Member - no payment needed
                        // Store booking details in provider for SuccessScreen to use
                        await provider.getBookingDetails(bookingId);

                        if (!context.mounted) return;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SuccessScreen(),
                          ),
                        );
                      } else {
                        // Non-member - open payment and wait for return
                        await _handlePaymentFlow(context, bookingId, paymentLinkUrl);
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold ? AppTextStyles.labelMedium : AppTextStyles.bodyMedium,
        ),
        Text(
          '₹${amount.toInt()}',
          style: isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  // Handle payment flow for non-members
  Future<void> _handlePaymentFlow(
      BuildContext context,
      String bookingId,
      String paymentUrl,
      ) async {
    debugPrint("🔗 Payment URL: $paymentUrl");
    debugPrint("📋 Booking ID: $bookingId");

    try {
      // Store booking ID for later verification
      setState(() {
        _pendingBookingId = bookingId;
        _isWaitingForPaymentReturn = true;
      });

      // Open payment URL
      await _openPaymentLink(paymentUrl);

      debugPrint("✅ Payment URL opened, waiting for user to return...");

    } catch (e) {
      debugPrint("❌ Payment URL Error: $e");

      setState(() {
        _isWaitingForPaymentReturn = false;
        _pendingBookingId = null;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open payment: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Open payment URL with proper canLaunchUrl check
  Future<void> _openPaymentLink(String paymentLink) async {
    try {
      final Uri url = Uri.parse(paymentLink);
      debugPrint("🔗 Parsed URI: $url");

      final canLaunch = await canLaunchUrl(url);
      debugPrint("🔗 Can launch URL: $canLaunch");

      if (!canLaunch) {
        debugPrint("⚠️ canLaunchUrl returned false, trying anyway...");
      }

      // Try to launch even if canLaunchUrl returns false (common issue with some URLs)
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      debugPrint("🔗 Launch result: $launched");

      if (!launched) {
        throw Exception('Could not launch payment link');
      }

      debugPrint("✅ Payment URL opened successfully");
    } catch (e) {
      debugPrint("❌ Error opening payment link: ${e.toString()}");
      rethrow;
    }
  }
}