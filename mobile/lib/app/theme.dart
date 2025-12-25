import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AirMass Design System Colors
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFEE456B);
  static const Color primaryDark = Color(0xFFD63054);
  static const Color secondary = Color(0xFFFF8322);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF8F6F6);
  static const Color backgroundDark = Color(0xFF221014);
  
  // Surface Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2D1B20);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF181112);
  static const Color textPrimaryDark = Color(0xFFF8F6F6);
  static const Color textSecondaryLight = Color(0xFF89616A);
  static const Color textSecondaryDark = Color(0xFFD1B3B9);
  
  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Border Colors
  static const Color borderLight = Color(0xFFE6DBDD);
  static const Color borderDark = Color(0xFF4A2E36);
  
  // Urgency (for timers)
  static const Color urgency = Color(0xFFFF8322);
}

/// AirMass Typography
class AppTypography {
  static String get fontFamily => 'PlusJakartaSans';
  
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );
  
  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );
  
  static TextStyle get displaySmall => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );
  
  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  
  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}

/// AirMass Theme
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimaryLight),
      displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimaryLight),
      displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimaryLight),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimaryLight),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimaryLight),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimaryLight),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryLight),
      titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textPrimaryLight),
      titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textPrimaryLight),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryLight),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimaryLight),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimaryLight),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight),
      labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryLight),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.primary),
        textStyle: AppTypography.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight.withValues(alpha: 0.6)),
      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedColor: AppColors.textPrimaryLight,
      labelStyle: AppTypography.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100),
        side: const BorderSide(color: AppColors.borderLight),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimaryDark),
      displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimaryDark),
      displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimaryDark),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimaryDark),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimaryDark),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimaryDark),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryDark),
      titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textPrimaryDark),
      titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textPrimaryDark),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryDark),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryDark),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimaryDark),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryDark),
      labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryDark),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryDark),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.3)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTypography.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark.withValues(alpha: 0.5)),
      labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
