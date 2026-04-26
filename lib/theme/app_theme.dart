import 'package:flutter/material.dart';

/// Centralized color definitions for the entire app.
/// All screens should import this instead of defining local _C classes.
class AppThemeColors {
  // Brand
  static const Color pink = Color(0xFFFF4D6D);
  static const Color pinkLight = Color(0xFFFF6B8A);
  static const Color pinkBg = Color(0xFFFFF0F3);
  static const Color pinkDark = Color(0xFFE8446A);
  static const Color pinkRose = Color(0xFFE8567C);

  // Blue
  static const Color blue = Color(0xFF5BA8E0);
  static const Color blueBg = Color(0xFFE3F2FD);
  static const Color blueMid = Color(0xFF6C7AE0);
  static const Color blueDeep = Color(0xFF4A5AC7);

  // Mint / Teal
  static const Color mint = Color(0xFF7DD6B8);
  static const Color mintBg = Color(0xFFE0F7F0);
  static const Color mintAlt = Color(0xFF4CD9A0);
  static const Color teal = Color(0xFF2EC4B6);

  // Yellow / Gold
  static const Color yellow = Color(0xFFFFD580);
  static const Color yellowBg = Color(0xFFFFF8E7);
  static const Color yellowAlt = Color(0xFFFFBE45);
  static const Color gold = Color(0xFFFFCA42);
  static const Color goldDark = Color(0xFFFFB830);

  // Orange
  static const Color orange = Color(0xFFFF9B50);
  static const Color orangeBg = Color(0xFFFFF3E8);
  static const Color orangeDeep = Color(0xFFFF8845);

  // Green
  static const Color green = Color(0xFF4CAF50);
  static const Color greenBg = Color(0xFFE8F5E9);
  static const Color greenBright = Color(0xFF66BB6A);
  static const Color greenDark = Color(0xFF43A047);

  // Red
  static const Color red = Color(0xFFE53935);
  static const Color redBg = Color(0xFFFFEBEE);

  // Purple
  static const Color purple = Color(0xFF7E57C2);

  // Neutrals — Light mode
  static const Color background = Color(0xFFF5F7FA);
  static const Color scaffoldAlt = Color(0xFFFAF7F9);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF2D2D2D);
  static const Color darkTextAlt = Color(0xFF1E1E2C);
  static const Color greyText = Color(0xFF9E9E9E);
  static const Color mutedText = Color(0xFF8A8A9E);
  static const Color border = Color(0xFFEDE8EB);
  static const Color inputBorder = Color(0xFFE8ECF0);
  static const Color inputBg = Color(0xFFFFFFFF);
  static const Color inputIconBg = Color(0xFFF0F4F8);

  // Neutrals — Dark mode
  static const Color darkBackground = Color(0xFF121218);
  static const Color darkSurface = Color(0xFF1E1E2C);
  static const Color darkCard = Color(0xFF252535);
  static const Color darkBorder = Color(0xFF3A3A4A);
  static const Color darkInputBg = Color(0xFF2A2A3A);
  static const Color lightText = Color(0xFFF0F0F5);
  static const Color lightGreyText = Color(0xFFB0B0C0);

  // Radar orbit colors
  static const Color ringLight = Color(0xFFE4EEF5);
  static const Color ringMid = Color(0xFFD4DCF0);

  // Profile-specific
  static const Color beige = Color(0xFFF5E6D8);
  static const Color tan = Color(0xFFD4A574);
  static const Color lightPinkBg = Color(0xFFF9F6F8);
  static const Color greyLight = Color(0xFFD4D4D4);
  static const Color greyMedium = Color(0xFFBBBBBB);
  static const Color profileBorder = Color(0xFFE8E0E4);

  // Donation flow
  static const Color pinkAlt = Color(0xFFE85475);
  static const Color pinkFade1 = Color(0xFFFBCDD5);
  static const Color pinkFade2 = Color(0xFFF8A4B8);
  static const Color coral = Color(0xFFFF7EA1);
}

/// Light theme
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppThemeColors.background,
  colorScheme: const ColorScheme.light(
    primary: AppThemeColors.pink,
    secondary: AppThemeColors.blue,
    surface: AppThemeColors.cardBg,
    error: AppThemeColors.red,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppThemeColors.background,
    foregroundColor: AppThemeColors.darkText,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: AppThemeColors.cardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppThemeColors.cardBg,
    selectedItemColor: AppThemeColors.pink,
    unselectedItemColor: AppThemeColors.greyText,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppThemeColors.pink,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

/// Dark theme
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppThemeColors.darkBackground,
  colorScheme: const ColorScheme.dark(
    primary: AppThemeColors.pinkLight,
    secondary: AppThemeColors.blue,
    surface: AppThemeColors.darkCard,
    error: AppThemeColors.red,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppThemeColors.darkBackground,
    foregroundColor: AppThemeColors.lightText,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: AppThemeColors.darkCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppThemeColors.darkSurface,
    selectedItemColor: AppThemeColors.pinkLight,
    unselectedItemColor: AppThemeColors.lightGreyText,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppThemeColors.pinkLight,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
