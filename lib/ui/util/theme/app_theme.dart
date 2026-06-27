import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import 'app_text_styles.dart';
import 'special_app_theme.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoPageTransitionsBuilder;

class AppTheme {
  static ThemeData get light => getTheme(AppThemeMode.orange);

  static ThemeData getTheme(
    AppThemeMode mode, {
    Color? customPrimary,
    Color? customDark,
    bool? customUseGradient,
  }) {
    Color primaryColor;
    Color primaryDarkColor;
    Gradient? primaryGradient;
    bool useGradient;

    switch (mode) {
      case AppThemeMode.hologram:
        primaryColor = const Color(0xFF8EC5FC);
        primaryDarkColor = const Color(0xFFE0C3FC);
        primaryGradient = AppColors.hologramGradient;
        useGradient = true;
        break;
      case AppThemeMode.rainbow:
        primaryColor = Colors.blue;
        primaryDarkColor = Colors.indigo;
        primaryGradient = AppColors.rainbowGradient;
        useGradient = true;
        break;
      case AppThemeMode.orange:
        primaryColor = AppColors.primary;
        primaryDarkColor = AppColors.primaryDark;
        primaryGradient = null;
        useGradient = false;
        break;
      case AppThemeMode.army:
        primaryColor = const Color(0xFF4B5320);
        primaryDarkColor = const Color(0xFF2E3B34);
        primaryGradient = const LinearGradient(
          colors: [
            Color(0xFF4B5320),
            Color(0xFF2E3B34),
            Color(0xFF3F4E3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        useGradient = true;
        break;
      case AppThemeMode.custom:
        primaryColor = customPrimary ?? const Color(0xFF9C27B0);
        primaryDarkColor = customDark ?? const Color(0xFF673AB7);
        useGradient = customUseGradient ?? true;
        primaryGradient = useGradient
            ? LinearGradient(
                colors: [primaryColor, primaryDarkColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null;
        break;
    }

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: AppColors.tactical,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.sectionTitle,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44, 48),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: primaryColor, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      extensions: [
        SpecialAppTheme(
          primaryColor: primaryColor,
          primaryDarkColor: primaryDarkColor,
          primaryGradient: primaryGradient,
          useGradient: useGradient,
        ),
      ],
    );
  }
}
