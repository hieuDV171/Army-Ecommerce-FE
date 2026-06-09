import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final AppThemeMode themeMode;
  final Color customPrimaryColor;
  final Color customDarkColor;
  final bool customUseGradient;

  const ThemeState({
    required this.themeMode,
    required this.customPrimaryColor,
    required this.customDarkColor,
    required this.customUseGradient,
  });

  ThemeState copyWith({
    AppThemeMode? themeMode,
    Color? customPrimaryColor,
    Color? customDarkColor,
    bool? customUseGradient,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
      customDarkColor: customDarkColor ?? this.customDarkColor,
      customUseGradient: customUseGradient ?? this.customUseGradient,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          customPrimaryColor == other.customPrimaryColor &&
          customDarkColor == other.customDarkColor &&
          customUseGradient == other.customUseGradient;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      customPrimaryColor.hashCode ^
      customDarkColor.hashCode ^
      customUseGradient.hashCode;
}

class ThemeCubit extends Cubit<ThemeState> {
  static const String _keyThemeMode = "theme_mode";
  static const String _keyCustomPrimary = "theme_custom_primary";
  static const String _keyCustomDark = "theme_custom_dark";
  static const String _keyCustomUseGradient = "theme_custom_use_gradient";

  ThemeCubit({
    required AppThemeMode initialTheme,
    required Color initialCustomPrimary,
    required Color initialCustomDark,
    required bool initialCustomUseGradient,
  }) : super(ThemeState(
          themeMode: initialTheme,
          customPrimaryColor: initialCustomPrimary,
          customDarkColor: initialCustomDark,
          customUseGradient: initialCustomUseGradient,
        ));

  Future<void> setTheme(AppThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, mode.name);
    } catch (_) {}
  }

  Future<void> setCustomTheme({
    required Color primary,
    required Color dark,
    required bool useGradient,
  }) async {
    emit(state.copyWith(
      themeMode: AppThemeMode.custom,
      customPrimaryColor: primary,
      customDarkColor: dark,
      customUseGradient: useGradient,
    ));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, AppThemeMode.custom.name);
      await prefs.setInt(_keyCustomPrimary, primary.toARGB32());
      await prefs.setInt(_keyCustomDark, dark.toARGB32());
      await prefs.setBool(_keyCustomUseGradient, useGradient);
    } catch (_) {}
  }
}
