// Map View Screen
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/providers.dart';
import 'gym_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapController;
  String? _selectedGymId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<HomeProvider, LocationProvider>(
        builder: (context, homeProvider, locationProvider, child) {
          final gyms = homeProvider.gyms;
          final currentLocation = locationProvider.currentLocation;

          final initialPosition = currentLocation != null
              ? LatLng(currentLocation.latitude, currentLocation.longitude)
              : const LatLng(12.9716, 77.5946);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialPosition,
                  zoom: 13,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: gyms.map((gym) {
                  return Marker(
                    markerId: MarkerId(gym.id),
                    position: LatLng(gym.latitude, gym.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                    onTap: () {
                      setState(() => _selectedGymId = gym.id);
                    },
                  );
                }).toSet(),
              ),

              // Top bar
              SafeArea(
                child: Column(
                  children: [
                    HomeAppBar(
                      location: locationProvider.displayLocation,
                      address: locationProvider.displayAddress,
                      onLocationTap: () {},
                      onNotificationTap: () {},
                      onMenuTap: () {},
                    ),
                  ],
                ),
              ),

              // Selected gym card
              if (_selectedGymId != null)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
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

              // List view toggle
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(24),
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
      ),
    );
  }
}