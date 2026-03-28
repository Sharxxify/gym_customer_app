import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/address_model.dart';

class AddressService {
  final String baseUrl = "http://13.49.224.36:5000/api/v1";

  /// Get user addresses
  /// GET /user/addresses
  Future<AddressListResponse> getUserAddresses({
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/user/addresses");

    debugPrint("✅ Get User Addresses API → $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Get Addresses Status: ${response.statusCode}");
      debugPrint("✅ Get Addresses Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return AddressListResponse.fromJson(result);
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        }
        throw Exception(result['message'] ?? "Failed to load addresses");
      }
    } catch (e) {
      debugPrint("❌ Get Addresses API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  /// Add new address
  /// POST /user/addresses
  Future<AddAddressResponse> addAddress({
    required String token,
    required String houseFlat,
    required String roadArea,
    required String streetCity,
    required String label,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async {
    final url = Uri.parse("$baseUrl/user/addresses");

    debugPrint("✅ Add Address API → $url");
    debugPrint("📤 Payload: house_flat: $houseFlat, road_area: $roadArea, street_city: $streetCity, label: $label, is_default: $isDefault");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "house_flat": houseFlat,
          "road_area": roadArea,
          "street_city": streetCity,
          "label": label,
          "latitude": latitude,
          "longitude": longitude,
          "is_default": isDefault,
        }),
      );

      debugPrint("✅ Add Address Status: ${response.statusCode}");
      debugPrint("✅ Add Address Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 201 && result['success'] == true) {
        return AddAddressResponse.fromJson(result);
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        }
        throw Exception(result['message'] ?? "Failed to add address");
      }
    } catch (e) {
      debugPrint("❌ Add Address API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  /// Update address
  /// PUT /user/addresses/{id}
  Future<AddAddressResponse> updateAddress({
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
    final url = Uri.parse("$baseUrl/user/addresses/$addressId");

    debugPrint("✅ Update Address API → $url");

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "house_flat": houseFlat,
          "road_area": roadArea,
          "street_city": streetCity,
          "label": label,
          "latitude": latitude,
          "longitude": longitude,
          "is_default": isDefault,
        }),
      );

      debugPrint("✅ Update Address Status: ${response.statusCode}");
      debugPrint("✅ Update Address Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return AddAddressResponse.fromJson(result);
      } else {
        throw Exception(result['message'] ?? "Failed to update address");
      }
    } catch (e) {
      debugPrint("❌ Update Address API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  /// Delete address
  /// DELETE /user/addresses/{id}
  Future<bool> deleteAddress({
    required String token,
    required String addressId,
  }) async {
    final url = Uri.parse("$baseUrl/user/addresses/$addressId");

    debugPrint("✅ Delete Address API → $url");

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Delete Address Status: ${response.statusCode}");
      debugPrint("✅ Delete Address Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Delete Address API Error: $e");
      return false;
    }
  }
}
