import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors from design
  static const Color primaryDark = Color(0xFF05110B);
  static const Color primaryOlive = Color(0xFF3A420E);
  static const Color primaryGreen = Color(0xFFA1E433);
  static const Color primaryRed = Color(0xFF4B0202);

  // Background colors
  static const Color background = Color(0xFF05110B);
  static const Color cardBackground = Color(0xFF0D1A12);
  static const Color inputBackground = Color(0xFF0F1E14);
  static const Color surfaceLight = Color(0xFF1A2E1F);

  // Border colors
  static const Color border = Color(0xFF2A3A2E);
  static const Color borderLight = Color(0xFF3A4A3E);
  static const Color inputBorder = Color(0xFF3A420E);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF707070);
  static const Color textGreen = Color(0xFFA1E433);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);

  // Rating colors
  static const Color starFilled = Color(0xFFFFC107);
  static const Color starEmpty = Color(0xFF505050);

  // Calendar colors
  static const Color calendarPresent = Color(0xFF4CAF50);
  static const Color calendarAbsent = Color(0xFF4B0202);
  static const Color calendarWeekend = Color(0xFF1A2E1F);

  // Gradients
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D1A12),
      Color(0xFF1A2E1F),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF8BC34A),
      Color(0xFFA1E433),
    ],
  );

  static const LinearGradient oliveGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF3A420E),
      Color(0xFF252B09),
    ],
  );

  // Box shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
