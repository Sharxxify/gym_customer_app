import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/formatters.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import 'gym_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'attendance_screen.dart';
import 'subscription_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.token != null) {
      await context.read<NotificationProvider>().fetchNotifications(
        token: authProvider.token!,
        refresh: true,
      );
    }
  }

  Future<void> _loadMore() async {
    final authProvider = context.read<AuthProvider>();
    final notifProvider = context.read<NotificationProvider>();

    if (authProvider.token != null &&
        notifProvider.hasMore &&
        !notifProvider.isLoading) {
      await notifProvider.fetchNotifications(token: authProvider.token!);
    }
  }

  Future<void> _markAllAsRead() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.token != null) {
      await context
          .read<NotificationProvider>()
          .markAllAsRead(authProvider.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    final authProvider = context.read<AuthProvider>();

    // Mark as read
    if (!notification.isRead && authProvider.token != null) {
      context.read<NotificationProvider>().markAsRead(
        authProvider.token!,
        notification.id,
      );
    }

    // TODO: Navigation disabled temporarily - Re-enable when needed
    /*
    // Navigate based on action type
    if (notification.actionType == null) return;

    switch (notification.actionType) {
      case 'booking_detail':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
        );
        break;
      case 'attendance_detail':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
        );
        break;
      case 'subscription':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
        break;
      case 'gym_detail':
        // Navigate to gym detail if needed
        if (notification.actionId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GymDetailScreen(gymId: notification.actionId!),
            ),
          );
        }
        break;
    }
    */
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.check_circle;
      case 'attendance':
        return Icons.qr_code_scanner;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return AppColors.primaryGreen;
      case 'attendance':
        return Colors.blue;
      case 'promotion':
        return AppColors.starFilled;
      case 'system':
        return Colors.grey;
      default:
        return AppColors.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: AppTextStyles.heading4),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: _markAllAsRead,
                  child: Text(
                    'Mark All Read',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          // Loading state - first time
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          // Error state - no notifications loaded
          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.h16,
                    Text(
                      provider.error!,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.h16,
                    ElevatedButton(
                      onPressed: _loadNotifications,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state
          if (provider.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  AppSpacing.h16,
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AppSpacing.h8,
                  Text(
                    'We\'ll notify you when something arrives',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Notifications list
          return RefreshIndicator(
            onRefresh: _loadNotifications,
            color: AppColors.primaryGreen,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
              itemCount:
              provider.notifications.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Loading indicator at bottom
                if (index == provider.notifications.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(
                          color: AppColors.primaryGreen)
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final notification = provider.notifications[index];
                final icon = _getNotificationIcon(notification.type);
                final color = _getNotificationColor(notification.type);

                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.token != null) {
                      provider.deleteNotification(
                        authProvider.token!,
                        notification.id,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification deleted'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: InkWell(
                    onTap: () => _handleNotificationTap(notification),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: notification.isRead
                            ? null
                            : AppColors.cardGradient,
                        color: notification.isRead
                            ? AppColors.cardBackground.withOpacity(0.5)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: notification.isRead
                              ? AppColors.border.withOpacity(0.3)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          AppSpacing.w12,
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                          fontWeight: notification.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                AppSpacing.h4,
                                Text(
                                  notification.message,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                AppSpacing.h4,
                                Text(
                                  AppFormatters.formatRelativeTime(
                                      notification.createdAt),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}