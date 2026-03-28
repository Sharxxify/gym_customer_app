import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/formatters.dart';
import '../providers/providers.dart';
import 'qr_scanner_screen.dart';
import 'set_location_screen.dart';
import 'notification_screen.dart';
import 'side_menu_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final bool showAppBar;

  const AttendanceScreen({super.key, this.showAppBar = true});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadAttendance();
    });
  }

  void _showMonthPicker(BuildContext context, AttendanceProvider provider) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    // Generate last 12 months
    final List<DateTime> months = List.generate(12, (index) {
      return DateTime(now.year, now.month - index, 1);
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Month',
                      style: AppTextStyles.heading4,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Divider(height: 1),

              // Month list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: months.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final isCurrentMonth = month.year == currentMonth.year &&
                        month.month == currentMonth.month;
                    final isSelected = month.year == provider.selectedMonth.year &&
                        month.month == provider.selectedMonth.month;

                    String monthLabel;
                    if (isCurrentMonth) {
                      monthLabel = 'This Month';
                    } else {
                      monthLabel = _getMonthYearLabel(month);
                    }

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          provider.setMonth(month);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryGreen.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      monthLabel,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: isSelected
                                            ? AppColors.primaryGreen
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (!isCurrentMonth) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _getDateRange(month),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryGreen,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthYearLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getDateRange(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    const monthsShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${start.day} ${monthsShort[start.month - 1]} - ${end.day} ${monthsShort[end.month - 1]}';
  }

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final contentColumn = Column(
      children: [
        // App bar
        if (widget.showAppBar) ...[
          Consumer2<LocationProvider, HomeProvider>(
            builder: (context, locationProvider, homeProvider, child) {
              return HomeAppBar(
                location: locationProvider.displayLocation,
                address: locationProvider.displayAddress,
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
          AppSpacing.h16,
        ],

        // Title
        Text('Your Attendance', style: AppTextStyles.heading4),
        AppSpacing.h16,

        Expanded(
          child: Consumer<AttendanceProvider>(
            builder: (context, provider, child) {
              // Loading state
              if (provider.isLoading && provider.attendanceData.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                );
              }

              // Error state
              if (provider.error != null && provider.attendanceData.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      AppSpacing.h16,
                      Text(
                        provider.error!,
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.h16,
                      TextButton(
                        onPressed: () {
                          provider.clearError();
                          provider.loadAttendance();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPaddingH,
                ),
                child: Column(
                  children: [
                    // Month selector - NOW CLICKABLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showMonthPicker(context, provider),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isCurrentMonth(provider.selectedMonth)
                                    ? 'This Month'
                                    : _getMonthYearLabel(provider.selectedMonth),
                                style: AppTextStyles.labelMedium,
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 20),
                            ],
                          ),
                        ),
                        AppSpacing.w12,
                        Text(
                          provider.dateRangeText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h16,

                    // Stats card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          AppSpacing.w12,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Days',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${provider.presentDays + provider.absentDays}',
                                style: AppTextStyles.heading4,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Present',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${provider.presentDays}',
                                style: AppTextStyles.heading4,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Absent',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${provider.absentDays}',
                                style: AppTextStyles.heading4.copyWith(
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h24,

                    // Calendar - ORIGINAL DESIGN PRESERVED
                    _buildCalendar(provider),
                  ],
                ),
              );
            },
          ),
        ),

        // Mark attendance button
        Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          child: PrimaryButton(
            text: 'Mark Attendance',
            icon: Icons.qr_code_scanner,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
            },
          ),
        ),
      ],
    );

    // Return without Scaffold when used in MainScreen
    if (!widget.showAppBar) {
      return contentColumn;
    }

    // Return with Scaffold when standalone
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: const SideMenuScreen(),
      body: SafeArea(child: contentColumn),
    );
  }

  Widget _buildCalendar(AttendanceProvider provider) {
    final selectedMonth = provider.selectedMonth;
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    // Previous month days to show
    final prevMonth = DateTime(selectedMonth.year, selectedMonth.month, 0);
    final prevMonthDays = prevMonth.day;

    List<Widget> dayWidgets = [];

    // Previous month trailing days
    for (int i = firstWeekday - 1; i > 0; i--) {
      dayWidgets.add(_buildDayCell(prevMonthDays - i + 1, false, null));
    }

    // Current month days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedMonth.year, selectedMonth.month, day);
      final attendance = provider.getAttendanceForDate(date);
      dayWidgets.add(_buildDayCell(day, true, attendance));
    }

    // Next month leading days
    int nextMonthDay = 1;
    while (dayWidgets.length < 42) {
      dayWidgets.add(_buildDayCell(nextMonthDay++, false, null));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => provider.changeMonth(-1),
                child: Text(
                  AppFormatters.getMonthNameShort(
                    selectedMonth.month == 1 ? 12 : selectedMonth.month - 1,
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              AppSpacing.w24,
              Text(
                AppFormatters.getMonthName(selectedMonth.month),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryGreen,
                ),
              ),
              AppSpacing.w24,
              GestureDetector(
                onTap: () => provider.changeMonth(1),
                child: Text(
                  AppFormatters.getMonthNameShort(
                    selectedMonth.month == 12 ? 1 : selectedMonth.month + 1,
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.h16,

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map((day) => SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  day,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          AppSpacing.h8,

          // Calendar grid
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: dayWidgets,
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, bool isCurrentMonth, bool? attendance) {
    Color bgColor = Colors.transparent;
    Color textColor = isCurrentMonth ? AppColors.textPrimary : AppColors.textHint;

    if (isCurrentMonth && attendance != null) {
      bgColor = attendance ? AppColors.calendarPresent : AppColors.calendarAbsent;
      textColor = AppColors.textPrimary;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppTextStyles.bodySmall.copyWith(color: textColor),
        ),
      ),
    );
  }
}