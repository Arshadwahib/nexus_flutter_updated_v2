// lib/widgets/user_avatar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool showBorder;
  final bool hasStory;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 20,
    this.showBorder = false,
    this.hasStory = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => _placeholder(isDark),
        errorWidget: (ctx, url, err) => _placeholder(isDark),
      );
    } else {
      avatar = _placeholder(isDark);
    }

    Widget circle = ClipOval(
      child: SizedBox(width: radius * 2, height: radius * 2, child: avatar),
    );

    if (hasStory) {
      circle = Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF4ECDC4)],
          ),
          shape: BoxShape.circle,
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.black : AppTheme.white,
            shape: BoxShape.circle,
          ),
          child: circle,
        ),
      );
    } else if (showBorder) {
      circle = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppTheme.grey800 : AppTheme.grey200,
            width: 1,
          ),
          shape: BoxShape.circle,
        ),
        child: circle,
      );
    }

    return circle;
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark ? AppTheme.grey800 : AppTheme.grey200,
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: isDark ? AppTheme.grey400 : AppTheme.grey500,
            fontSize: radius * 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
