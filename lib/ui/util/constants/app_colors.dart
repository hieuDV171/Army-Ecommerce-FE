import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFFF5A1F);
  static const primaryDark = Color(0xFFE83A14);
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const tactical = Color(0xFF263238);

  // Additional colors used in components
  static const greyBackground = Color(0xFFF5F5F5);
  static const unreadBackground = Color(0xFFFFF3F0);
  static const info = Color(0xFF1E88E5);
  static const purple = Color(0xFF8E24AA);
  static const successDark = Color(0xFF2E7D32);
  static const greyDivider = Color(0xFFE0E0E0);
  static const greyLight = Color(0xFFEEEEEE);
  static const primaryUltraLight = Color(0xFFFFEBE8);
  static const greyLightest = Color(0xFFF0F0F0);

  // WhatsApp/Online green
  static const onlineGreen = Color(0xFF24D366);
  static const onlineGreenGlow = Color(0x6624D366);

  // Reward/Info panel colors
  static const infoBlue = Color(0xFF1565C0);
  static const infoBlueDark = Color(0xFF0D47A1);

  // Code block theme colors
  static const codeBackground = Color(0xFF1E1E1E);
  static const codeComment = Color(0xFF6A9955);
  static const codeString = Color(0xFFCE9178);

  // Gradient themes for holidays
  static const hologramGradient = LinearGradient(
    colors: [
      Color(0xFFE0C3FC),
      Color(0xFF8EC5FC),
      Color(0xFFFBC2EB),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const rainbowGradient = LinearGradient(
    colors: [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
