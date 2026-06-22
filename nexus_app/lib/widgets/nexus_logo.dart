// lib/widgets/nexus_logo.dart
import 'package:flutter/material.dart';

/// NexusLogo — shows the real NEXUS brand image from assets.
/// Falls back to styled text if the image fails to load.
/// The source image is 628×218 px (ratio ≈ 2.88 : 1).
class NexusLogo extends StatelessWidget {
  final double size;
  const NexusLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final double width = size * 2.88;
    return Image.asset(
      'assets/images/nexus_logo.jpg',
      width: width,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackLogo(size: size),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final double size;
  const _FallbackLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'N',
            style: TextStyle(
              fontSize: size * 0.9,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: const Color(0xFF3a6bc4),
            ),
          ),
          TextSpan(
            text: 'EXUS',
            style: TextStyle(
              fontSize: size * 0.9,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
