import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';

class NotificationService {
  final String baseUrl = "http://13.49.224.36:5000/api/v1";

  Future<NotificationResponse> getNotifications({
    required String token,
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'unread_only': unreadOnly.toString(),
    };

    final uri = Uri.parse("$baseUrl/notifications")
        .replace(queryParameters: queryParams);

    debugPrint("✅ Get Notifications API → $uri");

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Get Notifications Status: ${response.statusCode}");
      debugPrint("✅ Get Notifications Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return NotificationResponse.fromJson(result);
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        }
        throw Exception(result['message'] ?? "Failed to load notifications");
      }
    } catch (e) {
      debugPrint("❌ Get Notifications API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  Future<bool> markAsRead({
    required String token,
    required String notificationId,
  }) async {
    final uri = Uri.parse("$baseUrl/notifications/$notificationId/read");

    debugPrint("✅ Mark Notification as Read API → $uri");

    try {
      final response = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Mark as Read Status: ${response.statusCode}");
      debugPrint("✅ Mark as Read Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Mark as Read Error: $e");
      return false;
    }
  }

  Future<bool> markAllAsRead({required String token}) async {
    final uri = Uri.parse("$baseUrl/notifications/mark-all-read");

    debugPrint("✅ Mark All as Read API → $uri");

    try {
      final response = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Mark All as Read Status: ${response.statusCode}");
      debugPrint("✅ Mark All as Read Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Mark All as Read Error: $e");
      return false;
    }
  }

  Future<bool> deleteNotification({
    required String token,
    required String notificationId,
  }) async {
    final uri = Uri.parse("$baseUrl/notifications/$notificationId");

    debugPrint("✅ Delete Notification API → $uri");

    try {
      final response = await http.delete(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Delete Notification Status: ${response.statusCode}");
      debugPrint("✅ Delete Notification Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Delete Notification Error: $e");
      return false;
    }
  }
}
