// lib/widgets/verified_badge.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VerifiedBadge extends StatelessWidget {
  final bool isAdmin;
  final double size;

  const VerifiedBadge({super.key, this.isAdmin = false, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified_rounded,
      color: isAdmin ? const Color(0xFFFFD700) : AppTheme.accent,
      size: size,
    );
  }
}
