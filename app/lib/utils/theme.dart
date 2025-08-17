import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Modern Dark Theme - Deep blacks with vibrant accents
  static const Color backgroundPrimary = Color(0xFF0A0A0A); // Almost black
  static const Color backgroundSecondary = Color(0xFF111111); // Dark gray
  static const Color backgroundTertiary = Color(0xFF1A1A1A); // Lighter dark
  static const Color backgroundCard = Color(0xFF1E1E1E); // Card background
  static const Color backgroundElevated = Color(0xFF252525); // Elevated surfaces

  // Primary accent - Electric cyan/blue gradient
  static const Color primaryAccent = Color(0xFF00D4FF); // Bright cyan
  static const Color primaryAccentDark = Color(0xFF0099CC);
  static const Color primaryGradientStart = Color(0xFF00D4FF);
  static const Color primaryGradientEnd = Color(0xFF7C3AED);

  // Status colors - Vibrant and modern
  static const Color successGreen = Color(0xFF00FF88); // Bright green
  static const Color errorRed = Color(0xFFFF3366); // Bright red
  static const Color warningOrange = Color(0xFFFFAA00); // Bright orange
  static const Color infoBlue = Color(0xFF00AAFF); // Bright blue

  // Text colors - High contrast
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFFB3B3B3); // Light gray
  static const Color textTertiary = Color(0xFF666666); // Medium gray
  static const Color textMuted = Color(0xFF404040); // Dark gray

  // Border and divider colors
  static const Color borderLight = Color(0xFF2A2A2A);
  static const Color borderMedium = Color(0xFF333333);
  static const Color borderDark = Color(0xFF1A1A1A);

  // Additional accent colors
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF97316);

  // Glassmorphism effect
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      primaryColor: AppColors.primaryAccent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.successGreen,
        error: AppColors.errorRed,
        surface: AppColors.backgroundCard,
        onPrimary: AppColors.backgroundPrimary,
        onSecondary: AppColors.backgroundPrimary,
        onError: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.backgroundPrimary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCard,
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textTertiary,
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}
