import 'package:flutter/cupertino.dart';

/// iOS-specific theme and styling for EduVision
class EduVisionTheme {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryPurple = Color(0xFF5856D6);
  static const Color primaryTeal = Color(0xFF5AC8FA);
  static const Color primaryGreen = Color(0xFF34C759);
  
  // Background Colors
  static const Color backgroundPrimary = Color(0xFFF2F2F7);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color backgroundTertiary = Color(0xFFF2F2F7);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);
  
  // System Colors
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemYellow = Color(0xFFFFCC02);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [primaryTeal, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Theme Data
  static CupertinoThemeData get lightTheme => const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: backgroundPrimary,
    barBackgroundColor: backgroundSecondary,
    textTheme: CupertinoTextThemeData(
      primaryColor: textPrimary,
      textStyle: TextStyle(
        fontFamily: '.SF Pro Text',
        fontSize: 17,
        color: textPrimary,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontFamily: '.SF Pro Display',
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      navTitleTextStyle: TextStyle(
        fontFamily: '.SF Pro Text',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
  );
  
  // Custom Button Styles
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: primaryBlue.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get secondaryButtonDecoration => BoxDecoration(
    color: backgroundSecondary,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: primaryBlue.withOpacity(0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: CupertinoColors.systemGrey.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Input Field Styles
  static BoxDecoration get inputDecoration => BoxDecoration(
    color: backgroundSecondary,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: textTertiary,
      width: 1,
    ),
  );
  
  static BoxDecoration get focusedInputDecoration => BoxDecoration(
    color: backgroundSecondary,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: primaryBlue,
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: primaryBlue.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Card Styles
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: backgroundSecondary,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: CupertinoColors.systemGrey.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Text Styles
  static const TextStyle heroTitle = TextStyle(
    fontFamily: '.SF Pro Display',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle title1 = TextStyle(
    fontFamily: '.SF Pro Display',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle title2 = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  static const TextStyle headline = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  static const TextStyle body = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 17,
    color: textPrimary,
  );
  
  static const TextStyle caption = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 13,
    color: textSecondary,
  );
}
