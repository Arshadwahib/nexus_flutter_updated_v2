// lib/utils/constants.dart
// ⚠️  CONFIDENTIAL — Admin credentials. Do not commit to public repos.
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AppConstants {
  // ─── App Info ──────────────────────────────────────────────────────────
  static const String appName = 'Nexus';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your world, connected.';

  // ─── Supabase Config (free tier) ──────────────────────────────────────
  // Sign up free at https://supabase.com — replace with your project values
  static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // ─── Admin Credentials (hashed for security) ─────────────────────────
  // CONFIDENTIAL: Admin username and password known only to the app developer
  static const String _adminUsername = 'arshadwahib99';
  // Password hash (SHA-256 of the actual password — never store plaintext)
  static final String _adminPasswordHash = _hashPassword('wahibarshad99');

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyAdminCredentials(String username, String password) {
    final inputHash = _hashPassword(password);
    return username == _adminUsername && inputHash == _adminPasswordHash;
  }

  static String get adminUsername => _adminUsername;

  // ─── Storage Buckets ─────────────────────────────────────────────────
  static const String avatarsBucket = 'avatars';
  static const String postsBucket = 'posts';
  static const String reelsBucket = 'reels';
  static const String storiesBucket = 'stories';
  static const String chatMediaBucket = 'chat_media';

  // ─── Pagination ───────────────────────────────────────────────────────
  static const int feedPageSize = 20;
  static const int reelsPageSize = 10;
  static const int searchPageSize = 30;
  static const int chatPageSize = 50;
  static const int notificationsPageSize = 30;

  // ─── Content Limits ────────────────────────────────────────────────────
  static const int maxPostLength = 500;
  static const int maxBioLength = 160;
  static const int maxUsernameLength = 30;
  static const int maxCommentLength = 300;
  static const int maxStoryDuration = 15; // seconds
  static const int maxReelDuration = 90;  // seconds

  // ─── Feature Flags ─────────────────────────────────────────────────────
  static const bool storiesEnabled = true;
  static const bool reelsEnabled = true;
  static const bool liveEnabled = true;
  static const bool spacesEnabled = true;

  // ─── Notification Channels ─────────────────────────────────────────────
  static const String notifChannelId = 'nexus_main';
  static const String notifChannelName = 'Nexus Notifications';

  // ─── Regex ─────────────────────────────────────────────────────────────
  static final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp hashtagRegex = RegExp(r'#(\w+)');
  static final RegExp mentionRegex = RegExp(r'@(\w+)');
}
