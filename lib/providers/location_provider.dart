import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocationProvider extends ChangeNotifier {
  LocationModel? _currentLocation;
  AddressModel? _savedAddress;
  bool _isLoading = false;
  String? _error;
  bool _locationPermissionGranted = false;

  LocationModel? get currentLocation => _currentLocation;
  AddressModel? get savedAddress => _savedAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get locationPermissionGranted => _locationPermissionGranted;
  bool get hasLocation => _currentLocation != null || _savedAddress != null;

  String get displayLocation {
    if (_savedAddress != null) {
      return _savedAddress!.streetCity;
    }
    if (_currentLocation != null) {
      return _currentLocation!.locality ?? _currentLocation!.city ?? 'Unknown';
    }
    return 'Set Location';
  }

  String get displayAddress {
    if (_savedAddress != null) {
      return _savedAddress!.fullAddress;
    }
    if (_currentLocation != null) {
      return _currentLocation!.displayAddress;
    }
    return 'Tap to set your location';
  }

  Future<void> loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('location_lat');
      final lng = prefs.getDouble('location_lng');
      final locality = prefs.getString('location_locality');
      final city = prefs.getString('location_city');
      final address = prefs.getString('location_address');

      if (lat != null && lng != null) {
        _currentLocation = LocationModel(
          latitude: lat,
          longitude: lng,
          locality: locality,
          city: city,
          address: address,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved location: $e');
    }
  }

  Future<bool> checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled';
        _locationPermissionGranted = false;
        notifyListeners();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          _locationPermissionGranted = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied';
        _locationPermissionGranted = false;
        notifyListeners();
        return false;
      }

      _locationPermissionGranted = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _locationPermissionGranted = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> getCurrentLocation() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _updateLocationFromCoordinates(position.latitude, position.longitude);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _updateLocationFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentLocation = LocationModel(
          latitude: lat,
          longitude: lng,
          address: place.street,
          locality: place.subLocality ?? place.locality,
          city: place.locality ?? place.administrativeArea,
          state: place.administrativeArea,
          pincode: place.postalCode,
        );

        await _saveLocation();
      }
    } catch (e) {
      _currentLocation = LocationModel(
        latitude: lat,
        longitude: lng,
      );
    }
    notifyListeners();
  }

  Future<void> setLocationFromCoordinates(double lat, double lng) async {
    _isLoading = true;
    notifyListeners();

    await _updateLocationFromCoordinates(lat, lng);

    _isLoading = false;
    notifyListeners();
  }

  Future<List<LocationModel>> searchLocation(String query) async {
    try {
      if (query.isEmpty) return [];

      List<Location> locations = await locationFromAddress(query);
      List<LocationModel> results = [];

      for (var location in locations.take(5)) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          results.add(LocationModel(
            latitude: location.latitude,
            longitude: location.longitude,
            address: place.street,
            locality: place.subLocality ?? place.locality,
            city: place.locality ?? place.administrativeArea,
            state: place.administrativeArea,
            pincode: place.postalCode,
          ));
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching location: $e');
      return [];
    }
  }

  void setCurrentLocation(LocationModel location) {
    _currentLocation = location;
    _saveLocation();
    notifyListeners();
  }

  void saveAddress(AddressModel address) {
    _savedAddress = address;
    notifyListeners();
  }

  Future<void> _saveLocation() async {
    if (_currentLocation == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('location_lat', _currentLocation!.latitude);
      await prefs.setDouble('location_lng', _currentLocation!.longitude);
      if (_currentLocation!.locality != null) {
        await prefs.setString('location_locality', _currentLocation!.locality!);
      }
      if (_currentLocation!.city != null) {
        await prefs.setString('location_city', _currentLocation!.city!);
      }
      if (_currentLocation!.address != null) {
        await prefs.setString('location_address', _currentLocation!.address!);
      }
    } catch (e) {
      debugPrint('Error saving location: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
