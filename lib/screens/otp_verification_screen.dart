import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/providers.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart'; // 👈 adjust if your home screen name differs

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final result = await authProvider.verifyOtp(_otp);

    if (!mounted) return;

    if (result != null && authProvider.isAuthenticated) {
      // 🔀 Navigate based on new user flag
      if (authProvider.isNewUser == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
            const ProfileScreen(isInitialSetup: true),
          ),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      }
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error!)),
      );
    }
    // Navigator.pushAndRemoveUntil(
    //     context,
    //     MaterialPageRoute(builder: (_) => const HomeScreen()),
    //         (route) => false,
    //   );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
          // 🔙 Back Button
          Positioned(
          top: 8,
          left: 8,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ),

        // Existing UI (UNCHANGED)
        Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.all(AppDimensions.screenPaddingH),
            child: Container(
              padding:
              const EdgeInsets.all(AppDimensions.paddingXXL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryOlive.withOpacity(0.3),
                    AppColors.cardBackground,
                  ],
                ),
                borderRadius:
                BorderRadius.circular(AppDimensions.radiusXL),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Enter OTP',
                      style: AppTextStyles.heading3),
                  AppSpacing.h16,
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'We\'ve sent a verification code to',
                          style:
                          AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.h4,
                        Text(
                          '+91 ${widget.phoneNumber.replaceAll(' ', '').replaceFirst(RegExp(r'^\+91'), '')}',
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h32,
                  Text(
                    'Verification Code',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary),
                  ),
                  AppSpacing.h12,
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 44,
                        height: 52,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType:
                          TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style:
                          AppTextStyles.heading4.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor:
                            AppColors.inputBackground,
                            contentPadding:
                            EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  AppDimensions.radiusS),
                              borderSide: const BorderSide(
                                  color:
                                  AppColors.inputBorder),
                            ),
                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  AppDimensions.radiusS),
                              borderSide: const BorderSide(
                                  color: AppColors
                                      .primaryGreen),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty &&
                                index < 5) {
                              _focusNodes[index + 1]
                                  .requestFocus();
                            }
                            if (value.isEmpty &&
                                index > 0) {
                              _focusNodes[index - 1]
                                  .requestFocus();
                            }
                            setState(() {});
                          },
                        ),
                      );
                    }),
                  ),
                  AppSpacing.h32,
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return PrimaryButton(
                        text: 'Login',
                        isLoading:
                        auth.status == AuthStatus.loading,
                        isEnabled: _otp.length == 6,
                        onPressed: _handleVerify,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

    ],
    ),
    ),
    );
  }
}
