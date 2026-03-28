import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/providers.dart';
import 'main_screen.dart';

class AddAddressScreen extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? locality;

  const AddAddressScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.locality,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _houseFlatController = TextEditingController();
  final _roadAreaController = TextEditingController();
  final _streetCityController = TextEditingController();
  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isSaving = false;

  final List<String> _labels = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.locality != null) {
      _streetCityController.text = widget.locality!;
    }
  }

  @override
  void dispose() {
    _houseFlatController.dispose();
    _roadAreaController.dispose();
    _streetCityController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    // Detailed validation with specific field messages
    List<String> emptyFields = [];

    if (_houseFlatController.text.trim().isEmpty) {
      emptyFields.add('House/Flat/Block');
    }

    if (_roadAreaController.text.trim().isEmpty) {
      emptyFields.add('Apartment/Road/Area');
    }

    if (_streetCityController.text.trim().isEmpty) {
      emptyFields.add('Street and City');
    }

    // Show validation errors if any fields are empty
    if (emptyFields.isNotEmpty) {
      String message = emptyFields.length == 1
          ? 'Please fill in ${emptyFields[0]}'
          : 'Please fill in: ${emptyFields.join(', ')}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check if location is available
    if (widget.latitude == null || widget.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please go back and select location.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.token == null) {
        throw Exception("Authentication required. Please login again.");
      }

      final addressProvider = context.read<AddressProvider>();

      // Call API to add address
      final success = await addressProvider.addAddress(
        token: authProvider.token!,
        houseFlat: _houseFlatController.text.trim(),
        roadArea: _roadAreaController.text.trim(),
        streetCity: _streetCityController.text.trim(),
        label: _selectedLabel,
        latitude: widget.latitude!,
        longitude: widget.longitude!,
        isDefault: _isDefault,
      );

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address added successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
        );
      } else {
        // Show error message
        final error = addressProvider.error ?? 'Failed to add address';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Add Address'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingXL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryOlive.withOpacity(0.2),
                      AppColors.cardBackground,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textPrimary,
                          size: 28,
                        ),
                      ),
                    ),
                    AppSpacing.h24,

                    // House/Flat/Block
                    CustomTextField(
                      label: 'House/Flat/Block',
                      hint: 'Flat 203, Building A',
                      controller: _houseFlatController,
                      textInputAction: TextInputAction.next,
                    ),
                    AppSpacing.h20,

                    // Apartment/Road/Area
                    CustomTextField(
                      label: 'Apartment/Road/Area',
                      hint: 'Koramangala 5th Block',
                      controller: _roadAreaController,
                      textInputAction: TextInputAction.next,
                    ),
                    AppSpacing.h20,

                    // Street and City
                    CustomTextField(
                      label: 'Street and City',
                      hint: 'Bengaluru, Karnataka',
                      controller: _streetCityController,
                      textInputAction: TextInputAction.done,
                      maxLines: 2,
                    ),
                    AppSpacing.h20,

                    // Save address as
                    Text(
                      'Save address as',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    AppSpacing.h12,
                    Row(
                      children: _labels.map((label) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildLabelChip(label),
                        );
                      }).toList(),
                    ),
                    AppSpacing.h20,

                    // Set as default address
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set as default address',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                AppSpacing.h4,
                                Text(
                                  'This address will be used by default for deliveries',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.w12,
                          Switch(
                            value: _isDefault,
                            onChanged: (value) {
                              setState(() => _isDefault = value);
                            },
                            activeColor: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
            child: PrimaryButton(
              text: _isSaving ? 'Saving...' : 'Save Address',
              onPressed: _isSaving ? null : _saveAddress,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelChip(String label) {
    final isSelected = _selectedLabel == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedLabel = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withOpacity(0.1)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}