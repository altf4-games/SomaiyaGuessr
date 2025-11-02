import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Neo-Brutalism Color Palette
  static const Color backgroundPrimary = Color(0xFFFAF8F3); // Warm off-white
  static const Color backgroundSecondary = Color(0xFFF5F1E8); // Light cream
  static const Color backgroundTertiary = Color(0xFFFFFFFF); // Pure white

  // Bold Neo-Brutalism Colors
  static const Color brutalistYellow = Color(
    0xFFFFD60A,
  ); // Vibrant yellow (better contrast)
  static const Color brutalistPink = Color(0xFFFF006E); // Hot pink (deeper)
  static const Color brutalistCyan = Color(
    0xFF00B4D8,
  ); // Electric cyan (darker)
  static const Color brutalistGreen = Color(0xFF06FFA5); // Neon green
  static const Color brutalistOrange = Color(
    0xFFFF5400,
  ); // Bold orange (better contrast)
  static const Color brutalistPurple = Color(
    0xFF7209B7,
  ); // Vivid purple (darker)
  static const Color brutalistRed = Color(0xFFD90429); // Bold red (darker)
  static const Color brutalistBlue = Color(0xFF023E8A); // Bright blue (darker)

  // Primary accent
  static const Color primaryAccent = brutalistYellow;
  static const Color primaryAccentDark = Color(0xFFE6BD2A);

  // Status colors
  static const Color successGreen = brutalistGreen;
  static const Color errorRed = brutalistRed;
  static const Color warningOrange = brutalistOrange;
  static const Color infoBlue = brutalistCyan;

  // Text colors - High contrast for brutalism
  static const Color textPrimary = Color(0xFF000000); // Pure black
  static const Color textSecondary = Color(0xFF333333); // Dark gray
  static const Color textTertiary = Color(0xFF666666); // Medium gray

  // The signature neo-brutalism thick black border
  static const Color brutalistBorder = Color(0xFF000000); // Pure black
  static const double brutalistBorderWidth = 4.0;

  // Hard shadow offset for neo-brutalism (no blur!)
  static const double shadowOffset = 8.0;
  static const Color shadowColor = Color(0xFF000000);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light, // Neo-brutalism uses light backgrounds
      scaffoldBackgroundColor: AppColors.backgroundPrimary,
      primaryColor: AppColors.primaryAccent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryAccent,
        secondary: AppColors.brutalistPink,
        error: AppColors.errorRed,
        surface: AppColors.backgroundTertiary,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onError: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: AppColors.textPrimary,
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Sharp corners!
            side: const BorderSide(
              color: AppColors.brutalistBorder,
              width: AppColors.brutalistBorderWidth,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          elevation: 0, // No soft shadows in neo-brutalism
          overlayColor: Colors.black.withOpacity(0.1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            decoration: TextDecoration.underline,
            decorationThickness: 2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundTertiary,
        hintStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textTertiary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0), // Sharp corners
          borderSide: const BorderSide(
            color: AppColors.brutalistBorder,
            width: AppColors.brutalistBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(
            color: AppColors.brutalistBorder,
            width: AppColors.brutalistBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(
            color: AppColors.brutalistBorder,
            width: AppColors.brutalistBorderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: AppColors.brutalistBorderWidth,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0), // Sharp corners
          side: const BorderSide(
            color: AppColors.brutalistBorder,
            width: AppColors.brutalistBorderWidth,
          ),
        ),
        elevation: 0, // No soft elevation
        shadowColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.brutalistCyan,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 28),
      ),
    );
  }

  // Helper to create neo-brutalism box decoration
  static BoxDecoration brutalistContainer({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    bool addShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.backgroundTertiary,
      border: Border.all(
        color: borderColor ?? AppColors.brutalistBorder,
        width: borderWidth ?? AppColors.brutalistBorderWidth,
      ),
      borderRadius: BorderRadius.circular(0),
      boxShadow: addShadow
          ? [
              BoxShadow(
                color: AppColors.shadowColor,
                offset: const Offset(
                  AppColors.shadowOffset,
                  AppColors.shadowOffset,
                ),
                blurRadius: 0, // No blur for hard shadow!
              ),
            ]
          : null,
    );
  }

  // Helper for brutalist button decoration
  static BoxDecoration brutalistButton({
    required Color backgroundColor,
    Color? borderColor,
    bool addShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(
        color: borderColor ?? AppColors.brutalistBorder,
        width: AppColors.brutalistBorderWidth,
      ),
      borderRadius: BorderRadius.circular(0),
      boxShadow: addShadow
          ? [
              BoxShadow(
                color: AppColors.shadowColor,
                offset: const Offset(6, 6),
                blurRadius: 0,
              ),
            ]
          : null,
    );
  }
}
