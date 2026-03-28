// Side Menu Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../providers/providers.dart';
import 'profile_screen.dart';
import 'my_bookings_screen.dart';
import 'my_subscriptions_screen.dart';
import 'login_screen.dart';

class SideMenuScreen extends StatelessWidget {
  const SideMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.h24,
            // My Account Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'My Account',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            AppSpacing.h8,
            _buildMenuItem(
              context,
              Icons.person_outline,
              'My Profile',
                  () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(
                      isEditMode: true, // ✅ Pass isEditMode=true to fetch data from API
                    ),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              Icons.receipt_long_outlined,
              'My Bookings',
                  () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              Icons.diamond_outlined,
              'My Subscription',
                  () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MySubscriptionsScreen()),
                );
              },
            ),
            AppSpacing.h24,

            // Settings & Support Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Settings & Support',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            AppSpacing.h8,
            _buildMenuItem(context, Icons.help_outline, 'FAQ', () {}),
            _buildMenuItem(context, Icons.support_agent_outlined, 'Support', () {}),
            _buildMenuItem(context, Icons.call_outlined, 'Contact Us', () {}),
            _buildMenuItem(context, Icons.share_outlined, 'Share App with Friends', () {}),
            _buildMenuItem(
              context,
              Icons.logout,
              'Logout',
                  () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(title, style: AppTextStyles.bodyMedium),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // ✅ Get provider references BEFORE popping
              final authProvider = context.read<AuthProvider>();
              final homeProvider = context.read<HomeProvider>();

              // Close dialog
              Navigator.pop(dialogContext);

              // Perform logout
              await authProvider.logout();

              // Optional: reset home state
              homeProvider.clearFilters();

              // Navigate to login screen (check if widget is still mounted)
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}