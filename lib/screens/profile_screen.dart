import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/providers.dart';
import '../services/upload_service.dart';
import 'set_location_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isInitialSetup;
  final bool isEditMode; // New parameter to distinguish between onboarding and editing

  const ProfileScreen({
    super.key,
    this.isInitialSetup = false,
    this.isEditMode = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedGender;
  File? _profileImage;
  String? _uploadedImageUrl; // Store the uploaded URL from API
  bool _isUploadingImage = false; // Track upload state
  bool _isLoadingProfile = false; // Track profile loading state
  final _picker = ImagePicker();
  final _uploadService = UploadService();

  @override
  void initState() {
    super.initState();
    // Load profile data based on mode
    if (widget.isEditMode) {
      // Fetch fresh data from API when in edit mode
      _loadProfileFromAPI();
    } else {
      // Load from local auth provider for onboarding
      _loadLocalUserData();
    }
  }

  /// Load user data from local AuthProvider (for onboarding flow)
  void _loadLocalUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
      _selectedGender = user.gender;
      _uploadedImageUrl = user.profileImage;
    }
  }

  /// Fetch profile data from API (for edit mode)
  Future<void> _loadProfileFromAPI() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Load profile from API and update local state
      final success = await authProvider.loadUserProfile();

      if (success && mounted) {
        final user = authProvider.user;
        if (user != null) {
          setState(() {
            _nameController.text = user.name ?? '';
            _emailController.text = user.email ?? '';
            _selectedGender = user.gender;
            _uploadedImageUrl = user.profileImage;
            _isLoadingProfile = false;
          });
        }
      } else {
        setState(() {
          _isLoadingProfile = false;
        });

        if (mounted && authProvider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load profile: ${authProvider.error}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
        _isUploadingImage = true;
      });

      try {
        // Get token from auth provider
        final token = context.read<AuthProvider>().token;

        if (token == null) {
          throw Exception("Authentication required. Please login again.");
        }

        // Upload file and get URL
        final uploadedUrl = await _uploadService.uploadFile(
          token: token,
          file: File(picked.path),
        );

        setState(() {
          _uploadedImageUrl = uploadedUrl;
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully'),
              backgroundColor: AppColors.primaryGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isUploadingImage = false;
          _profileImage = null; // Clear image on upload failure
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleUpdate() async {
    // Validate required fields - only for Update Profile, not Skip
    List<String> emptyFields = [];

    if (_nameController.text.trim().isEmpty) {
      emptyFields.add('Name');
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      emptyFields.add('Gender');
    }

    if (_emailController.text.trim().isEmpty) {
      emptyFields.add('Email');
    }

    // Check if profile image is uploaded (only during initial setup)
    if (widget.isInitialSetup && _uploadedImageUrl == null && _profileImage == null) {
      emptyFields.add('Profile Image');
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

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      gender: _selectedGender,
      profileImagePath: _uploadedImageUrl, // Send uploaded URL to API
    );

    if (success && mounted) {
      if (widget.isInitialSetup) {
        // Onboarding flow - go to location screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SetLocationScreen(isInitialSetup: true)),
        );
      } else {
        // Edit mode - go back and show success message
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleSkip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SetLocationScreen(isInitialSetup: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isInitialSetup
          ? null
          : const CustomAppBar(title: 'My Profile'),
      body: _isLoadingProfile
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
        ),
      )
          : SafeArea(
        child: Column(
          children: [
            if (widget.isInitialSetup) ...[
              AppSpacing.h24,
              Text(
                'Profile Details',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primaryGreen,
                ),
              ),
              AppSpacing.h16,
            ],
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
                        AppColors.primaryOlive.withOpacity(0.3),
                        AppColors.cardBackground,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      AppSpacing.h16,
                      // Profile Image
                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.surfaceLight,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                                  ? NetworkImage(_uploadedImageUrl!) as ImageProvider
                                  : null,
                              child: (_profileImage == null && (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty))
                                  ? const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.textSecondary,
                              )
                                  : null,
                            ),
                            // Loading indicator overlay
                            if (_isUploadingImage)
                              Positioned.fill(
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.primaryDark.withOpacity(0.7),
                                  child: const CircularProgressIndicator(
                                    color: AppColors.primaryGreen,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            // Add button
                            if (!_isUploadingImage)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 20,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      AppSpacing.h32,

                      // Phone Number (Read-only, shown in edit mode)
                      if (widget.isEditMode) ...[
                        Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone Number',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                AppSpacing.h8,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                                    border: Border.all(color: AppColors.inputBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                      AppSpacing.w12,
                                      Text(
                                        auth.user?.phoneNumber ?? 'N/A',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        AppSpacing.h20,
                      ],

                      // Name Field
                      CustomTextField(
                        label: 'Your Name',
                        hint: 'Enter your name',
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                      ),
                      AppSpacing.h20,

                      // Gender Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gender',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          AppSpacing.h8,
                          Row(
                            children: [
                              Expanded(
                                child: _GenderButton(
                                  label: 'Male',
                                  isSelected: _selectedGender?.toLowerCase() == 'male',
                                  onTap: () {
                                    setState(() => _selectedGender = 'male');
                                  },
                                ),
                              ),
                              AppSpacing.w12,
                              Expanded(
                                child: _GenderButton(
                                  label: 'Female',
                                  isSelected: _selectedGender?.toLowerCase() == 'female',
                                  onTap: () {
                                    setState(() => _selectedGender = 'female');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      AppSpacing.h20,

                      // Email Field
                      CustomTextField(
                        label: 'Email',
                        hint: 'michael.mitc@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                      ),
                      AppSpacing.h32,

                      // Skip button (only for initial setup)
                      if (widget.isInitialSetup) ...[
                        TextButton(
                          onPressed: _handleSkip,
                          child: Text(
                            'Skip',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Update Button
            Padding(
              padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
              child: Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return PrimaryButton(
                    text: widget.isEditMode ? 'Update Profile' : 'Continue',
                    isLoading: auth.status == AuthStatus.loading,
                    onPressed: _handleUpdate,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withOpacity(0.1)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.inputBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}