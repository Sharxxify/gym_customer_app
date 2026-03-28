import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'add_address_screen.dart';
import 'main_screen.dart';

class SetLocationScreen extends StatefulWidget {
  final bool isInitialSetup;

  const SetLocationScreen({
    super.key,
    this.isInitialSetup = false,
  });

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _selectedPosition = const LatLng(12.9716, 77.5946);
  String? _selectedAddress;
  String? _selectedLocality;
  bool _isSearching = false;
  List<LocationModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    print('🚀 SetLocationScreen initialized');
    print('📍 Initial position: ${_selectedPosition.latitude}, ${_selectedPosition.longitude}');
    _initLocation();
  }

  @override
  void dispose() {
    print('🔚 SetLocationScreen disposed');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    print('🔄 _initLocation() called');
    final locationProvider = context.read<LocationProvider>();
    final hasPermission = await locationProvider.checkLocationPermission();

    print('🔐 Location permission: $hasPermission');

    if (hasPermission) {
      await locationProvider.getCurrentLocation();
      if (locationProvider.currentLocation != null) {
        setState(() {
          _selectedPosition = LatLng(
            locationProvider.currentLocation!.latitude,
            locationProvider.currentLocation!.longitude,
          );
          _selectedAddress = locationProvider.currentLocation!.fullAddress;
          _selectedLocality = locationProvider.currentLocation!.locality;
        });

        print('✅ Initial location set:');
        print('   Lat: ${_selectedPosition.latitude}');
        print('   Lng: ${_selectedPosition.longitude}');
        print('   Address: $_selectedAddress');
        print('   Locality: $_selectedLocality');

        _mapController.move(_selectedPosition, 15.0);
      } else {
        print('❌ Current location is null');
      }
    } else {
      print('❌ Location permission denied');
    }
  }

  Future<void> _getCurrentLocation() async {
    print('📍 _getCurrentLocation() called');
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.getCurrentLocation();

    if (locationProvider.currentLocation != null) {
      setState(() {
        _selectedPosition = LatLng(
          locationProvider.currentLocation!.latitude,
          locationProvider.currentLocation!.longitude,
        );
        _selectedAddress = locationProvider.currentLocation!.fullAddress;
        _selectedLocality = locationProvider.currentLocation!.locality;
      });

      print('✅ Current location updated:');
      print('   Lat: ${_selectedPosition.latitude}');
      print('   Lng: ${_selectedPosition.longitude}');
      print('   Address: $_selectedAddress');
      print('   Locality: $_selectedLocality');

      _mapController.move(_selectedPosition, 15.0);
    } else {
      print('❌ Failed to get current location');
    }
  }

  Future<void> _searchLocation(String query) async {
    print('🔍 _searchLocation() called with query: "$query"');

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      print('   Search cleared');
      return;
    }

    setState(() => _isSearching = true);

    final locationProvider = context.read<LocationProvider>();
    final results = await locationProvider.searchLocation(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });

    print('   Found ${results.length} results');
  }

  void _selectSearchResult(LocationModel location) {
    print('🎯 _selectSearchResult() called');
    print('   Selected: ${location.locality}');
    print('   Lat: ${location.latitude}');
    print('   Lng: ${location.longitude}');
    print('   Address: ${location.fullAddress}');

    setState(() {
      _selectedPosition = LatLng(location.latitude, location.longitude);
      _selectedAddress = location.fullAddress;
      _selectedLocality = location.locality;
      _searchResults = [];
      _searchController.clear();
    });

    print('✅ Selected position updated to: ${_selectedPosition.latitude}, ${_selectedPosition.longitude}');

    _mapController.move(_selectedPosition, 15.0);

    FocusScope.of(context).unfocus();
  }

  void _onMapTap(LatLng position) async {
    print('🗺️  Map tapped at: ${position.latitude}, ${position.longitude}');

    setState(() {
      _selectedPosition = position;
    });

    print('   Position updated in state');

    final locationProvider = context.read<LocationProvider>();
    print('   Fetching address for coordinates...');

    await locationProvider.setLocationFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (locationProvider.currentLocation != null) {
      setState(() {
        _selectedAddress = locationProvider.currentLocation!.fullAddress;
        _selectedLocality = locationProvider.currentLocation!.locality;
      });

      print('✅ Address fetched:');
      print('   Address: $_selectedAddress');
      print('   Locality: $_selectedLocality');
    } else {
      print('❌ Failed to fetch address for tapped location');
    }
  }

  void _confirmLocation() {
    print('🎉 _confirmLocation() called');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📍 FINAL SELECTED LOCATION:');
    print('   Latitude: ${_selectedPosition.latitude}');
    print('   Longitude: ${_selectedPosition.longitude}');
    print('   Address: $_selectedAddress');
    print('   Locality: $_selectedLocality');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final locationProvider = context.read<LocationProvider>();
    locationProvider.setCurrentLocation(LocationModel(
      latitude: _selectedPosition.latitude,
      longitude: _selectedPosition.longitude,
      address: _selectedAddress,
      locality: _selectedLocality,
    ));

    if (widget.isInitialSetup) {
      print('   Navigating to AddAddressScreen (initial setup)');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddAddressScreen(
            latitude: _selectedPosition.latitude,
            longitude: _selectedPosition.longitude,
            locality: _selectedLocality,
          ),
        ),
      );
    } else {
      print('   Popping back with location');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Print current state on every build
    print('🔄 Build called - Current state:');
    print('   Position: ${_selectedPosition.latitude}, ${_selectedPosition.longitude}');
    print('   Address: ${_selectedAddress ?? "Not set"}');
    print('   Locality: ${_selectedLocality ?? "Not set"}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Set Location',
        showBackButton: !widget.isInitialSetup,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
            child: Column(
              children: [
                SearchTextField(
                  hint: 'Search location',
                  controller: _searchController,
                  onChanged: _searchLocation,
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: AppColors.border),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textSecondary,
                          ),
                          title: Text(
                            result.locality ?? result.city ?? 'Unknown',
                            style: AppTextStyles.labelMedium,
                          ),
                          subtitle: Text(
                            result.fullAddress,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Map with CartoDB tiles (Working implementation)
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPosition,
                    initialZoom: 15.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                    onTap: (tapPosition, point) {
                      print('👆 Map tap detected at: ${point.latitude}, ${point.longitude}');
                      _onMapTap(point);
                    },
                  ),
                  children: [
                    // CartoDB Dark Matter tiles - WORKING IMPLEMENTATION
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.bookmyfit.customer',
                      maxZoom: 19,
                    ),
                    // Marker layer
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPosition,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primaryGreen,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Pin instruction
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Place the pin to your location',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),

                // Current location button
                Positioned(
                  bottom: 180,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      print('🔘 Current Location button tapped');
                      _getCurrentLocation();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryGreen),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.w8,
                          Text(
                            'Current Location',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom section
          Container(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXL),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.w12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLocality ?? 'Select Location',
                              style: AppTextStyles.labelLarge,
                            ),
                            if (_selectedAddress != null)
                              Text(
                                _selectedAddress!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h16,
                  PrimaryButton(
                    text: 'Confirm Location',
                    onPressed: _selectedAddress != null ? () {
                      print('🔘 Confirm Location button tapped');
                      _confirmLocation();
                    } : null,
                    isEnabled: _selectedAddress != null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}