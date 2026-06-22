// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Current User ───────────────────────────────────────────────────
  User? get currentAuthUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  bool get isLoggedIn => currentAuthUser != null;
  String? get currentUserId => currentAuthUser?.id;

  // ─── Regular Sign Up ────────────────────────────────────────────────
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    // Validate username uniqueness
    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    if (existing != null) {
      throw Exception('Username already taken. Please choose another.');
    }

    // Create auth user
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': displayName,
        'is_admin': false,
        'role': 'user',
      },
    );

    if (response.user == null) {
      throw Exception('Sign up failed. Please try again.');
    }

    // Create profile
    final profileData = {
      'id': response.user!.id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'is_verified': false,
      'is_admin': false,
      'role': 'user',
      'followers_count': 0,
      'following_count': 0,
      'posts_count': 0,
      'is_private': false,
      'is_active': true,
      'interests': [],
      'notifications_enabled': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('profiles').insert(profileData);

    return UserModel.fromJson({...profileData, 'created_at': DateTime.now().toIso8601String()});
  }

  // ─── Admin Sign Up ───────────────────────────────────────────────────
  // CONFIDENTIAL: Secret admin signup — only accessible via hidden entry point
  Future<UserModel> adminSignUp({
    required String email,
    required String password,
    required String adminUsername,
    required String adminSecret,
  }) async {
    // Verify admin credentials (username + secret password)
    if (!AppConstants.verifyAdminCredentials(adminUsername, adminSecret)) {
      throw Exception('Invalid admin credentials. Access denied.');
    }

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': adminUsername,
        'display_name': adminUsername,
        'is_admin': true,
        'role': 'admin',
      },
    );

    if (response.user == null) {
      throw Exception('Admin sign up failed.');
    }

    final profileData = {
      'id': response.user!.id,
      'email': email,
      'username': adminUsername,
      'display_name': adminUsername,
      'is_verified': true,  // Admins auto-verified
      'is_admin': true,
      'role': 'admin',
      'followers_count': 0,
      'following_count': 0,
      'posts_count': 0,
      'is_private': false,
      'is_active': true,
      'interests': [],
      'notifications_enabled': true,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('profiles').insert(profileData);

    return UserModel.fromJson(profileData);
  }

  // ─── Sign In ─────────────────────────────────────────────────────────
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Invalid email or password.');
    }

    return await getUserProfile(response.user!.id);
  }

  // ─── Admin Login ─────────────────────────────────────────────────────
  // CONFIDENTIAL: Admin login validates extra admin credentials
  Future<UserModel> adminSignIn({
    required String email,
    required String password,
    required String adminUsername,
    required String adminSecret,
  }) async {
    // Verify the secret admin credentials first
    if (!AppConstants.verifyAdminCredentials(adminUsername, adminSecret)) {
      throw Exception('Invalid admin credentials. Access denied.');
    }

    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Invalid email or password.');
    }

    final user = await getUserProfile(response.user!.id);
    if (!user.isAdmin) {
      await _supabase.auth.signOut();
      throw Exception('This account does not have admin privileges.');
    }

    return user;
  }

  // ─── Get Profile ─────────────────────────────────────────────────────
  Future<UserModel> getUserProfile(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    return UserModel.fromJson(data);
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─── Password Reset ───────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // ─── Update Profile ───────────────────────────────────────────────────
  Future<UserModel> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? website,
    String? location,
    bool? isPrivate,
    List<String>? interests,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (website != null) updates['website'] = website;
    if (location != null) updates['location'] = location;
    if (isPrivate != null) updates['is_private'] = isPrivate;
    if (interests != null) updates['interests'] = interests;
    updates['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('profiles').update(updates).eq('id', userId);
    return await getUserProfile(userId);
  }

  // ─── Admin: Grant Blue Tick ───────────────────────────────────────────
  Future<void> grantVerification(String targetUserId, bool verified) async {
    final currentUser = await getUserProfile(currentUserId!);
    if (!currentUser.isAdmin) throw Exception('Not authorized.');

    await _supabase
        .from('profiles')
        .update({'is_verified': verified, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', targetUserId);

    // Send notification
    await _supabase.from('notifications').insert({
      'user_id': targetUserId,
      'type': verified ? 'verifiedBadge' : 'adminAction',
      'actor_id': currentUserId,
      'message': verified
          ? 'Congratulations! You\'ve been awarded a verified badge. ✓'
          : 'Your verified badge has been removed.',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Delete Account ───────────────────────────────────────────────────
  Future<void> deleteAccount(String userId) async {
    await _supabase.from('profiles').update({'is_active': false}).eq('id', userId);
    await _supabase.auth.signOut();
  }
}
