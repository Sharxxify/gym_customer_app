import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Update this with your actual base URL
  final String baseUrl = "http://13.49.224.36:5000/api/v1";
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userGenderKey = 'user_gender';
  static const String _userDateOfBirthKey = 'user_date_of_birth';
  static const String _userProfileImageKey = 'user_profile_image';
  static const String _isNewUserKey = 'is_new_user';

  // Get token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // Save token
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  // Get phone number
  Future<String?> getPhoneNumber() async {
    try {
      return await _secureStorage.read(key: _phoneNumberKey);
    } catch (e) {
      debugPrint('Error getting phone number: $e');
      return null;
    }
  }

  // Save phone number
  Future<void> savePhoneNumber(String phoneNumber) async {
    try {
      await _secureStorage.write(key: _phoneNumberKey, value: phoneNumber);
    } catch (e) {
      debugPrint('Error saving phone number: $e');
    }
  }

  // Get user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  // Save user ID
  Future<void> saveUserId(String userId) async {
    try {
      await _secureStorage.write(key: _userIdKey, value: userId);
    } catch (e) {
      debugPrint('Error saving user ID: $e');
    }
  }

  // Get user name
  Future<String?> getUserName() async {
    try {
      return await _secureStorage.read(key: _userNameKey);
    } catch (e) {
      debugPrint('Error getting user name: $e');
      return null;
    }
  }

  // Save user name
  Future<void> saveUserName(String name) async {
    try {
      await _secureStorage.write(key: _userNameKey, value: name);
    } catch (e) {
      debugPrint('Error saving user name: $e');
    }
  }

  // Get user email
  Future<String?> getUserEmail() async {
    try {
      return await _secureStorage.read(key: _userEmailKey);
    } catch (e) {
      debugPrint('Error getting user email: $e');
      return null;
    }
  }

  // Save user email
  Future<void> saveUserEmail(String email) async {
    try {
      await _secureStorage.write(key: _userEmailKey, value: email);
    } catch (e) {
      debugPrint('Error saving user email: $e');
    }
  }

  // Get user gender
  Future<String?> getUserGender() async {
    try {
      return await _secureStorage.read(key: _userGenderKey);
    } catch (e) {
      debugPrint('Error getting user gender: $e');
      return null;
    }
  }

  // Save user gender
  Future<void> saveUserGender(String gender) async {
    try {
      await _secureStorage.write(key: _userGenderKey, value: gender);
    } catch (e) {
      debugPrint('Error saving user gender: $e');
    }
  }

  // Get user date of birth
  Future<String?> getUserDateOfBirth() async {
    try {
      return await _secureStorage.read(key: _userDateOfBirthKey);
    } catch (e) {
      debugPrint('Error getting user date of birth: $e');
      return null;
    }
  }

  // Save user date of birth
  Future<void> saveUserDateOfBirth(String dateOfBirth) async {
    try {
      await _secureStorage.write(key: _userDateOfBirthKey, value: dateOfBirth);
    } catch (e) {
      debugPrint('Error saving user date of birth: $e');
    }
  }

  // Get user profile image
  Future<String?> getUserProfileImage() async {
    try {
      return await _secureStorage.read(key: _userProfileImageKey);
    } catch (e) {
      debugPrint('Error getting user profile image: $e');
      return null;
    }
  }

  // Save user profile image
  Future<void> saveUserProfileImage(String imageUrl) async {
    try {
      await _secureStorage.write(key: _userProfileImageKey, value: imageUrl);
    } catch (e) {
      debugPrint('Error saving user profile image: $e');
    }
  }

  // Get is_new_user status
  Future<bool?> getIsNewUser() async {
    try {
      final value = await _secureStorage.read(key: _isNewUserKey);
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error getting is_new_user: $e');
      return null;
    }
  }

  // Save is_new_user status
  Future<void> saveIsNewUser(bool isNewUser) async {
    try {
      await _secureStorage.write(key: _isNewUserKey, value: isNewUser.toString());
    } catch (e) {
      debugPrint('Error saving is_new_user: $e');
    }
  }

  // Send OTP to phone number
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final url = Uri.parse("$baseUrl/auth/send-otp");
    debugPrint("✅ Send OTP API Payload: phone_number=$phoneNumber");

    // Save phone number for later use
    await savePhoneNumber(phoneNumber);

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "phone_number": phoneNumber,
          "country_code": "+91"
        }),
      );

      debugPrint("✅ Send OTP API Response: ${response.statusCode}");
      debugPrint("✅ Send OTP API Response Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return result['data'] ?? {"message": result['message']};
      } else {
        // Handle error response
        final error = result['error'];
        if (error != null && error['code'] == 'INVALID_PHONE') {
          throw Exception("Invalid phone number format");
        } else if (error != null && error['code'] == 'RATE_LIMIT_EXCEEDED') {
          throw Exception(result['message'] ?? "Too many OTP requests. Please try again later.");
        } else {
          throw Exception(result['message'] ?? "Failed to send OTP");
        }
      }
    } catch (e) {
      debugPrint("❌ Send OTP API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  String formatPhoneNumber(String phoneNumber) {
    phoneNumber = phoneNumber.trim();

    if (!phoneNumber.startsWith('+91')) {
      return '+91$phoneNumber';
    }
    return phoneNumber;
  }

  // Verify OTP and get JWT token
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp, {String? deviceId, String? fcmToken}) async {
    final url = Uri.parse("$baseUrl/auth/verify-otp");
    debugPrint("✅ Verify OTP API Payload: phone_number=$formatPhoneNumber(phoneNumber), otp=$otp");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "phone_number": formatPhoneNumber(phoneNumber),
          "otp": otp.toString().trim(),
        }),
      );

      debugPrint("✅ Verify OTP API Response: ${response.statusCode}");
      debugPrint("✅ Verify OTP API Response Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        final data = result['data'];

        // Save token and phone number to secure storage
        if (data['token'] != null) {
          await saveToken(data['token']);
          await savePhoneNumber(phoneNumber);

          // Save user data
          final user = data['user'];
          if (user != null) {
            if (user['id'] != null) {
              await saveUserId(user['id']);
            }
            if (user['name'] != null) {
              await saveUserName(user['name']);
            }
            if (user['email'] != null) {
              await saveUserEmail(user['email']);
            }
            if (user['gender'] != null) {
              await saveUserGender(user['gender']);
            }
            if (user['date_of_birth'] != null) {
              await saveUserDateOfBirth(user['date_of_birth']);
            }
            if (user['profile_image'] != null) {
              await saveUserProfileImage(user['profile_image']);
            }
          }

          // Save is_new_user status
          if (data['is_new_user'] != null) {
            await saveIsNewUser(data['is_new_user'] == true);
          }

          // Save refresh token if provided
          if (data['refresh_token'] != null) {
            await _secureStorage.write(key: 'refresh_token', value: data['refresh_token']);
          }
        }

        return data;
      } else {
        // Handle error response
        final error = result['error'];
        if (error != null && error['code'] == 'INVALID_OTP') {
          throw Exception("Invalid OTP. Please try again.");
        } else if (error != null && error['code'] == 'OTP_EXPIRED') {
          throw Exception("OTP has expired. Please request a new OTP.");
        } else {
          throw Exception(result['message'] ?? "OTP verification failed");
        }
      }
    } catch (e) {
      debugPrint("❌ Verify OTP API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  // Logout method
  Future<Map<String, dynamic>> logout(String token, {String? deviceId}) async {
    final url = Uri.parse("$baseUrl/auth/logout");
    debugPrint("✅ Logout API called");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Logout API Response: ${response.statusCode}");
      debugPrint("✅ Logout API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Clear secure storage
        await clearAll();
        final result = jsonDecode(response.body);
        return result;
      } else {
        throw Exception("Logout failed");
      }
    } catch (e) {
      debugPrint("❌ Logout API Error: $e");
      // Clear storage anyway even if API fails
      await clearAll();
      rethrow;
    }
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final url = Uri.parse("$baseUrl/auth/refresh-token");
    debugPrint("✅ Refresh Token API called");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "refresh_token": refreshToken,
        }),
      );

      debugPrint("✅ Refresh Token API Response: ${response.statusCode}");
      debugPrint("✅ Refresh Token API Response Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        final data = result['data'];

        // Save new tokens
        if (data['token'] != null) {
          await saveToken(data['token']);
        }
        if (data['refresh_token'] != null) {
          await _secureStorage.write(key: 'refresh_token', value: data['refresh_token']);
        }

        return data;
      } else {
        throw Exception(result['message'] ?? "Failed to refresh token");
      }
    } catch (e) {
      debugPrint("❌ Refresh Token API Error: $e");
      rethrow;
    }
  }

  // Method to make authenticated requests
  Future<http.Response> makeAuthenticatedRequest(
      String endpoint,
      String token, {
        String method = 'GET',
        Map<String, dynamic>? body,
      }) async {
    final url = Uri.parse("$baseUrl$endpoint");
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      switch (method.toUpperCase()) {
        case 'POST':
          return await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'PUT':
          return await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'DELETE':
          return await http.delete(url, headers: headers);
        default:
          return await http.get(url, headers: headers);
      }
    } catch (e) {
      debugPrint("❌ API Request Error: $e");
      rethrow;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all stored data
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('✅ All secure storage cleared');
    } catch (e) {
      debugPrint('❌ Error clearing storage: $e');
    }
  }

  // Clear session
  Future<void> clearSession() async {
    await clearAll();
  }
}
