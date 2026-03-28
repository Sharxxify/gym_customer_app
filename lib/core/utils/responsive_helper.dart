import 'package:flutter/material.dart';

class ResponsiveHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double textScaleFactor;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
    textScaleFactor = _mediaQueryData.textScaleFactor;
  }

  // Width percentage
  static double wp(double percentage) {
    return screenWidth * (percentage / 100);
  }

  // Height percentage
  static double hp(double percentage) {
    return screenHeight * (percentage / 100);
  }

  // Safe width percentage
  static double swp(double percentage) {
    return safeBlockHorizontal * percentage;
  }

  // Safe height percentage
  static double shp(double percentage) {
    return safeBlockVertical * percentage;
  }

  // Font size scaling
  static double sp(double size) {
    return size * (screenWidth / 375); // Based on iPhone X width
  }

  // Responsive value based on screen width
  static T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (screenWidth >= 1200 && desktop != null) {
      return desktop;
    } else if (screenWidth >= 600 && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  // Check device type
  static bool get isMobile => screenWidth < 600;
  static bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  static bool get isDesktop => screenWidth >= 1200;

  // Get safe padding
  static EdgeInsets get safePadding => _mediaQueryData.padding;

  // Get keyboard height
  static double get keyboardHeight => _mediaQueryData.viewInsets.bottom;

  // Check if keyboard is visible
  static bool get isKeyboardVisible => keyboardHeight > 0;
}

// Extension for easier access
extension ResponsiveExtension on num {
  double get w => ResponsiveHelper.wp(toDouble());
  double get h => ResponsiveHelper.hp(toDouble());
  double get sw => ResponsiveHelper.swp(toDouble());
  double get sh => ResponsiveHelper.shp(toDouble());
  double get sp => ResponsiveHelper.sp(toDouble());
}
