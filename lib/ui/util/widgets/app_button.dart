import 'package:flutter/material.dart';
import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final specialTheme = context.specialTheme;
    final isEnabled = onPressed != null && !isLoading;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: specialTheme.useGradient ? Colors.transparent : null,
      shadowColor: specialTheme.useGradient ? Colors.transparent : null,
      elevation: specialTheme.useGradient ? 0 : null,
    );

    Widget innerButton = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );

    if (specialTheme.useGradient) {
      return Container(
        decoration: BoxDecoration(
          gradient: isEnabled ? specialTheme.primaryGradient : null,
          color: isEnabled ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: innerButton,
      );
    }

    return innerButton;
  }
}
