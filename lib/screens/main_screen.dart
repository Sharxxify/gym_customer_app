import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/providers.dart';
import 'home_screen.dart';
import 'attendance_screen.dart';
import 'subscription_screen.dart';
import 'set_location_screen.dart';
import 'notification_screen.dart';
import 'side_menu_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialTab;

  const MainScreen({super.key, this.initialTab = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(showAppBar: false),
    AttendanceScreen(showAppBar: false),
    SubscriptionScreen(showAppBar: false),
  ];

  // Track previous index to detect tab changes
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _previousIndex = widget.initialTab;
    _loadData();
  }

  Future<void> _loadData() async {
    final homeProvider = context.read<HomeProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final authProvider = context.read<AuthProvider>();
    final locationProvider = context.read<LocationProvider>();
    final addressProvider = context.read<AddressProvider>();

    await locationProvider.loadSavedLocation();

    final token = authProvider.token;

    if (token != null) {
      await Future.wait([
        homeProvider.loadGyms(token: token),
        homeProvider.loadUserProfile(token),
        homeProvider.loadBanners(),
        attendanceProvider.loadAttendance(),
        addressProvider.loadAddresses(token), // Load addresses
      ]);
    } else {
      await homeProvider.loadBanners();
    }
  }

  // Reload data when switching back to home tab
  Future<void> _reloadHomeData() async {
    final authProvider = context.read<AuthProvider>();
    final addressProvider = context.read<AddressProvider>();
    final homeProvider = context.read<HomeProvider>();

    final token = authProvider.token;
    if (token != null) {
      await Future.wait([
        addressProvider.loadAddresses(token),
        homeProvider.loadBanners(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: const SideMenuScreen(),
      body: SafeArea(
        child: Column(
          children: [
            // Common HomeAppBar for all tabs
            Consumer<AddressProvider>(
              builder: (context, addressProvider, child) {
                final defaultAddress = addressProvider.defaultAddress;

                return HomeAppBar(
                  location: defaultAddress?.roadArea ?? 'Set Location',
                  address: defaultAddress?.fullAddress ?? 'Tap to set your location',
                  onLocationTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SetLocationScreen(),
                      ),
                    );
                  },
                  onNotificationTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                  onMenuTap: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                );
              },
            ),

            // Tab content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Reload home data when switching back to home tab from another tab
          if (index == 0 && _previousIndex != 0) {
            _reloadHomeData();
          }
          // Always refresh active subscriptions when switching to Subscription tab
          if (index == 2) {
            context.read<SubscriptionProvider>().loadActiveSubscriptions();
          }
          setState(() {
            _previousIndex = _currentIndex;
            _currentIndex = index;
          });
        },
      ),
    );
  }
}