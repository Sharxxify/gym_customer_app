import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/formatters.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'set_location_screen.dart';
import 'notification_screen.dart';
import 'side_menu_screen.dart';
import 'subscription_success_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final GymModel? gym;
  final bool showAppBar;

  const SubscriptionScreen({super.key, this.gym, this.showAppBar = true});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String _selectedType;
  int _selectedPlanIndex = 0;

  // Payment flow state
  bool _isWaitingForPaymentReturn = false;
  String? _pendingMembershipId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedType = widget.gym != null ? 'single_gym' : 'multi_gym';

    // Fetch multi-gym pricing and active subscriptions as early as possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchMultiGymPricing();
      context.read<SubscriptionProvider>().loadActiveSubscriptions();
    });
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

    // Fetch booking details to check payment status
    debugPrint("🔍 Fetching booking details...");
    final bookingDetails = await provider.getBookingDetails(_pendingMembershipId!);

    if (!mounted) return;

    // Close processing dialog
    Navigator.of(context).pop();

    if (bookingDetails != null) {
      // Check payment status
      final paymentStatus = bookingDetails['payment_status']?.toString().toLowerCase() ?? '';
      final isPaymentCompleted = paymentStatus == 'completed';

      debugPrint("✅ Payment Status: $paymentStatus");

      // Navigate to success screen with payment status
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionSuccessScreen(
            membershipId: _pendingMembershipId!,
            subscriptionType: _selectedType,
            gymName: widget.gym?.name,
            isPaymentCompleted: isPaymentCompleted,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch booking details. Please check your memberships.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handlePaymentFlow(
      BuildContext context,
      String membershipId,
      String paymentUrl,
      ) async {
    debugPrint("🔗 Payment URL: $paymentUrl");
    debugPrint("📋 Membership ID: $membershipId");

    try {
      // Store membership ID for later verification
      setState(() {
        _pendingMembershipId = membershipId;
        _isWaitingForPaymentReturn = true;
      });

      // Open payment URL
      await _openPaymentLink(paymentUrl);

      debugPrint("✅ Payment URL opened, waiting for user to return...");

    } catch (e) {
      debugPrint("❌ Payment URL Error: $e");

      setState(() {
        _isWaitingForPaymentReturn = false;
        _pendingMembershipId = null;
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

  Future<void> _openPaymentLink(String paymentLink) async {
    try {
      final Uri url = Uri.parse(paymentLink);
      debugPrint("🔗 Parsed URI: $url");

      final canLaunch = await canLaunchUrl(url);
      debugPrint("🔗 Can launch URL: $canLaunch");

      if (!canLaunch) {
        debugPrint("⚠️ canLaunchUrl returned false, trying anyway...");
      }

      // Try to launch even if canLaunchUrl returns false
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: const SideMenuScreen(),
      body: SafeArea(
        child: Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            // Get plans
            final subscriptionProvider = context.watch<SubscriptionProvider>();
            List<SubscriptionModel> plans;

            if (_selectedType == 'single_gym' && widget.gym != null) {
              plans = widget.gym!.membershipFees
                  .map((fee) => fee.toSubscriptionModel(
                gymId: widget.gym!.id,
                gymName: widget.gym!.name,
              ))
                  .toList();
            } else if (_selectedType == 'single_gym' && widget.gym == null) {
              plans = [];
            } else {
              // multi_gym — sourced from API via SubscriptionProvider
              plans = subscriptionProvider.multiGymPlans;
            }

            // Show loading spinner while multi-gym pricing is being fetched
            if (_selectedType == 'multi_gym' &&
                subscriptionProvider.isPricingLoading) {
              return Column(
                children: [
                  _buildAppBar(context),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              );
            }

            // Show error + retry for multi-gym pricing fetch failure
            if (_selectedType == 'multi_gym' &&
                subscriptionProvider.pricingError != null &&
                plans.isEmpty) {
              return Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_outlined,
                                color: AppColors.textSecondary, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              subscriptionProvider.pricingError!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () =>
                                  subscriptionProvider.fetchMultiGymPricing(
                                      forceRefresh: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Empty state
            if (plans.isEmpty) {
              return Column(
                children: [
                  widget.gym != null
                      ? const CustomAppBar(
                    title: 'Subscription Plans',
                    showBackButton: true,
                  )
                      : Consumer<LocationProvider>(
                    builder: (context, locationProvider, child) {
                      return HomeAppBar(
                        location: locationProvider.displayLocation,
                        address: locationProvider.displayAddress,
                        onLocationTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SetLocationScreen(),
                            ),
                          );
                        },
                        onNotificationTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                        },
                        onMenuTap: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                      );
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'No subscription plans available',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Ensure selected index is valid
            if (_selectedPlanIndex >= plans.length) {
              _selectedPlanIndex = plans.length > 2 ? 2 : 0;
            }

            final selectedPlan = plans[_selectedPlanIndex];

            return Column(
              children: [
                // App bar (conditional based on showAppBar and gym)
                if (widget.showAppBar)
                  widget.gym != null
                      ? CustomAppBar(
                    title: 'Subscription Plans',
                    showBackButton: true,
                    actions: [
                      Consumer<NotificationProvider>(
                        builder: (context, notifProvider, _) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  const Center(
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.textPrimary,
                                      size: 20,
                                    ),
                                  ),
                                  if (notifProvider.unreadCount > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            notifProvider.unreadCount > 9
                                                ? '9+'
                                                : notifProvider.unreadCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                      : Consumer<LocationProvider>(
                    builder: (context, locationProvider, child) {
                      return HomeAppBar(
                        location: locationProvider.displayLocation,
                        address: locationProvider.displayAddress,
                        onLocationTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SetLocationScreen(),
                            ),
                          );
                        },
                        onNotificationTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationScreen(),
                            ),
                          );
                        },
                        onMenuTap: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                      );
                    },
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Hero - PNG ONLY (subscribe.png)
                        Container(
                          height: screenHeight * 0.25,
                          width: double.infinity,
                          margin: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/subscribe.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.01),

                        // Type selection
                        Text(
                          'Select Subscription Type',
                          style: AppTextStyles.heading4.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTypeCard(
                                  title: 'Single Gym',
                                  subtitle: 'Access only to',
                                  detail: widget.gym?.name ?? 'Selected Gym',
                                  isSelected: _selectedType == 'single_gym',
                                  onTap: widget.gym != null
                                      ? () {
                                    setState(() {
                                      _selectedType = 'single_gym';
                                      _selectedPlanIndex = 0;
                                    });
                                  }
                                      : null,
                                  showRecommended: false,
                                  screenWidth: screenWidth,
                                  isDisabled: widget.gym == null,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: _buildTypeCard(
                                  title: 'Multi Gym',
                                  subtitle: 'Access to all',
                                  detail: '112 Pro Gyms',
                                  isSelected: _selectedType == 'multi_gym',
                                  onTap: () {
                                    setState(() {
                                      _selectedType = 'multi_gym';
                                      _selectedPlanIndex = 0;
                                    });
                                  },
                                  showRecommended: true,
                                  screenWidth: screenWidth,
                                  isDisabled: false,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Duration selection
                        Text(
                          'Select Duration',
                          style: AppTextStyles.heading4.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Duration cards
                        Container(
                          height: screenHeight * 0.13,
                          margin: EdgeInsets.only(left: screenWidth * 0.04),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: plans.length,
                            itemBuilder: (context, index) {
                              final plan = plans[index];
                              final isSelected = _selectedPlanIndex == index;

                              return Padding(
                                padding: EdgeInsets.only(right: screenWidth * 0.025),
                                child: GestureDetector(
                                  onTap: () {
                                    debugPrint('🔵 Tapped plan $index: ${plan.durationLabel}');
                                    setState(() {
                                      _selectedPlanIndex = index;
                                    });
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    width: screenWidth * 0.22,
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenWidth * 0.025,
                                      horizontal: screenWidth * 0.02,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primaryGreen.withOpacity(0.1)
                                          : AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryGreen : AppColors.border,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: AppColors.primaryGreen,
                                            size: screenWidth * 0.05,
                                          )
                                        else
                                          SizedBox(height: screenWidth * 0.05),
                                        SizedBox(height: screenWidth * 0.01),
                                        Text(
                                          plan.durationLabel,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: screenWidth * 0.008),
                                        Text(
                                          '₹ ${plan.price}',
                                          style: TextStyle(
                                            color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (plan.originalPrice != null) ...[
                                          SizedBox(height: screenWidth * 0.005),
                                          Text(
                                            '${plan.originalPrice}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),

                // Bottom summary
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: const Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Consumer<SubscriptionProvider>(
                      builder: (context, subProvider, _) {
                        // Check if multi-gym is already active
                        final isMultiGymActive = _selectedType == 'multi_gym' &&
                            subProvider.hasActiveMultiGymMembership;
                        final activeMultiSub = subProvider.activeMultiGymSubscription;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Active multi-gym banner ──────────────────
                            if (isMultiGymActive && activeMultiSub != null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primaryGreen.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.primaryGreen,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Multi-Gym Membership Active',
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Valid until ${AppFormatters.formatDate(activeMultiSub.endDate)} · ${activeMultiSub.daysRemaining} days remaining',
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.primaryGreen.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // ── Plan summary row ─────────────────────────
                            if (!isMultiGymActive) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _selectedType == 'multi_gym'
                                          ? 'Multi Gym'
                                          : widget.gym?.name ?? 'Single Gym',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: Text('•', style: TextStyle(fontSize: 16)),
                                  ),
                                  Text(
                                    selectedPlan.durationLabel,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                    child: Text('•', style: TextStyle(fontSize: 16)),
                                  ),
                                  Text(
                                    '₹${selectedPlan.price}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.015),
                            ],

                            // ── Subscribe / Already Active button ────────
                            PrimaryButton(
                              text: isMultiGymActive
                                  ? 'Already Subscribed'
                                  : 'Subscribe',
                              isLoading: bookingProvider.isLoading,
                              isEnabled: !isMultiGymActive,
                              onPressed: isMultiGymActive
                                  ? null
                                  : () async {
                                debugPrint('🔵 ========== SUBSCRIBE BUTTON PRESSED ==========');
                                debugPrint('🔵 Selected plan from UI: ${selectedPlan.durationLabel} - ₹${selectedPlan.price}');
                                debugPrint('🔵 Subscription type: $_selectedType');

                                final authProvider = context.read<AuthProvider>();
                                final userName = authProvider.user?.name ?? 'Guest';

                                debugPrint('🔵 Booking for: $userName');

                                bookingProvider.setBookingFor(userName);
                                bookingProvider.setSubscriptionType(_selectedType);
                                bookingProvider.selectPlan(selectedPlan);

                                debugPrint('🔵 Provider plan after setting: ${bookingProvider.selectedPlan?.durationLabel}');
                                debugPrint('🔵 Provider type after setting: ${bookingProvider.subscriptionType}');

                                debugPrint('🔵 Calling createMembershipBooking...');
                                final response = await bookingProvider.createMembershipBooking(
                                  gymId: _selectedType == 'single_gym' ? widget.gym?.id : null,
                                );

                                if (!context.mounted) return;

                                if (response == null) {
                                  debugPrint('❌ Response is null');
                                  debugPrint('❌ Error: ${bookingProvider.error}');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(bookingProvider.error ?? 'Failed to create membership'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                final booking = response['booking'];
                                final paymentLinkUrl = booking?['payment_link_url'];
                                final membershipId = booking?['id'];

                                debugPrint('✅ Response received: $response');
                                debugPrint('✅ Booking object: $booking');
                                debugPrint('✅ Payment URL: $paymentLinkUrl');
                                debugPrint('✅ Membership ID: $membershipId');

                                if (paymentLinkUrl != null && membershipId != null) {
                                  await _handlePaymentFlow(context, membershipId, paymentLinkUrl);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid payment response'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                            ),

                            if (!isMultiGymActive) ...[
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Next renewal: ${_getNextRenewalDate(selectedPlan.duration)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Shared app-bar widget used by loading and error states.
  Widget _buildAppBar(BuildContext context) {
    if (widget.gym != null) {
      return const CustomAppBar(
        title: 'Subscription Plans',
        showBackButton: true,
      );
    }
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return HomeAppBar(
          location: locationProvider.displayLocation,
          address: locationProvider.displayAddress,
          onLocationTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SetLocationScreen()),
          ),
          onNotificationTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          ),
          onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
        );
      },
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String subtitle,
    required String detail,
    required bool isSelected,
    required VoidCallback? onTap,
    required bool showRecommended,
    required double screenWidth,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenWidth * 0.045,
              ),
              decoration: BoxDecoration(
                gradient: isSelected && !isDisabled
                    ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryOlive.withOpacity(0.4),
                    AppColors.primaryGreen.withOpacity(0.15),
                  ],
                )
                    : null,
                color: isSelected && !isDisabled ? null : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected && !isDisabled ? AppColors.primaryGreen : AppColors.border,
                  width: isSelected && !isDisabled ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primaryGreen,
                      size: screenWidth * 0.065,
                    )
                  else
                    Container(
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  SizedBox(height: screenWidth * 0.025),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.035),
                  Container(
                    height: 1,
                    color: AppColors.border.withOpacity(0.5),
                  ),
                  SizedBox(height: screenWidth * 0.025),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showRecommended)
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getNextRenewalDate(String duration) {
    final now = DateTime.now();
    DateTime renewalDate;

    // Handle both old and new formats
    switch (duration.toLowerCase()) {
      case 'daily':
      case '1_day':
        renewalDate = now.add(const Duration(days: 1));
        break;
      case 'weekly':
      case '1_week':
        renewalDate = now.add(const Duration(days: 7));
        break;
      case 'monthly':
      case '1_month':
        renewalDate = DateTime(now.year, now.month + 1, now.day);
        break;
      case 'quarterly':
      case '3_months':
        renewalDate = DateTime(now.year, now.month + 3, now.day);
        break;
      case 'half_yearly':
      case '6_months':
        renewalDate = DateTime(now.year, now.month + 6, now.day);
        break;
      case 'yearly':
      case '1_year':
        renewalDate = DateTime(now.year + 1, now.month, now.day);
        break;
      default:
        renewalDate = now.add(const Duration(days: 30));
    }

    return AppFormatters.formatDate(renewalDate);
  }
}