import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  // Booking state
  GymModel? _selectedGym;
  ServiceModel? _selectedService;
  DateTime? _selectedDate;
  TimeSlotModel? _selectedTimeSlot;
  int _slotCount = 1;
  String _bookingFor = '';
  AddressModel? _serviceLocation;

  // Subscription state
  String _subscriptionType = 'single_gym'; // single_gym or multi_gym
  SubscriptionModel? _selectedPlan;

  // General state
  List<BookingModel> _bookings = [];
  List<TimeSlotModel> _availableSlots = [];
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  String? _error;
  Map<String, dynamic>? _currentBookingDetails; // For storing fetched booking details

  // Getters
  GymModel? get selectedGym => _selectedGym;
  ServiceModel? get selectedService => _selectedService;
  DateTime? get selectedDate => _selectedDate;
  TimeSlotModel? get selectedTimeSlot => _selectedTimeSlot;
  int get slotCount => _slotCount;
  String get bookingFor => _bookingFor;
  AddressModel? get serviceLocation => _serviceLocation;
  String get subscriptionType => _subscriptionType;
  SubscriptionModel? get selectedPlan => _selectedPlan;
  List<BookingModel> get bookings => _bookings;
  List<TimeSlotModel> get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  bool get isLoadingSlots => _isLoadingSlots;
  String? get error => _error;
  Map<String, dynamic>? get currentBookingDetails => _currentBookingDetails;

  // Price calculations
  double get serviceTotal {
    if (_selectedService == null) return 0;
    return _selectedService!.pricePerSlot * _slotCount.toDouble();
  }

  double get visitingFee => 99;
  double get tax => (serviceTotal * 0.18);
  double get totalAmount => serviceTotal + visitingFee + tax;

  // Initialize booking for a gym
  void initializeBooking(GymModel gym) {
    _selectedGym = gym;
    _selectedService = null;
    _selectedDate = DateTime.now();
    _selectedTimeSlot = null;
    _slotCount = 1;
    _availableSlots = [];  // Clear slots, will be loaded when service is selected
    notifyListeners();
  }

  // Select service
  void selectService(ServiceModel service) {
    _selectedService = service;
    notifyListeners();
  }

  // Select date
  void selectDate(DateTime date) {
    _selectedDate = date;
    // Note: Caller should call loadAvailableSlots(token) after this
    notifyListeners();
  }

  // Select time slot
  void selectTimeSlot(TimeSlotModel slot) {
    _selectedTimeSlot = slot;
    notifyListeners();
  }

  // Update slot count
  void updateSlotCount(int count) {
    if (count >= 1 && count <= 10) {
      _slotCount = count;
      notifyListeners();
    }
  }

  void incrementSlots() {
    if (_slotCount < 10) {
      _slotCount++;
      notifyListeners();
    }
  }

  void decrementSlots() {
    if (_slotCount > 1) {
      _slotCount--;
      notifyListeners();
    }
  }

  // Set booking for
  void setBookingFor(String name) {
    _bookingFor = name;
    notifyListeners();
  }

  // Set service location
  void setServiceLocation(AddressModel address) {
    _serviceLocation = address;
    notifyListeners();
  }

  // Subscription methods
  void setSubscriptionType(String type) {
    _subscriptionType = type;
    _selectedPlan = null;
    notifyListeners();
  }

  void selectPlan(SubscriptionModel plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  /// Returns plans for the given type.
  /// Multi-gym plans are fetched from the API via [SubscriptionProvider]
  /// and handled in [SubscriptionScreen] — this returns [] for that type.
  /// Single-gym plans come from [GymModel.membershipFees] on the detail screen.
  List<SubscriptionModel> getPlansForType(String type) {
    return [];
  }

  // Load available time slots from API
  Future<void> loadAvailableSlots({
    required String token,
    required int slotCount,
  }) async {
    if (_selectedGym == null || _selectedService == null || _selectedDate == null) {
      debugPrint("❌ Cannot load slots: Missing gym, service, or date");
      return;
    }

    try {
      _isLoadingSlots = true;
      _error = null;
      notifyListeners();

      // Format date as YYYY-MM-DD
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      _availableSlots = await _bookingService.getTimeSlots(
        token: token,
        gymId: _selectedGym!.id,
        serviceId: _selectedService!.id,
        date: dateStr,
        slotCount: slotCount,
      );

      _isLoadingSlots = false;
      notifyListeners();
    } catch (e) {
      _isLoadingSlots = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Load Time Slots Error: $e");
    }
  }

  // Load user bookings
  Future<void> loadBookings({
    String status = 'all',
    String type = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get token from storage - assuming it's available
      // Note: You may need to pass token as parameter if not accessible here
      final token = await _getAuthToken();

      if (token == null) {
        throw Exception("Please login to view bookings");
      }

      _bookings = await _bookingService.getUserBookings(
        token: token,
        status: status,
        type: type,
        page: page,
        limit: limit,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Load Bookings Error: $e");
    }
  }

  // Helper method to get auth token
  // You'll need to adjust this based on how you store/access the token
  Future<String?> _getAuthToken() async {
    // Option 1: If you have access to AuthProvider token
    // return authProvider.token;

    // Option 2: If you use FlutterSecureStorage directly
    try {
      final storage = const FlutterSecureStorage();
      return await storage.read(key: 'auth_token');
    } catch (e) {
      debugPrint("Error getting auth token: $e");
      return null;
    }
  }

  // Create service booking
  Future<Map<String, dynamic>?> createServiceBooking() async {
    if (_selectedGym == null || _selectedService == null ||
        _selectedDate == null || _selectedTimeSlot == null) {
      _error = 'Please complete all booking details';
      notifyListeners();
      return null;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get auth token
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Authentication required. Please login again.");
      }

      // Parse time from "9:00 AM" format to DateTime
      final startDateTime = _parseTimeSlot(_selectedTimeSlot!.startTime, _selectedDate!);
      final startTime = startDateTime.toIso8601String();

      // Format booking date as YYYY-MM-DD
      final bookingDate = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      // Call API
      final response = await _bookingService.createServiceBooking(
        token: token,
        gymId: _selectedGym!.id,
        serviceId: _selectedService!.id,
        startTime: startTime,
        hours: _slotCount,
        bookingDate: bookingDate,
        timeSlotId: _selectedTimeSlot!.id,
        bookingFor: _bookingFor,
        serviceLocation: _serviceLocation?.fullAddress,
        paymentMethod: 'razorpay',
        amount: serviceTotal,
        visitingFee: visitingFee,
        tax: tax,
        totalAmount: totalAmount,
      );

      _isLoading = false;
      notifyListeners();

      return response;  // Returns { booking: {...}, payment_link_url: "..." }
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Create Service Booking Error: $e");
      return null;
    }
  }

  // Get booking details by ID
  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Authentication required. Please login again.");
      }

      final bookingDetails = await _bookingService.getBookingDetails(
        token: token,
        bookingId: bookingId,
      );

      _currentBookingDetails = bookingDetails; // Store for SuccessScreen
      _isLoading = false;
      notifyListeners();

      return bookingDetails;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Get Booking Details Error: $e");
      return null;
    }
  }

  // Verify payment
  Future<bool> verifyPayment(String bookingId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Authentication required. Please login again.");
      }

      return await _bookingService.verifyPayment(
        token: token,
        bookingId: bookingId,
      );
    } catch (e) {
      debugPrint("❌ Verify Payment Error: $e");
      return false;
    }
  }

  // Create membership booking
  // Create membership booking (single or multi-gym)
  Future<Map<String, dynamic>?> createMembershipBooking({String? gymId}) async {
    print(_selectedPlan);
    if (_selectedPlan == null) {
      _error = 'Please select a subscription plan';
      notifyListeners();
      return null;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Authentication required. Please login again.");
      }

      Map<String, dynamic> response;

      // Call appropriate API based on type
      if (_subscriptionType == 'single_gym') {
        if (gymId == null) {
          throw Exception("Gym ID is required for single gym membership");
        }

        response = await _bookingService.createMembershipBooking(
          token: token,
          gymId: gymId,
          bookingFor: _bookingFor.isNotEmpty ? _bookingFor : null,
          amount: _selectedPlan!.price.toDouble(),
          duration: _selectedPlan!.duration,
          planId: _selectedPlan!.id,
        );
      } else {
        // Multi-gym membership
        response = await _bookingService.createMultiGymMembershipBooking(
          token: token,
          bookingFor: _bookingFor.isNotEmpty ? _bookingFor : null,
          amount: _selectedPlan!.price.toDouble(),
          duration: _selectedPlan!.duration,
          planId: _selectedPlan!.id,
        );
      }

      _isLoading = false;
      notifyListeners();

      return response; // { membership_id, payment_link_url }
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Create Membership Booking Error: $e");
      return null;
    }
  }

  // Verify membership payment
  Future<bool> verifyMembershipPayment(String membershipId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Authentication required. Please login again.");
      }

      final verified = await _bookingService.verifyMembershipPayment(
        token: token,
        membershipId: membershipId,
      );

      return verified;
    } catch (e) {
      debugPrint("❌ Verify Membership Payment Error: $e");
      return false;
    }
  }

  // Get membership details
  Future<Map<String, dynamic>?> getMembershipDetails(String membershipId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception("Authentication required. Please login again.");
      }

      final details = await _bookingService.getMembershipDetails(
        token: token,
        membershipId: membershipId,
      );

      _isLoading = false;
      notifyListeners();

      return details;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("❌ Get Membership Details Error: $e");
      return null;
    }
  }

  // Reset booking state
  void resetBooking() {
    _selectedService = null;
    _selectedDate = DateTime.now();
    _selectedTimeSlot = null;
    _slotCount = 1;
    _bookingFor = '';
    _serviceLocation = null;
    _selectedPlan = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper function to parse time slot format "9:00 AM" to DateTime
  DateTime _parseTimeSlot(String timeString, DateTime date) {
    try {
      // Remove any extra whitespace
      timeString = timeString.trim();

      // Check if it contains AM/PM
      final isAM = timeString.toUpperCase().contains('AM');
      final isPM = timeString.toUpperCase().contains('PM');

      // Remove AM/PM and trim
      String cleanTime = timeString.replaceAll(RegExp(r'[APMapm\s]+'), '').trim();

      // Split by colon
      final parts = cleanTime.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid time format: $timeString');
      }

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      // Convert to 24-hour format if PM
      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }

      return DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
    } catch (e) {
      debugPrint('❌ Error parsing time: $timeString - $e');
      // Fallback to current time
      return DateTime.now();
    }
  }
}