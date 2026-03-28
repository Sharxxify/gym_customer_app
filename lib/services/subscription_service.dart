import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class SubscriptionService {
  final String baseUrl = "http://13.49.224.36:5000/api/v1";

  // ─── Active Subscriptions ────────────────────────────────────────────────

  Future<List<ActiveSubscriptionModel>> getActiveSubscriptions({
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/subscriptions/active");

    debugPrint("✅ Get Active Subscriptions API called");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Get Active Subscriptions Response: ${response.statusCode}");
      debugPrint("✅ Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] != null) {
          final subscriptionsData =
          result['data']['subscriptions'] as List<dynamic>;

          return subscriptionsData
              .map((sub) => ActiveSubscriptionModel.fromJson(sub))
              .toList();
        } else {
          throw Exception(
              result['message'] ?? "Failed to fetch subscriptions");
        }
      } else {
        final result = jsonDecode(response.body);
        throw Exception(result['message'] ?? "Failed to fetch subscriptions");
      }
    } catch (e) {
      debugPrint("❌ Get Active Subscriptions Error: $e");
      rethrow;
    }
  }

  // ─── Multi-Gym Pricing ───────────────────────────────────────────────────

  /// GET /memberships/multi-gym-pricing
  /// Returns a list of [MultiGymPricingModel] for all 4 duration tiers.
  Future<List<MultiGymPricingModel>> fetchMultiGymPricing({
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/memberships/multi-gym-pricing");

    debugPrint("✅ Fetch Multi-Gym Pricing API → $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("✅ Multi-Gym Pricing Status: ${response.statusCode}");
      debugPrint("✅ Multi-Gym Pricing Body: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['success'] == true && result['data'] != null) {
          final pricingList = result['data']['pricing'] as List<dynamic>;

          return pricingList
              .map((item) =>
              MultiGymPricingModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(
              result['message'] ?? "Failed to fetch multi-gym pricing");
        }
      } else {
        final result = jsonDecode(response.body);
        throw Exception(
            result['message'] ?? "Failed to fetch multi-gym pricing");
      }
    } catch (e) {
      debugPrint("❌ Fetch Multi-Gym Pricing Error: $e");
      rethrow;
    }
  }
}

// ─── Active Subscription Model ───────────────────────────────────────────────

class ActiveSubscriptionModel {
  final String id;
  final String planId;
  final String type; // single_gym or multi_gym
  final String duration;
  final String durationLabel;
  final String? gymId;
  final String? gymName;
  final String? gymAddress;
  final String? gymImage;
  final DateTime startDate;
  final DateTime endDate;
  final int daysRemaining;
  final bool isActive;
  final bool autoRenew;
  final String? qrCode;
  final DateTime createdAt;

  ActiveSubscriptionModel({
    required this.id,
    required this.planId,
    required this.type,
    required this.duration,
    required this.durationLabel,
    this.gymId,
    this.gymName,
    this.gymAddress,
    this.gymImage,
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.isActive,
    required this.autoRenew,
    this.qrCode,
    required this.createdAt,
  });

  factory ActiveSubscriptionModel.fromJson(Map<String, dynamic> json) {
    // Derive a human-readable duration label from service_name or type when
    // the API does not return explicit duration / duration_label fields.
    final rawType = json['type'] ?? 'single_gym';
    final serviceName = json['service_name'] as String? ?? '';
    final fallbackLabel = serviceName.isNotEmpty
        ? serviceName
        : (rawType == 'multi_gym_membership' || rawType == 'multi_gym'
        ? 'Multi-Gym Membership'
        : 'Membership');

    return ActiveSubscriptionModel(
      id: json['id'] ?? '',
      planId: json['plan_id'] ?? json['booking_number'] ?? '',
      type: rawType,
      duration: json['duration'] ?? rawType,
      durationLabel: json['duration_label'] ?? fallbackLabel,
      gymId: json['gym_id'],
      gymName: json['gym_name'],
      gymAddress: json['gym_address'],
      gymImage: json['gym_image'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      daysRemaining: json['days_remaining'] ?? 0,
      isActive: json['is_active'] ?? false,
      autoRenew: json['auto_renew'] ?? false,
      qrCode: json['qr_code'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'type': type,
      'duration': duration,
      'duration_label': durationLabel,
      'gym_id': gymId,
      'gym_name': gymName,
      'gym_address': gymAddress,
      'gym_image': gymImage,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'days_remaining': daysRemaining,
      'is_active': isActive,
      'auto_renew': autoRenew,
      'qr_code': qrCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
