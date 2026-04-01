import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService {
  // Update this with your actual base URL
  final String baseUrl = "http://13.49.224.36:5000/api/v1";

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? profileImagePath,  // ✅ Added profile image path
  }) async {
    final url = Uri.parse("$baseUrl/user/profile");

    // Build request body only with non-null fields
    final Map<String, dynamic> requestBody = {};
    if (name != null && name.isNotEmpty) requestBody['name'] = name;
    if (email != null && email.isNotEmpty) requestBody['email'] = email;
    if (gender != null && gender.isNotEmpty) requestBody['gender'] = gender.toLowerCase();
    if (dateOfBirth != null && dateOfBirth.isNotEmpty) requestBody['date_of_birth'] = dateOfBirth;
    if (profileImagePath != null && profileImagePath.isNotEmpty) requestBody['profile_image'] = profileImagePath;

    debugPrint("✅ Update Profile API Payload: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );

      debugPrint("✅ Update Profile API Response: ${response.statusCode}");
      debugPrint("✅ Update Profile API Response Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return result['data'];
      } else {
        // Handle error response
        final error = result['error'];
        if (error != null && error['code'] == 'VALIDATION_ERROR') {
          throw Exception(result['message'] ?? "Invalid profile data");
        } else if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        } else {
          throw Exception(result['message'] ?? "Failed to update profile");
        }
      }
    } catch (e) {
      debugPrint("❌ Update Profile API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  // Get user profile (optional - for future use)
  Future<UserModel> getProfile(String token) async {
    final url = Uri.parse("$baseUrl/user/profile");
    debugPrint("✅ Get Profile API called");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Get Profile API Response: ${response.statusCode}");
      debugPrint("✅ Get Profile API Response Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return UserModel.fromJson(result['data']['user']);
      } else {
        throw Exception(result['message'] ?? "Failed to get profile");
      }
    } catch (e) {
      debugPrint("❌ Get Profile API Error: $e");
      rethrow;
    }
  }
}
