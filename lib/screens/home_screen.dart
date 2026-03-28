import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'gym_detail_screen.dart';
import 'map_view_screen.dart';
import 'filter_screen.dart';
import 'notification_screen.dart';
import 'side_menu_screen.dart';
import 'set_location_screen.dart';
import 'review_screen.dart';

enum ViewMode { list, map }

class HomeScreen extends StatefulWidget {
  final bool showAppBar;

  const HomeScreen({super.key, this.showAppBar = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ViewMode _viewMode = ViewMode.list;
  MapController _mapController = MapController();
  String? _selectedGymId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  // Load all initial data
  Future<void> _loadInitialData() async {
    await _loadNotifications();
    await _loadUserAddresses();
    await _loadBanners();
    await _loadGyms();
  }

  // Refresh all data (for pull-to-refresh)
  Future<void> _refreshData() async {
    await Future.wait([
      _loadNotifications(),
      _loadUserAddresses(),
      _loadBanners(),
      _loadGyms(),
    ]);
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.token != null) {
      await context.read<NotificationProvider>().fetchNotifications(
        token: authProvider.token!,
        refresh: true,
      );
    }
  }

  Future<void> _loadUserAddresses() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.token != null) {
      await context.read<AddressProvider>().loadAddresses(authProvider.token!);
    }
  }

  Future<void> _loadBanners() async {
    await context.read<HomeProvider>().loadBanners();
  }

  Future<void> _loadGyms() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.token != null) {
      // Pass location coords so the server can return nearby gyms.
      // Fall back to Bengaluru if device location is unavailable.
      final locationProvider = context.read<LocationProvider>();
      final loc = locationProvider.currentLocation;
      await context.read<HomeProvider>().loadGyms(
        token: authProvider.token!,
        latitude: loc?.latitude ?? 12.9716,
        longitude: loc?.longitude ?? 77.5946,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final contentColumn = Column(
      children: [
        // App bar (only if showAppBar is true)
        if (widget.showAppBar)
          Consumer<AddressProvider>(
            builder: (context, addressProvider, child) {
              final defaultAddress = addressProvider.defaultAddress;

              return HomeAppBar(
                location: defaultAddress?.roadArea ?? 'Set Location',
                address: defaultAddress?.fullAddress ?? 'Tap to set your location',
                // onLocationTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => const SetLocationScreen(),
                //     ),
                //   );
                // },
                onNotificationTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
                onMenuTap: _openDrawer,
              );
            },
          ),

        // Banner Slider
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: Consumer<HomeProvider>(
            builder: (context, provider, child) {
              return BannerSlider(
                banners: provider.banners,
                height: size.height * 0.22,
              );
            },
          ),
        ),
        AppSpacing.h16,

        // Gym count
        Consumer<HomeProvider>(
          builder: (context, provider, child) {
            final displayText = provider.hasActiveFilters || provider.searchQuery.isNotEmpty
                ? '${provider.gyms.length} of ${provider.totalGyms} Gyms'
                : '${provider.totalGyms} Gyms near you';

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
              ),
              child: Row(
                children: [
                  Text(
                    displayText,
                    style: AppTextStyles.heading4,
                  ),
                  if (provider.hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryGreen,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Filtered',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        AppSpacing.h12,

        // Search and filter row
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH,
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      context.read<HomeProvider>().searchGyms(value);
                    },
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search gym',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.inputBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.inputBorder,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.w8,
              _buildIconButton(
                Icons.tune,
                onTap: () => _showFilterSheet(context),
              ),
              AppSpacing.w8,
              _buildIconButton(
                Icons.sort,
                onTap: () => _showSortSheet(context),
              ),
            ],
          ),
        ),
        AppSpacing.h16,

        // Gym list or Map view
        Expanded(
          child: _viewMode == ViewMode.list
              ? _buildListView()
              : _buildMapView(),
        ),
      ],
    );

    // Return without Scaffold when used in MainScreen
    if (!widget.showAppBar) {
      return contentColumn;
    }

    // Return with Scaffold when standalone
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: const SideMenuScreen(),
      body: SafeArea(child: contentColumn),
    );
  }

  // Build List View
  Widget _buildListView() {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGreen,
            ),
          );
        }

        if (provider.gyms.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primaryGreen,
            backgroundColor: AppColors.cardBackground,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      AppSpacing.h16,
                      Text(
                        'No gyms found',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.h8,
                      Text(
                        'Pull down to refresh',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.primaryGreen,
          backgroundColor: AppColors.cardBackground,
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(
                  left: AppDimensions.screenPaddingH,
                  right: AppDimensions.screenPaddingH,
                  bottom: 80, // Add padding for bottom button
                ),
                itemCount: provider.gyms.length,
                itemBuilder: (context, index) {
                  final gym = provider.gyms[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GymCard(
                      name: gym.name,
                      location: gym.locality,
                      distance: gym.distance,
                      rating: gym.rating,
                      reviewCount: gym.reviewCount,
                      price: gym.pricePerDay,
                      is24x7: gym.is24x7,
                      hasTrainer: gym.hasTrainer,
                      imageUrl: gym.images.isNotEmpty ? gym.images.first : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GymDetailScreen(gymId: gym.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Map View toggle button
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _viewMode = ViewMode.map;
                        _selectedGymId = null;
                        _mapController = MapController(); // Reinitialize controller
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map, color: AppColors.primaryDark, size: 18),
                          AppSpacing.w8,
                          Text(
                            'Map View',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Rate prompt
              Consumer<AttendanceProvider>(
                builder: (context, attendanceProvider, child) {
                  if (!attendanceProvider.showRatePrompt) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    bottom: 70,
                    left: AppDimensions.screenPaddingH,
                    right: AppDimensions.screenPaddingH,
                    child: _buildRatePrompt(
                      context,
                      attendanceProvider.lastVisitedGymId ?? '',
                      attendanceProvider.lastVisitedGymName ?? '',
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Build Map View with OpenStreetMap + CartoDB tiles
  Widget _buildMapView() {
    return Consumer2<HomeProvider, LocationProvider>(
      builder: (context, homeProvider, locationProvider, child) {
        final gyms = homeProvider.gyms;
        final currentLocation = locationProvider.currentLocation;

        if (homeProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGreen,
            ),
          );
        }

        if (gyms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                AppSpacing.h16,
                Text(
                  'No gyms found',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final initialPosition = currentLocation != null
            ? LatLng(currentLocation.latitude, currentLocation.longitude)
            : (gyms.isNotEmpty
            ? LatLng(gyms.first.latitude, gyms.first.longitude)
            : const LatLng(12.9716, 77.5946));

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialPosition,
                initialZoom: 13.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                onTap: (tapPosition, point) {
                  // Deselect gym when tapping on map
                  setState(() => _selectedGymId = null);
                },
              ),
              children: [
                // CartoDB Dark Matter tiles - Same as set_location_screen
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.bookmyfit.customer',
                  maxZoom: 19,
                ),
                // Marker layer for all gyms
                MarkerLayer(
                  markers: gyms.map((gym) {
                    final isSelected = _selectedGymId == gym.id;
                    return Marker(
                      point: LatLng(gym.latitude, gym.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedGymId = gym.id);
                          // Move camera to selected gym
                          _mapController.move(
                            LatLng(gym.latitude, gym.longitude),
                            15.0,
                          );
                        },
                        child: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? AppColors.error
                              : AppColors.primaryGreen,
                          size: isSelected ? 50 : 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // Selected gym card
            if (_selectedGymId != null)
              Positioned(
                bottom: 70,
                left: 16,
                right: 16,
                child: Builder(
                  builder: (context) {
                    final gym = gyms.firstWhere((g) => g.id == _selectedGymId);
                    return GymCard(
                      name: gym.name,
                      location: gym.locality,
                      distance: gym.distance,
                      rating: gym.rating,
                      reviewCount: gym.reviewCount,
                      price: gym.pricePerDay,
                      is24x7: gym.is24x7,
                      hasTrainer: gym.hasTrainer,
                      imageUrl: gym.images.isNotEmpty ? gym.images.first : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GymDetailScreen(gymId: gym.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            // List view toggle button
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _viewMode = ViewMode.list;
                      _selectedGymId = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.list, color: AppColors.primaryDark, size: 18),
                        AppSpacing.w8,
                        Text(
                          'List View',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, {VoidCallback? onTap, Color? backgroundColor, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: backgroundColor != null ? backgroundColor : AppColors.inputBorder),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildRatePrompt(BuildContext context, String gymId, String gymName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Gym image placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gymName,
                  style: AppTextStyles.labelMedium,
                ),
                Text(
                  'How was your experience?',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<AttendanceProvider>().dismissRatePrompt();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewScreen(
                    gymId: gymId,
                    gymName: gymName,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Rate',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FilterSheet(),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SortSheet(),
    );
  }
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Facilities', 'Fee', 'Distance', 'Rating'];
  Set<String> _selectedFacilities = {};

  @override
  void initState() {
    super.initState();
    // Initialize with current filters from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HomeProvider>();
      setState(() {
        _selectedFacilities = Set.from(provider.selectedFacilities);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Column(
        children: [
          AppSpacing.h12,
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppSpacing.h16,
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter', style: AppTextStyles.heading4),
                Consumer<HomeProvider>(
                  builder: (context, provider, _) {
                    if (provider.hasActiveFilters) {
                      return TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedFacilities.clear();
                          });
                          context.read<HomeProvider>().clearFilters();
                        },
                        child: Text(
                          'Clear All',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          AppSpacing.h16,
          Expanded(
            child: Row(
              children: [
                // Tab list
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedTab == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTab = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: isSelected
                                ? const Border(
                              left: BorderSide(
                                color: AppColors.primaryGreen,
                                width: 3,
                              ),
                            )
                                : null,
                          ),
                          child: Text(
                            _tabs[index],
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Content
                Expanded(
                  child: _buildFilterContent(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
            child: PrimaryButton(
              text: _selectedFacilities.isEmpty
                  ? 'Apply Filter'
                  : 'Apply Filter (${_selectedFacilities.length})',
              onPressed: () {
                context.read<HomeProvider>().setFacilities(_selectedFacilities);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent() {
    if (_selectedTab == 0) {
      // Facilities
      final facilities = ['A/C', 'Trainer Support', '24x7', 'Washroom', 'Lorem', 'Lorem'];
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: facilities.length,
        itemBuilder: (context, index) {
          final facility = facilities[index];
          final isSelected = _selectedFacilities.contains(facility);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedFacilities.remove(facility);
                } else {
                  _selectedFacilities.add(facility);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.border,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.primaryDark,
                    )
                        : null,
                  ),
                  AppSpacing.w12,
                  Text(
                    facility,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return const Center(
      child: Text(
        'Coming soon',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class SortSheet extends StatelessWidget {
  const SortSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      'Relevance',
      'Fee: High to low',
      'Fee: Low to high',
      'Rating: High to low',
      'Distance: Low to High',
    ];

    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXL),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...sortOptions.map((option) {
                final isSelected = provider.selectedSort == option;
                return GestureDetector(
                  onTap: () {
                    provider.setSort(option);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              AppSpacing.h16,
            ],
          ),
        );
      },
    );
  }
}