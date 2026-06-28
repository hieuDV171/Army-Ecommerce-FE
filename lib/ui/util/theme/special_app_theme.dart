import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum AppThemeMode { orange, hologram, rainbow, army, custom }

class SpecialAppTheme extends ThemeExtension<SpecialAppTheme> {
  final Color primaryColor;
  final Color primaryDarkColor;
  final Gradient? primaryGradient;
  final bool useGradient;

  const SpecialAppTheme({
    required this.primaryColor,
    required this.primaryDarkColor,
    this.primaryGradient,
    required this.useGradient,
  });

  @override
  SpecialAppTheme copyWith({
    Color? primaryColor,
    Color? primaryDarkColor,
    Gradient? primaryGradient,
    bool? useGradient,
  }) {
    return SpecialAppTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      primaryDarkColor: primaryDarkColor ?? this.primaryDarkColor,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      useGradient: useGradient ?? this.useGradient,
    );
  }

  @override
  SpecialAppTheme lerp(ThemeExtension<SpecialAppTheme>? other, double t) {
    if (other is! SpecialAppTheme) return this;
    return SpecialAppTheme(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      primaryDarkColor: Color.lerp(
        primaryDarkColor,
        other.primaryDarkColor,
        t,
      )!,
      primaryGradient: Gradient.lerp(primaryGradient, other.primaryGradient, t),
      useGradient: t < 0.5 ? useGradient : other.useGradient,
    );
  }
}

extension SpecialThemeBuildContext on BuildContext {
  SpecialAppTheme get specialTheme =>
      Theme.of(this).extension<SpecialAppTheme>() ??
      const SpecialAppTheme(
        primaryColor: AppColors.primary,
        primaryDarkColor: AppColors.primaryDark,
        useGradient: false,
      );
}
