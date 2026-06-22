// lib/screens/home/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nexus_logo.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _routes = ['/', '/explore', '/reels', '/messages', '/profile'];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifProvider = context.watch<NotificationProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: widget.child,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/create'),
              backgroundColor: isDark ? AppTheme.white : AppTheme.black,
              foregroundColor: isDark ? AppTheme.black : AppTheme.white,
              elevation: 2,
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.black : AppTheme.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.grey900 : AppTheme.grey200,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isActive: _currentIndex == 0,
                  onTap: () => _onNavTap(0),
                ),
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  isActive: _currentIndex == 1,
                  onTap: () => _onNavTap(1),
                ),
                _NavItem(
                  icon: Icons.slow_motion_video_rounded,
                  activeIcon: Icons.slow_motion_video_rounded,
                  isActive: _currentIndex == 2,
                  onTap: () => _onNavTap(2),
                ),
                _NavItem(
                  icon: Icons.mode_comment_outlined,
                  activeIcon: Icons.mode_comment_rounded,
                  isActive: _currentIndex == 3,
                  badge: notifProvider.unreadCount,
                  onTap: () => _onNavTap(3),
                ),
                _NavItem(
                  widget: authProvider.currentUser?.avatarUrl != null
                      ? CircleAvatar(
                          radius: 14,
                          backgroundImage:
                              NetworkImage(authProvider.currentUser!.avatarUrl!),
                        )
                      : CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              isDark ? AppTheme.grey800 : AppTheme.grey200,
                          child: Text(
                            authProvider.currentUser?.initials ?? '?',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                          ),
                        ),
                  isActive: _currentIndex == 4,
                  onTap: () => _onNavTap(4),
                  activeRing: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData? icon;
  final IconData? activeIcon;
  final Widget? widget;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;
  final bool activeRing;

  const _NavItem({
    this.icon,
    this.activeIcon,
    this.widget,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
    this.activeRing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content;
    if (widget != null) {
      content = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: activeRing && isActive ? const EdgeInsets.all(2) : EdgeInsets.zero,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: activeRing && isActive
              ? Border.all(
                  color: isDark ? AppTheme.white : AppTheme.black,
                  width: 2,
                )
              : null,
        ),
        child: widget!,
      );
    } else {
      content = AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isActive ? activeIcon ?? icon : icon,
          key: ValueKey(isActive),
          size: 26,
          color: isActive
              ? (isDark ? AppTheme.white : AppTheme.black)
              : (isDark ? AppTheme.grey600 : AppTheme.grey400),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            content,
            if (badge > 0)
              Positioned(
                top: 8,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
