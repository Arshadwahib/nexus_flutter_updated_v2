// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/admin_auth_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/reels/reels_screen.dart';
import '../screens/chat/conversations_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/home/post_detail_screen.dart';
import '../screens/home/create_post_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation.startsWith('/auth');

        if (!isAuthenticated && !isAuthRoute) {
          return '/auth/login';
        }
        if (isAuthenticated && isAuthRoute) {
          return '/';
        }
        return null;
      },
      refreshListenable: authProvider,
      routes: [
        // ─── Auth Routes ──────────────────────────────────────────────
        GoRoute(
          path: '/auth/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        // Hidden admin route — not visible in navigation
        GoRoute(
          path: '/auth/admin',
          name: 'admin-auth',
          builder: (context, state) => const AdminAuthScreen(),
        ),

        // ─── Main Shell (Bottom Nav) ──────────────────────────────────
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const FeedScreen(),
            ),
            GoRoute(
              path: '/explore',
              name: 'explore',
              builder: (context, state) => const ExploreScreen(),
            ),
            GoRoute(
              path: '/reels',
              name: 'reels',
              builder: (context, state) => const ReelsScreen(),
            ),
            GoRoute(
              path: '/messages',
              name: 'messages',
              builder: (context, state) => const ConversationsScreen(),
            ),
            GoRoute(
              path: '/profile',
              name: 'my-profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),

        // ─── Detail Routes ────────────────────────────────────────────
        GoRoute(
          path: '/post/:id',
          name: 'post-detail',
          builder: (context, state) => PostDetailScreen(
            postId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/profile/:username',
          name: 'user-profile',
          builder: (context, state) => ProfileScreen(
            username: state.pathParameters['username'],
          ),
        ),
        GoRoute(
          path: '/chat/:id',
          name: 'chat',
          builder: (context, state) => ChatScreen(
            conversationId: state.pathParameters['id']!,
            otherUserId: state.uri.queryParameters['userId'] ?? '',
            otherUsername: state.uri.queryParameters['username'] ?? '',
          ),
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/create',
          name: 'create-post',
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          name: 'edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/admin',
          name: 'admin-dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
          redirect: (context, state) {
            if (!authProvider.isAdmin) return '/';
            return null;
          },
        ),
      ],
    );
  }
}
