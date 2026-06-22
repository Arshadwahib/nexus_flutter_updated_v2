// lib/widgets/nexus_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NexusButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final bool outlined;
  final IconData? icon;
  final double? width;

  const NexusButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.outlined = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined
                  ? (color ?? (isDark ? AppTheme.white : AppTheme.black))
                  : (textColor ?? (isDark ? AppTheme.black : AppTheme.white)),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (width != null) {
      child = SizedBox(width: width, child: Center(child: child));
    }

    if (outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? (isDark ? AppTheme.white : AppTheme.black),
          side: BorderSide(
            color: color ?? (isDark ? AppTheme.grey700 : AppTheme.grey200),
            width: 1.5,
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? (isDark ? AppTheme.white : AppTheme.black),
        foregroundColor:
            textColor ?? (isDark ? AppTheme.black : AppTheme.white),
        minimumSize: const Size(double.infinity, 52),
      ),
      child: child,
    );
  }
}
