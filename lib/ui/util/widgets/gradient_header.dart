import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/special_app_theme.dart';

class GradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final specialTheme = context.specialTheme;
    final gradient = specialTheme.useGradient
        ? specialTheme.primaryGradient
        : LinearGradient(
            colors: [specialTheme.primaryColor, specialTheme.primaryDarkColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
      ),
      child: child,
    );
  }
}
