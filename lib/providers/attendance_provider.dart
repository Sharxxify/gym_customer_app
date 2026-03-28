import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/attendance_model.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  Map<DateTime, bool> _attendanceData = {};
  Map<DateTime, AttendanceRecord> _attendanceRecords = {};
  AttendanceStatistics? _statistics;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  bool _isCheckingIn = false;
  String? _error;
  bool _showRatePrompt = false;
  String? _lastVisitedGymId;
  String? _lastVisitedGymName;

  Map<DateTime, bool> get attendanceData => _attendanceData;
  Map<DateTime, AttendanceRecord> get attendanceRecords => _attendanceRecords;
  AttendanceStatistics? get statistics => _statistics;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  bool get isCheckingIn => _isCheckingIn;
  String? get error => _error;
  bool get showRatePrompt => _showRatePrompt;
  String? get lastVisitedGymId => _lastVisitedGymId;
  String? get lastVisitedGymName => _lastVisitedGymName;

  int get presentDays {
    return _statistics?.presentDays ?? _attendanceData.values.where((v) => v).length;
  }

  int get absentDays {
    return _statistics?.absentDays ?? _attendanceData.values.where((v) => !v).length;
  }

  double get attendancePercentage {
    return _statistics?.attendancePercentage ??
        (_attendanceData.isEmpty ? 0 : (presentDays / _attendanceData.length) * 100);
  }

  String get dateRangeText {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return '${start.day} ${_getMonthName(start.month).toLowerCase()} - ${end.day} ${_getMonthName(end.month).toLowerCase()}';
  }

  Future<void> loadAttendance() async {
    if (_isLoading) return; // Prevent duplicate calls

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get token from storage
      final token = await _getAuthToken();

      if (token == null) {
        throw Exception("Please login to view attendance");
      }

      // Call API
      final calendar = await _attendanceService.getAttendanceCalendar(
        token: token,
        month: _selectedMonth.month,
        year: _selectedMonth.year,
      );

      // Process attendance data
      _attendanceData.clear();
      _attendanceRecords.clear();

      for (var record in calendar.attendance) {
        final date = DateTime.parse(record.date);
        final dateKey = DateTime(date.year, date.month, date.day);
        _attendanceData[dateKey] = record.isPresent;
        _attendanceRecords[dateKey] = record;
      }

      _statistics = calendar.statistics;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Load Attendance Error: $e");
    }
  }

  /// Check-in via QR code scanning
  Future<Map<String, dynamic>> checkIn({
    required String qrCode,
    required String gymId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      _isCheckingIn = true;
      _error = null;
      notifyListeners();

      // Get token from storage
      final token = await _getAuthToken();

      if (token == null) {
        throw Exception("Please login to check-in");
      }

      // Call check-in API
      final response = await _attendanceService.checkIn(
        token: token,
        qrCode: qrCode,
        gymId: gymId,
        latitude: latitude,
        longitude: longitude,
      );

      // Update local attendance data with today's check-in
      if (response.attendance != null) {
        final today = DateTime.now();
        final dateKey = DateTime(today.year, today.month, today.day);
        _attendanceData[dateKey] = true;

        // Set rate prompt data
        _showRatePrompt = true;
        _lastVisitedGymId = response.attendance!.gymId;
        _lastVisitedGymName = response.attendance!.gymName;
      }

      _isCheckingIn = false;
      notifyListeners();

      return {
        'success': true,
        'message': response.message,
        'gymName': response.attendance?.gymName,
      };
    } catch (e) {
      _isCheckingIn = false;
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint("❌ Check-in Error: $e");

      return {
        'success': false,
        'message': _error ?? 'Check-in failed',
      };
    }
  }

  // Helper method to get auth token
  Future<String?> _getAuthToken() async {
    try {
      const storage = FlutterSecureStorage();
      return await storage.read(key: 'auth_token');
    } catch (e) {
      debugPrint("Error getting auth token: $e");
      return null;
    }
  }

  void changeMonth(int delta) {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + delta,
      1,
    );
    // Load attendance for new month
    loadAttendance();
  }

  void setMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    // Load attendance for new month
    loadAttendance();
  }

  void dismissRatePrompt() {
    _showRatePrompt = false;
    _lastVisitedGymId = null;
    _lastVisitedGymName = null;
    notifyListeners();
  }

  bool? getAttendanceForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _attendanceData[dateKey];
  }

  AttendanceRecord? getAttendanceRecordForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _attendanceRecords[dateKey];
  }

  List<DateTime> getPresentDates() {
    return _attendanceData.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }

  List<DateTime> getAbsentDates() {
    return _attendanceData.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}