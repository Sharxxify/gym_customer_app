import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _error;
  String? _phoneNumber;
  String? _otpId;
  bool? _isNewUser;
  String? _refreshToken;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get error => _error;
  String? get phoneNumber => _phoneNumber;
  bool? get isNewUser => _isNewUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _token != null;

  // Load token and user data from storage on app start
  Future<void> checkAuthStatus() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      _token = await _authService.getToken();
      final userId = await _authService.getUserId();
      _phoneNumber = await _authService.getPhoneNumber();
      final name = await _authService.getUserName();
      final email = await _authService.getUserEmail();
      final gender = await _authService.getUserGender();
      final dateOfBirth = await _authService.getUserDateOfBirth();
      final profileImage = await _authService.getUserProfileImage();
      _refreshToken = await _storage.read(key: 'refresh_token');

      // Load is_new_user
      _isNewUser = await _authService.getIsNewUser();

      if (_token != null && userId != null) {
        _user = UserModel(
          id: userId,
          phoneNumber: _phoneNumber ?? '',
          name: name,
          email: email,
          gender: gender,
          dateOfBirth: dateOfBirth,
          profileImage: profileImage,
        );
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
      debugPrint("❌ Check Auth Status Error: $e");
    }
    notifyListeners();
  }

  // Get phone number from storage
  Future<String?> getPhoneNumber() async {
    return await _authService.getPhoneNumber();
  }

  // Send OTP to phone number
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final result = await _authService.sendOtp(phoneNumber);
      _otpId = result['otp_id']?.toString();

      _phoneNumber = phoneNumber;
      _status = AuthStatus.unauthenticated;
      notifyListeners();

      debugPrint("✅ OTP sent successfully: ${result['message']}");
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Send OTP Error: $e");
      return false;
    }
  }

  // Verify OTP and save token
  Future<Map<String, dynamic>?> verifyOtp(String otp, {String? deviceId, String? fcmToken}) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      if (_phoneNumber == null) {
        throw Exception("Phone number not found. Please request OTP again.");
      }

      final result = await _authService.verifyOtp(
        _phoneNumber!,
        otp,
        deviceId: deviceId,
        fcmToken: fcmToken,
      );

      _token = result["token"];
      _refreshToken = result["refresh_token"];

      // Extract is_new_user from response
      if (result.containsKey("is_new_user")) {
        _isNewUser = result["is_new_user"] == true;
      }

      if (_token == null) {
        throw Exception("Token not found in response");
      }

      // Extract user data from response
      final userData = result["user"];
      if (userData != null) {
        _user = UserModel(
          id: userData['id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
          phoneNumber: userData['phone_number'] ?? _phoneNumber ?? '',
          name: userData['name'],
          email: userData['email'],
          gender: userData['gender'],
          dateOfBirth: userData['date_of_birth'],
          profileImage: userData['profile_image'],
        );
      } else {
        _user = UserModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          phoneNumber: _phoneNumber ?? '',
        );
      }

      _status = AuthStatus.authenticated;
      _otpId = null;
      notifyListeners();

      debugPrint("✅ OTP verified successfully");
      return result;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Verify OTP Error: $e");
      return null;
    }
  }

  // Update is_new_user status (useful after completing onboarding)
  Future<void> updateIsNewUser(bool isNewUser) async {
    _isNewUser = isNewUser;
    await _authService.saveIsNewUser(isNewUser);
    notifyListeners();
  }

  // Mark user as no longer new (completed onboarding)
  Future<void> completeOnboarding() async {
    await updateIsNewUser(false);
  }

  /// Load fresh user profile from API
  /// Returns true if successful, false otherwise
  Future<bool> loadUserProfile() async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      if (_token == null) {
        throw Exception("No authentication token found. Please login again.");
      }

      // Fetch profile from API
      final fetchedUser = await _userService.getProfile(_token!);

      // Update local user and save to secure storage
      _user = fetchedUser;

      // Update secure storage with fresh data
      if (fetchedUser.id != null) {
        await _authService.saveUserId(fetchedUser.id!);
      }
      if (fetchedUser.name != null) {
        await _authService.saveUserName(fetchedUser.name!);
      }
      if (fetchedUser.email != null) {
        await _authService.saveUserEmail(fetchedUser.email!);
      }
      if (fetchedUser.gender != null) {
        await _authService.saveUserGender(fetchedUser.gender!);
      }
      if (fetchedUser.dateOfBirth != null) {
        await _authService.saveUserDateOfBirth(fetchedUser.dateOfBirth!);
      }
      if (fetchedUser.profileImage != null) {
        await _authService.saveUserProfileImage(fetchedUser.profileImage!);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      debugPrint("✅ User profile loaded from API successfully");
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Load User Profile Error: $e");
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? profileImagePath, // ✅ Changed from profileImage to profileImagePath
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      if (_token == null) {
        throw Exception("No authentication token found. Please login again.");
      }

      // Call the API to update profile
      final result = await _userService.updateProfile(
        token: _token!,
        name: name,
        email: email,
        gender: gender,
        dateOfBirth: dateOfBirth,
        profileImagePath: profileImagePath, // ✅ Pass profile image path to API
      );

      // Extract updated user data from response
      final updatedUser = result['user'];
      if (updatedUser != null) {
        _user = UserModel.fromJson(updatedUser);

        // Save to secure storage
        if (updatedUser['name'] != null) {
          await _authService.saveUserName(updatedUser['name']);
        }
        if (updatedUser['email'] != null) {
          await _authService.saveUserEmail(updatedUser['email']);
        }
        if (updatedUser['gender'] != null) {
          await _authService.saveUserGender(updatedUser['gender']);
        }
        if (updatedUser['date_of_birth'] != null) {
          await _authService.saveUserDateOfBirth(updatedUser['date_of_birth']);
        }
        if (updatedUser['profile_image'] != null) {
          await _authService.saveUserProfileImage(updatedUser['profile_image']);
        }
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      debugPrint("✅ Profile updated successfully");
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Update Profile Error: $e");
      return false;
    }
  }

  // Refresh authentication token
  Future<bool> refreshAuthToken() async {
    try {
      if (_refreshToken == null) {
        throw Exception("No refresh token available");
      }

      final result = await _authService.refreshToken(_refreshToken!);

      _token = result['token'];
      _refreshToken = result['refresh_token'];

      notifyListeners();
      debugPrint("✅ Token refreshed successfully");
      return true;
    } catch (e) {
      debugPrint("❌ Refresh Token Error: $e");
      // If refresh fails, logout user
      await logout();
      return false;
    }
  }

  // Logout
  Future<void> logout({String? deviceId}) async {
    if (_token != null) {
      try {
        await _authService.logout(_token!, deviceId: deviceId);
        debugPrint("✅ Logout API success");
      } catch (e) {
        debugPrint("❌ Logout API error: $e");
      }
    }

    _user = null;
    _token = null;
    _phoneNumber = null;
    _isNewUser = null;
    _error = null;
    _refreshToken = null;
    _status = AuthStatus.unauthenticated;

    // Clear all secure storage
    await _authService.clearAll();

    notifyListeners();
    debugPrint("✅ Logged out successfully");
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setNewUserFlag(bool value) {
    _isNewUser = value;
    _authService.saveIsNewUser(value);
    notifyListeners();
  }
}