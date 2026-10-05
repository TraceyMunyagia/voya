import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData light() => _build(_lightScheme);
  static ThemeData dark() => _build(_darkScheme);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.navy,
    onPrimary: Colors.white,
    primaryContainer: AppColors.sand,
    onPrimaryContainer: AppColors.navy,
    secondary: AppColors.coral,
    onSecondary: AppColors.onCoral,
    secondaryContainer: AppColors.sand,
    onSecondaryContainer: AppColors.navy,
    tertiary: AppColors.success,
    onTertiary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.offWhite,
    onSurface: AppColors.charcoal,
    onSurfaceVariant: AppColors.mist,
    outline: Color(0xFFD9CDB8),
    outlineVariant: AppColors.sand,
  );

  // Derived from the brand colours; your palette didn't define dark mode.
  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.sand,
    onPrimary: AppColors.navy,
    primaryContainer: AppColors.navy,
    onPrimaryContainer: AppColors.sand,
    secondary: AppColors.coral,
    onSecondary: AppColors.onCoral,
    secondaryContainer: AppColors.navy,
    onSecondaryContainer: AppColors.sand,
    tertiary: AppColors.success,
    onTertiary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.darkBackground,
    onSurface: AppColors.offWhite,
    onSurfaceVariant: Color(0xFFB5C0CB),
    outline: Color(0xFF2D4660),
    outlineVariant: AppColors.navy,
  );

  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      // Navy header in both modes
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      // Sand cards (trip cards, itinerary sections)
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? AppColors.sand : AppColors.navy,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      // Every filled button is coral (Create Trip, Make This Trip Mine, ...)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: AppColors.onCoral,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: shape,
        ),
      ),
      // Secondary actions are navy outlines
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          minimumSize: const Size.fromHeight(48),
          shape: shape,
        ),
      ),
      // Navy bottom navigation with a coral active indicator
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navy,
        indicatorColor: AppColors.coral,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70,
          ),
        ),
      ),
    );
  }
}
