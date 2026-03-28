import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> fetchNotifications({
    required String token,
    bool refresh = false,
    bool unreadOnly = false,
  }) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _notifications = [];
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _notificationService.getNotifications(
        token: token,
        page: _currentPage,
        limit: 20,
        unreadOnly: unreadOnly,
      );

      if (refresh) {
        _notifications = response.notifications;
      } else {
        _notifications.addAll(response.notifications);
      }

      _unreadCount = response.unreadCount;
      _totalPages = response.totalPages;
      _hasMore = _currentPage < _totalPages;

      if (_hasMore) {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      debugPrint("❌ Fetch Notifications Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String token, String notificationId) async {
    try {
      final success = await _notificationService.markAsRead(
        token: token,
        notificationId: notificationId,
      );

      if (success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1 && !_notifications[index].isRead) {
          _notifications[index] = NotificationModel(
            id: _notifications[index].id,
            title: _notifications[index].title,
            message: _notifications[index].message,
            type: _notifications[index].type,
            isRead: true,
            actionType: _notifications[index].actionType,
            actionId: _notifications[index].actionId,
            createdAt: _notifications[index].createdAt,
          );
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("❌ Mark as Read Error: $e");
    }
  }

  Future<void> markAllAsRead(String token) async {
    try {
      final success = await _notificationService.markAllAsRead(token: token);

      if (success) {
        _notifications = _notifications.map((n) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            actionType: n.actionType,
            actionId: n.actionId,
            createdAt: n.createdAt,
          );
        }).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Mark All as Read Error: $e");
    }
  }

  Future<void> deleteNotification(String token, String notificationId) async {
    try {
      final success = await _notificationService.deleteNotification(
        token: token,
        notificationId: notificationId,
      );

      if (success) {
        final wasUnread = _notifications
            .firstWhere((n) => n.id == notificationId, orElse: () => _notifications.first)
            .isRead == false;

        _notifications.removeWhere((n) => n.id == notificationId);

        if (wasUnread) {
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ Delete Notification Error: $e");
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _notifications = [];
    _unreadCount = 0;
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}