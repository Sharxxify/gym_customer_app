import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final String baseUrl = "http://13.49.224.36:5000/api/v1";

  /// Get attendance calendar for a specific month
  /// GET /attendance/calendar?month=12&year=2025
  Future<AttendanceCalendar> getAttendanceCalendar({
    required String token,
    required int month,  // 1-12
    required int year,
  }) async {
    final url = Uri.parse("$baseUrl/attendance/calendar").replace(
      queryParameters: {
        'month': month.toString(),
        'year': year.toString(),
      },
    );

    debugPrint("✅ Get Attendance Calendar API → $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Get Attendance Calendar Status: ${response.statusCode}");
      debugPrint("✅ Get Attendance Calendar Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return AttendanceCalendar.fromJson(result);
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        } else {
          throw Exception(result['message'] ?? "Failed to load attendance");
        }
      }
    } catch (e) {
      debugPrint("❌ Get Attendance Calendar API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  /// Check-in via QR Code
  /// POST /attendance/check-in
  Future<CheckInResponse> checkIn({
    required String token,
    required String qrCode,
    required String gymId,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse("$baseUrl/attendance/check-in");

    debugPrint("✅ Check-in API → $url");
    debugPrint("✅ Check-in Payload → qr_code: $qrCode, gym_id: $gymId, lat: $latitude, lng: $longitude");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "qr_code": qrCode,
          "gym_id": gymId,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      debugPrint("✅ Check-in Status: ${response.statusCode}");
      debugPrint("✅ Check-in Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return CheckInResponse.fromJson(result);
      } else {
        final error = result['error'];
        if (error != null) {
          if (error['code'] == 'INVALID_QR') {
            throw Exception("Invalid QR code. Please scan a valid gym QR code.");
          } else if (error['code'] == 'ALREADY_CHECKED_IN') {
            throw Exception("You have already checked in today.");
          } else if (error['code'] == 'UNAUTHORIZED') {
            throw Exception("Session expired. Please login again.");
          }
        }
        throw Exception(result['message'] ?? "Check-in failed");
      }
    } catch (e) {
      debugPrint("❌ Check-in API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }
}

/// Check-in response model
class CheckInResponse {
  final bool success;
  final String message;
  final AttendanceData? attendance;

  CheckInResponse({
    required this.success,
    required this.message,
    this.attendance,
  });

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      attendance: json['data']?['attendance'] != null
          ? AttendanceData.fromJson(json['data']['attendance'])
          : null,
    );
  }
}

/// Attendance data from check-in response
class AttendanceData {
  final String id;
  final String gymId;
  final String gymName;
  final String date;
  final String checkInTime;
  final bool isPresent;

  AttendanceData({
    required this.id,
    required this.gymId,
    required this.gymName,
    required this.date,
    required this.checkInTime,
    required this.isPresent,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      id: json['id'] ?? '',
      gymId: json['gym_id'] ?? '',
      gymName: json['gym_name'] ?? '',
      date: json['date'] ?? '',
      checkInTime: json['check_in_time'] ?? '',
      isPresent: json['is_present'] ?? true,
    );
  }
}
