import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import 'confirmation_screen.dart';

class TimeSlotScreen extends StatefulWidget {
  final GymModel gym;
  final ServiceModel service;

  const TimeSlotScreen({
    super.key,
    required this.gym,
    required this.service,
  });

  @override
  State<TimeSlotScreen> createState() => _TimeSlotScreenState();
}

class _TimeSlotScreenState extends State<TimeSlotScreen> {
  DateTime? _selectedDate;
  TimeSlotModel? _selectedSlot;

  final List<DateTime> _availableDates = List.generate(
    7,
        (index) => DateTime.now().add(Duration(days: index)),
  );

  @override
  void initState() {
    super.initState();
    _selectedDate = _availableDates.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimeSlots();
    });
  }

  Future<void> _loadTimeSlots() async {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      await context.read<BookingProvider>().loadAvailableSlots(
        token: token,
        slotCount: context.read<BookingProvider>().slotCount,
      );
    }
  }

  Future<void> _onDateChanged(DateTime date) async {
    setState(() => _selectedDate = date);
    context.read<BookingProvider>().selectDate(date);
    await _loadTimeSlots();
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Today, ${AppFormatters.getDayName(date.weekday)}';
    } else if (date.day == tomorrow.day && date.month == tomorrow.month && date.year == tomorrow.year) {
      return 'Tomorrow, ${AppFormatters.getDayName(date.weekday)}';
    } else {
      return '${AppFormatters.getDayName(date.weekday)} ,${date.day} ${AppFormatters.getMonthNameShort(date.month)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            final slots = bookingProvider.availableSlots;

            final morningSlots = slots.where((s) => s.period == 'morning').toList();
            final afternoonSlots = slots.where((s) => s.period == 'afternoon').toList();
            final eveningSlots = slots.where((s) => s.period == 'evening').toList();

            return Column(
              children: [
                // Back button at top
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Spacer to push content to bottom
                const Spacer(),

                // Main container at bottom
                Container(
                  margin: EdgeInsets.all(screenWidth * 0.04),
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryOlive.withOpacity(0.3),
                        AppColors.cardBackground,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Select Pickup Slot',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Main content - Date list + Time slots
                      SizedBox(
                        height: screenHeight * 0.4, // Fixed height for scrolling
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - Date list with green indicator
                            SizedBox(
                              width: screenWidth * 0.35,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: _availableDates.map((date) {
                                  final isSelected = _selectedDate != null &&
                                      _selectedDate!.day == date.day &&
                                      _selectedDate!.month == date.month;

                                  return GestureDetector(
                                    onTap: () => _onDateChanged(date),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: BorderSide(
                                            color: isSelected
                                                ? AppColors.primaryGreen
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.03,
                                          vertical: screenHeight * 0.014,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            _getDateLabel(date),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.primaryGreen
                                                  : AppColors.textSecondary,
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            SizedBox(width: screenWidth * 0.02),

                            // Right side - Time slots (Scrollable)
                            Expanded(
                              child: bookingProvider.isLoadingSlots
                                  ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryGreen,
                                ),
                              )
                                  : bookingProvider.error != null
                                  ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.error,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      bookingProvider.error!,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: _loadTimeSlots,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                                  : slots.isEmpty
                                  ? Center(
                                child: Text(
                                  'No slots available',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                                  : SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Morning slots
                                    if (morningSlots.isNotEmpty) ...[
                                      _buildSectionTitle('Morning'),
                                      SizedBox(height: screenHeight * 0.008),
                                      ...morningSlots.map((slot) => _buildSlotTile(slot, screenWidth)),
                                      SizedBox(height: screenHeight * 0.012),
                                    ],

                                    // Afternoon slots
                                    if (afternoonSlots.isNotEmpty) ...[
                                      _buildSectionTitle('After noon'),
                                      SizedBox(height: screenHeight * 0.008),
                                      ...afternoonSlots.map((slot) => _buildSlotTile(slot, screenWidth)),
                                      SizedBox(height: screenHeight * 0.012),
                                    ],

                                    // Evening slots
                                    if (eveningSlots.isNotEmpty) ...[
                                      _buildSectionTitle('Evening'),
                                      SizedBox(height: screenHeight * 0.008),
                                      ...eveningSlots.map((slot) => _buildSlotTile(slot, screenWidth)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      // Selected summary
                      if (_selectedDate != null && _selectedSlot != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.012),
                          child: Center(
                            child: Text(
                              _getSelectedSummary(),
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Confirm button
                      PrimaryButton(
                        text: 'Confirm Slot',
                        isEnabled: _selectedSlot != null,
                        onPressed: () {
                          if (_selectedSlot != null) {
                            bookingProvider.selectTimeSlot(_selectedSlot!);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConfirmationScreen(
                                  gym: widget.gym,
                                  service: widget.service,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSlotTile(TimeSlotModel slot, double screenWidth) {
    final isSelected = _selectedSlot?.id == slot.id;
    final isDisabled = !slot.isAvailable;

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _selectedSlot = slot),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.035,
            vertical: screenWidth * 0.028,
          ),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryGreen
                : AppColors.inputBackground.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen
                  : AppColors.inputBackground,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              slot.label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getSelectedSummary() {
    if (_selectedDate == null || _selectedSlot == null) return '';

    final now = DateTime.now();
    String dateStr;

    if (_selectedDate!.day == now.day &&
        _selectedDate!.month == now.month &&
        _selectedDate!.year == now.year) {
      dateStr = 'Today';
    } else {
      dateStr = '${_selectedDate!.day} ${AppFormatters.getMonthNameShort(_selectedDate!.month)}';
    }

    return '$dateStr, ${_selectedSlot!.startTime}';
  }
}