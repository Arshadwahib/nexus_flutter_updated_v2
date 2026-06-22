// lib/services/follow_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class FollowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    final data = await _supabase
        .from('follows')
        .select('id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return data != null;
  }

  Future<void> followUser({
    required String followerId,
    required String followingId,
    required bool isPrivateAccount,
  }) async {
    if (isPrivateAccount) {
      // Create follow request
      await _supabase.from('follow_requests').insert({
        'requester_id': followerId,
        'target_id': followingId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      await _createNotification(userId: followingId, type: 'followRequest', actorId: followerId);
    } else {
      // Direct follow
      await _supabase.from('follows').insert({
        'follower_id': followerId,
        'following_id': followingId,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _supabase.rpc('increment_followers_count', params: {'user_id': followingId});
      await _supabase.rpc('increment_following_count', params: {'user_id': followerId});
      await _createNotification(userId: followingId, type: 'follow', actorId: followerId);
    }
  }

  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
    await _supabase.rpc('decrement_followers_count', params: {'user_id': followingId});
    await _supabase.rpc('decrement_following_count', params: {'user_id': followerId});
  }

  Future<List<UserModel>> fetchFollowers(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('follower:profiles!follower_id(*)')
        .eq('following_id', userId);
    return (data as List)
        .map((d) => UserModel.fromJson(d['follower'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserModel>> fetchFollowing(String userId) async {
    final data = await _supabase
        .from('follows')
        .select('following:profiles!following_id(*)')
        .eq('follower_id', userId);
    return (data as List)
        .map((d) => UserModel.fromJson(d['following'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserModel>> getSuggestedUsers(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select('*')
        .neq('id', userId)
        .eq('is_active', true)
        .order('followers_count', ascending: false)
        .limit(20);
    return (data as List).map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final data = await _supabase
        .from('profiles')
        .select('*')
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .eq('is_active', true)
        .limit(30);
    return (data as List).map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> _createNotification({
    required String userId,
    required String type,
    required String actorId,
  }) async {
    if (userId == actorId) return;
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'actor_id': actorId,
      'is_read': false,
      'message': '',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
