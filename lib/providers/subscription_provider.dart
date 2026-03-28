import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  // ─── Active Subscriptions state ─────────────────────────────────────────

  List<ActiveSubscriptionModel> _subscriptions = [];
  bool _isLoading = false;
  String? _error;

  List<ActiveSubscriptionModel> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Returns true if user has any active multi-gym membership.
  /// Covers both "multi_gym" (legacy) and "multi_gym_membership" (API value).
  bool get hasActiveMultiGymMembership => _subscriptions.any(
        (s) =>
    s.isActive &&
        (s.type == 'multi_gym_membership' || s.type == 'multi_gym'),
  );

  /// Returns the active multi-gym subscription, if any.
  ActiveSubscriptionModel? get activeMultiGymSubscription {
    try {
      return _subscriptions.firstWhere(
            (s) =>
        s.isActive &&
            (s.type == 'multi_gym_membership' || s.type == 'multi_gym'),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Multi-Gym Pricing state ─────────────────────────────────────────────

  List<MultiGymPricingModel> _multiGymPricing = [];
  bool _isPricingLoading = false;
  String? _pricingError;
  bool _pricingLoaded = false;

  bool get isPricingLoading => _isPricingLoading;
  String? get pricingError => _pricingError;

  List<MultiGymPricingModel> get multiGymPricing => _multiGymPricing;

  List<SubscriptionModel> get multiGymPlans =>
      _multiGymPricing.map((p) => p.toSubscriptionModel()).toList();

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<String?> _getAuthToken() async {
    try {
      return await const FlutterSecureStorage().read(key: 'auth_token');
    } catch (e) {
      debugPrint("Error getting auth token: $e");
      return null;
    }
  }

  // ─── Active Subscriptions ────────────────────────────────────────────────

  Future<void> loadActiveSubscriptions() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Authentication required. Please login again.");
      }

      _subscriptions = await _subscriptionService.getActiveSubscriptions(
        token: token,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Load Active Subscriptions Error: $e");
    }
  }

  // ─── Multi-Gym Pricing ───────────────────────────────────────────────────

  Future<void> fetchMultiGymPricing({bool forceRefresh = false}) async {
    if (_isPricingLoading) return;
    if (_pricingLoaded && !forceRefresh) return;

    try {
      _isPricingLoading = true;
      _pricingError = null;
      notifyListeners();

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Authentication required. Please login again.");
      }

      _multiGymPricing = await _subscriptionService.fetchMultiGymPricing(
        token: token,
      );

      _pricingLoaded = true;
      _isPricingLoading = false;
      notifyListeners();

      debugPrint("✅ Multi-Gym Pricing loaded: ${_multiGymPricing.length} tiers");
    } catch (e) {
      _isPricingLoading = false;
      _pricingError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Fetch Multi-Gym Pricing Error: $e");
    }
  }

  // ─── Error helpers ───────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearPricingError() {
    _pricingError = null;
    notifyListeners();
  }
}