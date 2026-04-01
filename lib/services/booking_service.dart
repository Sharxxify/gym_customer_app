import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';

class BookingService {
  final String baseUrl = "http://13.49.224.36:5000/api/v1";

  /// Get user bookings
  /// GET /bookings?status=all&type=all&page=1&limit=20
  Future<List<BookingModel>> getUserBookings({
    required String token,
    String status = 'all',  // all|confirmed|completed|cancelled
    String type = 'all',    // all|service|membership
    int page = 1,
    int limit = 20,
  }) async {
    final url = Uri.parse("$baseUrl/bookings").replace(
      queryParameters: {
        'status': status,
        'type': type,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    debugPrint("✅ Get User Bookings API → $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Get User Bookings Status: ${response.statusCode}");
      debugPrint("✅ Get User Bookings Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        final data = result['data'];
        if (data == null) {
          throw Exception("No data found in response");
        }

        final List bookingsList = data['bookings'] ?? [];
        return bookingsList.map((b) => BookingModel.fromJson(b)).toList();
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        } else {
          throw Exception(result['message'] ?? "Failed to load bookings");
        }
      }
    } catch (e) {
      debugPrint("❌ Get User Bookings API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  /// Get available time slots for a service
  /// GET /gyms/{gym_id}/services/{service_id}/time-slots?date=2025-12-20
  Future<List<TimeSlotModel>> getTimeSlots({
    required String token,
    required String gymId,
    required String serviceId,
    required String date,  // YYYY-MM-DD format
    required int slotCount,
  }) async {
    final url = Uri.parse("$baseUrl/gyms/$gymId/services/$serviceId/time-slots")
        .replace(queryParameters: {
      'date': date,
      'hours': slotCount.toString(),
    });

    debugPrint("✅ Get Time Slots API → $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Get Time Slots Status: ${response.statusCode}");
      debugPrint("✅ Get Time Slots Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        final data = result['data'];
        if (data == null) {
          throw Exception("No data found in response");
        }

        final slots = data['slots'];
        if (slots == null) {
          throw Exception("No slots found in response");
        }

        // Parse slots from all periods (morning, afternoon, evening)
        List<TimeSlotModel> allSlots = [];

        // Parse morning slots
        if (slots['morning'] != null) {
          final morningSlots = (slots['morning'] as List)
              .map((s) => TimeSlotModel.fromJson(s))
              .toList();
          allSlots.addAll(morningSlots);
        }

        // Parse afternoon slots
        if (slots['afternoon'] != null) {
          final afternoonSlots = (slots['afternoon'] as List)
              .map((s) => TimeSlotModel.fromJson(s))
              .toList();
          allSlots.addAll(afternoonSlots);
        }

        // Parse evening slots
        if (slots['evening'] != null) {
          final eveningSlots = (slots['evening'] as List)
              .map((s) => TimeSlotModel.fromJson(s))
              .toList();
          allSlots.addAll(eveningSlots);
        }

        debugPrint("✅ Loaded ${allSlots.length} time slots");
        return allSlots;
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        } else {
          throw Exception(result['message'] ?? "Failed to load time slots");
        }
      }
    } catch (e) {
      debugPrint("❌ Get Time Slots API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  // Create service booking
  Future<Map<String, dynamic>> createServiceBooking({
    required String token,
    required String gymId,
    required String serviceId,
    required String startTime,  // ISO datetime string
    required int hours,
    required String bookingDate,  // YYYY-MM-DD
    String? timeSlotId,
    String? bookingFor,
    String? serviceLocation,
    String paymentMethod = 'razorpay',
    double? amount,
    double? visitingFee,
    double? tax,
    double? totalAmount,
  }) async {
    final url = Uri.parse("$baseUrl/bookings/service");

    final body = {
      "gym_id": gymId,
      "service_id": serviceId,
      "start_time": startTime,
      "hours": hours,
      "booking_date": bookingDate,
      if (timeSlotId != null) "time_slot_id": timeSlotId,
      if (bookingFor != null) "booking_for": bookingFor,
      if (serviceLocation != null) "service_location": serviceLocation,
      "payment_method": paymentMethod,
      if (amount != null) "amount": amount,
      if (visitingFee != null) "visiting_fee": visitingFee,
      if (tax != null) "tax": tax,
      if (totalAmount != null) "total_amount": totalAmount,
    };

    debugPrint("✅ Create Service Booking API → $url");
    debugPrint("✅ Request Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      debugPrint("✅ Create Booking Status: ${response.statusCode}");
      debugPrint("✅ Create Booking Body: ${response.body}");

      final result = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && result['success'] == true) {
        return result['data'];
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        } else {
          throw Exception(result['message'] ?? "Failed to create booking");
        }
      }
    } catch (e) {
      debugPrint("❌ Create Booking API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  // Get booking details
  Future<Map<String, dynamic>> getBookingDetails({
    required String token,
    required String bookingId,
  }) async {
    final url = Uri.parse("$baseUrl/bookings/$bookingId");

    debugPrint("✅ Get Booking Details API → $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Get Booking Details Status: ${response.statusCode}");
      debugPrint("✅ Get Booking Details Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return result['data']['booking'];
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        } else {
          throw Exception(result['message'] ?? "Failed to fetch booking details");
        }
      }
    } catch (e) {
      debugPrint("❌ Get Booking Details API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  // Verify payment (placeholder - returns true for now)
  Future<bool> verifyPayment({
    required String token,
    required String bookingId,
  }) async {
    debugPrint("✅ Verify Payment for Booking: $bookingId");

    // TODO: Implement actual payment verification API when available
    await Future.delayed(const Duration(seconds: 1));

    debugPrint("✅ Payment Verified Successfully");
    return true;
  }

  // Create single gym membership booking
  Future<Map<String, dynamic>> createMembershipBooking({
    required String token,
    required String gymId,
    String? bookingFor,
    required double amount,
    required String duration,
    String? planId,
  }) async {
    final url = Uri.parse("$baseUrl/bookings/membership");

    final body = {
      "gym_id": gymId,
      if (bookingFor != null) "booking_for": bookingFor,
      "amount": amount,
      "duration": duration,
      "membership_type": duration,
      if (planId != null) "plan_id": planId,
      "payment_method": "razorpay",
    };

    debugPrint("✅ Create Single Gym Membership API → $url");
    debugPrint("✅ Request Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      debugPrint("✅ Create Membership Status: ${response.statusCode}");
      debugPrint("✅ Create Membership Body: ${response.body}");

      final result = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && result['success'] == true) {
        return result['data']; // { membership_id, payment_link_url }
      } else if (response.statusCode == 409 && result['error']?['code'] == 'PENDING_MEMBERSHIP_EXISTS') {
        // Return existing payment data instead of throwing error
        debugPrint("ℹ️ Pending membership exists. Returning data with payment link.");
        return result['error']['details'] ?? {};
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        } else {
          throw Exception(result['message'] ?? "Failed to create membership");
        }
      }
    } catch (e) {
      debugPrint("❌ Create Membership API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  // Create multi-gym membership booking
  Future<Map<String, dynamic>> createMultiGymMembershipBooking({
    required String token,
    String? bookingFor,
    required double amount,
    required String duration,
    String? planId,
  }) async {
    final url = Uri.parse("$baseUrl/bookings/multi-gym-membership");

    final body = {
      if (bookingFor != null) "booking_for": bookingFor,
      "amount": amount,
      "duration": duration,
      if (planId != null) "plan_id": planId,
      "payment_method": "razorpay",
    };

    debugPrint("✅ Create Multi Gym Membership API → $url");
    debugPrint("✅ Request Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      debugPrint("✅ Create Multi Gym Membership Status: ${response.statusCode}");
      debugPrint("✅ Create Multi Gym Membership Body: ${response.body}");

      final result = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && result['success'] == true) {
        return result['data']; // { membership_id, payment_link_url }
      } else if (response.statusCode == 409 && result['error']?['code'] == 'PENDING_MEMBERSHIP_EXISTS') {
        // Return existing payment data instead of throwing error
        debugPrint("ℹ️ Pending multi-gym membership exists. Returning data with payment link.");
        return result['error']['details'] ?? {};
      } else {
        final error = result['error'];
        if (error != null && error['code'] == 'UNAUTHORIZED') {
          throw Exception("Session expired. Please login again.");
        } else {
          throw Exception(result['message'] ?? "Failed to create multi-gym membership");
        }
      }
    } catch (e) {
      debugPrint("❌ Create Multi Gym Membership API Error: $e");
      if (e is Exception) rethrow;
      throw Exception("Network error. Please check your connection.");
    }
  }

  // Verify membership payment
  Future<bool> verifyMembershipPayment({
    required String token,
    required String membershipId,
  }) async {
    final url = Uri.parse("$baseUrl/bookings/membership/$membershipId/verify-payment");

    debugPrint("✅ Verify Membership Payment API → $url");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Verify Payment Status: ${response.statusCode}");
      debugPrint("✅ Verify Payment Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return result['data']['payment_verified'] ?? false;
      } else {
        debugPrint("❌ Payment verification failed");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Verify Payment API Error: $e");
      return false;
    }
  }

  // Get membership details
  Future<Map<String, dynamic>?> getMembershipDetails({
    required String token,
    required String membershipId,
  }) async {
    final url = Uri.parse("$baseUrl/bookings/membership/$membershipId");

    debugPrint("✅ Get Membership Details API → $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Get Membership Details Status: ${response.statusCode}");
      debugPrint("✅ Get Membership Details Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        return result['data']['membership'];
      } else {
        debugPrint("❌ Failed to fetch membership details");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Get Membership Details API Error: $e");
      return null;
    }
  }
}
