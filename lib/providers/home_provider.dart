import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../models/user_model.dart';
import '../services/home_service.dart';
import '../services/user_service.dart';

enum ViewMode { list, map }

class HomeProvider extends ChangeNotifier {
  List<GymModel> _gyms = [];
  List<GymModel> _filteredGyms = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.list;

  // Banners
  List<BannerModel> _banners = [];
  bool _isLoadingBanners = false;

  // User profile
  UserModel? _userProfile;
  bool _isLoadingProfile = false;

  // Filters
  Set<String> _selectedFacilities = {};
  String _selectedSort = 'Relevance';
  double? _minFee;
  double? _maxFee;
  double? _maxDistance;
  double? _minRating;

  List<GymModel> get gyms => _filteredGyms.isEmpty &&
      _searchQuery.isEmpty &&
      _selectedFacilities.isEmpty
      ? _gyms
      : _filteredGyms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  ViewMode get viewMode => _viewMode;
  Set<String> get selectedFacilities => _selectedFacilities;
  String get selectedSort => _selectedSort;
  int get totalGyms => _gyms.length;
  int get filteredCount => _filteredGyms.length;
  bool get hasActiveFilters =>
      _selectedFacilities.isNotEmpty ||
          _minFee != null ||
          _maxFee != null ||
          _maxDistance != null ||
          _minRating != null;

  // Banners getters
  List<BannerModel> get banners => _banners;
  bool get isLoadingBanners => _isLoadingBanners;

  // User profile getters
  UserModel? get userProfile => _userProfile;
  bool get isLoadingProfile => _isLoadingProfile;

  // Load user profile from API
  Future<void> loadUserProfile(String token) async {
    try {
      _isLoadingProfile = true;
      notifyListeners();

      _userProfile = await UserService().getProfile(token);

      _isLoadingProfile = false;
      notifyListeners();
    } catch (e) {
      _isLoadingProfile = false;
      debugPrint("❌ Load User Profile Error: $e");
      notifyListeners();
    }
  }

  // Load banners from API
  Future<void> loadBanners() async {
    try {
      _isLoadingBanners = true;
      notifyListeners();

      final service = HomeService();
      _banners = await service.fetchBanners();

      _isLoadingBanners = false;
      notifyListeners();
    } catch (e) {
      _isLoadingBanners = false;
      debugPrint("❌ Load Banners Error: $e");
      notifyListeners();
    }
  }

  Future<void> loadGyms({
    String? token,
    double? latitude,
    double? longitude,
  }) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // If no token provided, throw error
      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final gyms = await HomeService().fetchGyms(
        token: token,  // ✅ Pass token to service
        latitude: latitude,
        longitude: longitude,
      );

      _gyms = gyms;
      _filteredGyms = List.from(_gyms);
      _applyFiltersAndSort();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Load Gyms Error: $e");
    }
  }



  void searchGyms(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void toggleViewMode() {
    _viewMode = _viewMode == ViewMode.list ? ViewMode.map : ViewMode.list;
    notifyListeners();
  }

  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  void toggleFacility(String facility) {
    if (_selectedFacilities.contains(facility)) {
      _selectedFacilities.remove(facility);
    } else {
      _selectedFacilities.add(facility);
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setFacilities(Set<String> facilities) {
    _selectedFacilities = facilities;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSort(String sort) {
    _selectedSort = sort;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setFeeRange(double? min, double? max) {
    _minFee = min;
    _maxFee = max;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setMaxDistance(double? distance) {
    _maxDistance = distance;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setMinRating(double? rating) {
    _minRating = rating;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _selectedFacilities.clear();
    _selectedSort = 'Relevance';
    _minFee = null;
    _maxFee = null;
    _maxDistance = null;
    _minRating = null;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    _filteredGyms = List.from(_gyms);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredGyms = _filteredGyms.where((gym) {
        return gym.name.toLowerCase().contains(query) ||
            gym.locality.toLowerCase().contains(query) ||
            gym.city.toLowerCase().contains(query);
      }).toList();
    }

    // Apply facility filters
    if (_selectedFacilities.isNotEmpty) {
      _filteredGyms = _filteredGyms.where((gym) {
        return _selectedFacilities.every((facility) {
          // Check for 24x7
          if (facility == '24x7') return gym.is24x7;
          // Check other facilities
          return gym.facilities.any((f) =>
          f.name.toLowerCase() == facility.toLowerCase() && f.isAvailable);
        });
      }).toList();
    }

    // Apply fee filter
    if (_minFee != null) {
      _filteredGyms =
          _filteredGyms.where((gym) => gym.pricePerDay >= _minFee!).toList();
    }
    if (_maxFee != null) {
      _filteredGyms =
          _filteredGyms.where((gym) => gym.pricePerDay <= _maxFee!).toList();
    }

    // Apply distance filter
    if (_maxDistance != null) {
      _filteredGyms =
          _filteredGyms.where((gym) => gym.distance <= _maxDistance!).toList();
    }

    // Apply rating filter
    if (_minRating != null) {
      _filteredGyms =
          _filteredGyms.where((gym) => gym.rating >= _minRating!).toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'Fee: High to low':
        _filteredGyms.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
        break;
      case 'Fee: Low to high':
        _filteredGyms.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
        break;
      case 'Rating: High to low':
        _filteredGyms.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Distance: Low to High':
        _filteredGyms.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      default:
      // Relevance - keep original order
        break;
    }
  }


  GymModel? getGymById(String id) {
    try {
      return _gyms.firstWhere((gym) => gym.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}