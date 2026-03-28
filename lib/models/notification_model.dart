class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // booking, attendance, promotion, system
  final bool isRead;
  final String? actionType; // booking_detail, attendance_detail, subscription
  final String? actionId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.actionType,
    this.actionId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      actionType: json['action_type'] ?? json['actionType'],
      actionId: json['action_id'] ?? json['actionId'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'action_type': actionType,
      'action_id': actionId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  NotificationResponse({
    required this.notifications,
    required this.unreadCount,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final pagination = data['pagination'] ?? {};

    return NotificationResponse(
      notifications: (data['notifications'] as List?)
          ?.map((n) => NotificationModel.fromJson(n))
          .toList() ??
          [],
      unreadCount: data['unread_count'] ?? 0,
      currentPage: pagination['current_page'] ?? 1,
      totalPages: pagination['total_pages'] ?? 1,
      totalCount: pagination['total_count'] ?? 0,
    );
  }
}