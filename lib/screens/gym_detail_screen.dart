import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/home_service.dart';
import 'booking_flow/slot_count_screen.dart';
import 'booking_flow/business_hours_sheet.dart';
import 'ratings_reviews_screen.dart';
import 'subscription_screen.dart';

class GymDetailScreen extends StatefulWidget {
  final String gymId;

  const GymDetailScreen({
    super.key,
    required this.gymId,
  });

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMediaIndex = 0;

  GymModel? _gym;
  bool _isLoading = true;
  String? _error;

  // Membership status for this gym
  MembershipStatusModel? _membershipStatus;
  bool _isMembershipChecking = false;

  // Combined list: images first, then videos
  List<_MediaItem> get _mediaItems {
    if (_gym == null) return [];
    return [
      ..._gym!.images.map((url) => _MediaItem(url: url, isVideo: false)),
      ..._gym!.videos.map((url) => _MediaItem(url: url, isVideo: true)),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGymDetails();
  }

  Future<void> _loadGymDetails() async {
    final auth = context.read<AuthProvider>();

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final gym = await HomeService().getGymDetails(
        token: auth.token ?? '',
        gymId: widget.gymId,
      );

      if (mounted) {
        setState(() {
          _gym = gym;
          _isLoading = false;
        });
        // Fire membership check in background after gym loads
        _checkMembershipStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkMembershipStatus() async {
    if (_gym == null) return;

    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    setState(() => _isMembershipChecking = true);

    try {
      final status = await HomeService().checkMembershipStatus(
        token: auth.token!,
        gymId: _gym!.id,
      );
      if (mounted) {
        setState(() {
          _membershipStatus = status;
          _isMembershipChecking = false;
        });
        debugPrint("✅ Membership status for \${_gym!.name}: isMember=\${status.isMember}, type=\${status.membershipType}");
      }
    } catch (e) {
      // Non-fatal — button stays enabled if check fails
      if (mounted) setState(() => _isMembershipChecking = false);
      debugPrint("⚠️ Membership check failed (non-fatal): $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : _error != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: AppTextStyles.bodyMedium),
              AppSpacing.h16,
              PrimaryButton(
                text: 'Retry',
                onPressed: _loadGymDetails,
              ),
            ],
          ),
        )
            : _gym == null
            ? const Center(child: Text('Gym not found'))
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and header
                    Padding(
                      padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back),
                          ),
                        ],
                      ),
                    ),

                    // Gym name and info
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPaddingH,
                      ),
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
                                      _gym!.name,
                                      style: AppTextStyles.heading3,
                                    ),
                                    AppSpacing.h4,
                                    Text(
                                      _gym!.fullAddress,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              // Directions button
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.directions,
                                  color: AppColors.primaryGreen,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h12,
                          // Open status, distance, rating
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: AppColors.primaryGreen,
                                    ),
                                    AppSpacing.w4,
                                    Text(
                                      _gym!.isOpen ? 'Open' : 'Closed',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    if (_gym!.is24x7) ...[
                                      Text(
                                        ' 24x7',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              AppSpacing.w8,
                              const Text('•', style: TextStyle(color: AppColors.textSecondary)),
                              AppSpacing.w8,
                              Icon(Icons.directions_walk, size: 14, color: AppColors.textSecondary),
                              AppSpacing.w4,
                              Text(
                                '${_gym!.distance.toStringAsFixed(1)} km',
                                style: AppTextStyles.caption,
                              ),
                              AppSpacing.w8,
                              const Text('•', style: TextStyle(color: AppColors.textSecondary)),
                              AppSpacing.w8,
                              Icon(Icons.star, size: 14, color: AppColors.starFilled),
                              AppSpacing.w4,
                              Text(
                                '${_gym!.rating} (${AppFormatters.formatReviewCount(_gym!.reviewCount)})',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h16,

                    // Main media viewer
                    if (_mediaItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.screenPaddingH,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: _mediaItems[_selectedMediaIndex].isVideo
                                ? _GymVideoPlayer(
                              key: ValueKey(_mediaItems[_selectedMediaIndex].url),
                              url: _mediaItems[_selectedMediaIndex].url,
                            )
                                : Image.network(
                              _mediaItems[_selectedMediaIndex].url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surfaceLight,
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 48, color: AppColors.textSecondary),
                                ),
                              ),
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: AppColors.surfaceLight,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primaryGreen,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.screenPaddingH,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 200,
                            color: AppColors.surfaceLight,
                            child: const Center(
                              child: Icon(Icons.fitness_center, size: 60, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    AppSpacing.h12,

                    // Thumbnail strip (only shown when more than 1 media item)
                    if (_mediaItems.length > 1)
                      SizedBox(
                        height: 64,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.screenPaddingH,
                          ),
                          itemCount: _mediaItems.length,
                          itemBuilder: (context, index) {
                            final item = _mediaItems[index];
                            final isSelected = index == _selectedMediaIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedMediaIndex = index),
                              child: Container(
                                width: 64,
                                height: 64,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: isSelected
                                      ? Border.all(color: AppColors.primaryGreen, width: 2)
                                      : Border.all(color: AppColors.border, width: 1),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      item.isVideo
                                          ? Container(color: AppColors.surfaceLight)
                                          : Image.network(
                                        item.url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: AppColors.surfaceLight),
                                      ),
                                      if (item.isVideo)
                                        Center(
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryGreen.withOpacity(0.85),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    AppSpacing.h16,

                    // About Us
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPaddingH,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About Us', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          AppSpacing.h8,
                          Text(
                            _gym!.aboutUs ?? 'No description available.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h16,
                    const Divider(color: AppColors.border),

                    // Facilities
                    if (_gym!.facilities.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.screenPaddingH,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Facilities', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                            AppSpacing.h12,
                            Wrap(
                              spacing: 24,
                              runSpacing: 8,
                              children: _gym!.facilities.map((f) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check, size: 16, color: AppColors.primaryGreen),
                                    AppSpacing.w4,
                                    Text(f.name, style: AppTextStyles.bodySmall),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.border),
                    ],

                    // Tab bar
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.screenPaddingH,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border.withOpacity(0.3)),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primaryGreen,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primaryGreen,
                        indicatorWeight: 2,
                        tabs: const [
                          Tab(text: 'Services'),
                          Tab(text: 'Reviews'),
                          Tab(text: 'Equipments'),
                        ],
                      ),
                    ),

                    // Tab content
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildServicesTab(),
                          _buildReviewsTab(),
                          _buildEquipmentsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Consumer<SubscriptionProvider>(
                  builder: (context, subProvider, _) {
                    final hasMultiGym = subProvider.hasActiveMultiGymMembership;
                    final activeMultiSub = subProvider.activeMultiGymSubscription;

                    // isMember = gym-specific membership OR an active multi-gym membership
                    final isMember =
                        _membershipStatus?.isMember == true || hasMultiGym;

                    // Decide badge label
                    String badgeText = '';
                    if (_membershipStatus?.isMember == true) {
                      badgeText =
                      '${_membershipStatus!.membershipTypeLabel} Membership Active'
                          '${_membershipStatus!.endDate != null ? ' · Expires ${_membershipStatus!.endDate}' : ""}';
                    } else if (hasMultiGym && activeMultiSub != null) {
                      badgeText =
                      'Multi-Gym Membership Active · ${activeMultiSub.daysRemaining} days remaining';
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Active membership badge
                        if (isMember) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.primaryGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    badgeText,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        PrimaryButton(
                          text: isMember
                              ? 'Already Subscribed'
                              : 'Book Gym Membership',
                          isLoading: _isMembershipChecking,
                          isEnabled: !isMember,
                          onPressed: isMember
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SubscriptionScreen(gym: _gym!),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    if (_gym!.services.isEmpty) {
      return const Center(
        child: Text('No services available', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
      itemCount: _gym!.services.length,
      itemBuilder: (context, index) {
        final service = _gym!.services[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Service image placeholder
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sports_gymnastics, color: AppColors.textSecondary),
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: AppTextStyles.labelMedium),
                    Text(
                      '${service.schedule ?? 'Every day'}\n${service.timing ?? ''}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.read<BookingProvider>().initializeBooking(_gym!);
                  context.read<BookingProvider>().selectService(service);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SlotCountScreen(
                        gym: _gym!,
                        service: service,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Book Slot >',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RatingsReviewsScreen(
              gymId: _gym!.id,
              gymName: _gym!.name,
              rating: _gym!.rating,
              reviewCount: _gym!.reviewCount,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ratings & Reviews', style: AppTextStyles.labelMedium),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: AppColors.starFilled),
                    AppSpacing.w4,
                    Text(
                      '${_gym!.rating} (${AppFormatters.formatReviewCount(_gym!.reviewCount)})',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGreen),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.h16,
            Expanded(
              child: Center(
                child: Text(
                  'Tap to see all reviews',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentsTab() {
    if (_gym!.equipments.isEmpty) {
      return const Center(
        child: Text('No equipment information', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _gym!.equipments.length,
      itemBuilder: (context, index) {
        final equipment = _gym!.equipments[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fitness_center, color: AppColors.textSecondary),
              ),
              AppSpacing.h8,
              Text(
                equipment.name,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBusinessHoursSheet() {
    // Block navigation to subscription if user has a gym-specific OR multi-gym membership
    final hasMultiGym =
        context.read<SubscriptionProvider>().hasActiveMultiGymMembership;
    final isMember = _membershipStatus?.isMember == true || hasMultiGym;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BusinessHoursSheet(
        gymName: _gym!.name,
        businessHours: _gym!.businessHours,
        onContinue: isMember
            ? () => Navigator.pop(context) // just close sheet — already subscribed
            : () {
          Navigator.pop(context); // Close bottom sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubscriptionScreen(gym: _gym!),
            ),
          );
        },
      ),
    );
  }
}

// Simple data class representing one media item (image or video)
class _MediaItem {
  final String url;
  final bool isVideo;
  const _MediaItem({required this.url, required this.isVideo});
}

// Inline video player widget — manages VideoPlayerController lifecycle
class _GymVideoPlayer extends StatefulWidget {
  final String url;
  const _GymVideoPlayer({super.key, required this.url});

  @override
  State<_GymVideoPlayer> createState() => _GymVideoPlayerState();
}

class _GymVideoPlayerState extends State<_GymVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _controller.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('❌ Video player init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: Icon(Icons.videocam_off, size: 48, color: AppColors.textSecondary),
        ),
      );
    }
    if (!_isInitialized) {
      return Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 2),
        ),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        // Video fills the container maintaining aspect ratio
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        // Play/Pause button overlay
        GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}