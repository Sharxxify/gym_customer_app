import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';

class AddressProvider extends ChangeNotifier {
  final AddressService _addressService = AddressService();

  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<AddressModel> get addresses => _addresses;
  AddressModel? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  // Get default address or first address
  AddressModel? get defaultAddress {
    try {
      // First try to find default address
      return _addresses.firstWhere((addr) => addr.isDefault);
    } catch (e) {
      // If no default, return first address
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  /// Load user addresses
  Future<void> loadAddresses(String token) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _addressService.getUserAddresses(token: token);

      _addresses = response.addresses;

      // Set selected address to default or first
      if (_selectedAddress == null && _addresses.isNotEmpty) {
        _selectedAddress = defaultAddress;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Load Addresses Error: $e");
    }
  }

  /// Add new address
  Future<bool> addAddress({
    required String token,
    required String houseFlat,
    required String roadArea,
    required String streetCity,
    required String label,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async {
    try {
      _isSaving = true;
      _error = null;
      notifyListeners();

      final response = await _addressService.addAddress(
        token: token,
        houseFlat: houseFlat,
        roadArea: roadArea,
        streetCity: streetCity,
        label: label,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );

      if (response.address != null) {
        // Reload addresses to get updated list
        await loadAddresses(token);
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Add Address Error: $e");
      return false;
    }
  }

  /// Update address
  Future<bool> updateAddress({
    required String token,
    required String addressId,
    required String houseFlat,
    required String roadArea,
    required String streetCity,
    required String label,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async {
    try {
      _isSaving = true;
      _error = null;
      notifyListeners();

      final response = await _addressService.updateAddress(
        token: token,
        addressId: addressId,
        houseFlat: houseFlat,
        roadArea: roadArea,
        streetCity: streetCity,
        label: label,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      );

      if (response.address != null) {
        // Reload addresses
        await loadAddresses(token);
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Delete address
  Future<bool> deleteAddress({
    required String token,
    required String addressId,
  }) async {
    try {
      final success = await _addressService.deleteAddress(
        token: token,
        addressId: addressId,
      );

      if (success) {
        // Reload addresses
        await loadAddresses(token);
      }

      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Set selected address
  void setSelectedAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}