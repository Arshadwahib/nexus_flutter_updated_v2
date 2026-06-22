// lib/services/post_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../utils/constants.dart';

class PostService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Fetch Feed ──────────────────────────────────────────────────────
  Future<List<PostModel>> fetchHomeFeed({
    required String userId,
    int page = 0,
    PostType? filterType,
  }) async {
    var query = _supabase
        .from('posts')
        .select('''
          *,
          author:profiles!author_id(
            id, username, display_name, avatar_url, is_verified, is_admin
          ),
          repost_of:posts!repost_of_id(
            *,
            author:profiles!author_id(
              id, username, display_name, avatar_url, is_verified, is_admin
            )
          ),
          user_likes:post_likes!inner(user_id),
          user_reposts:post_reposts!inner(user_id),
          user_bookmarks:post_bookmarks!inner(user_id)
        ''')
        .eq('is_deleted', false)
        .or('visibility.eq.everyone,and(visibility.eq.followers,author_id.in.(${_getFollowingSubquery(userId)}))')
        .order('created_at', ascending: false)
        .range(page * AppConstants.feedPageSize, (page + 1) * AppConstants.feedPageSize - 1);

    if (filterType != null) {
      query = query.eq('type', filterType.name) as dynamic;
    }

    final data = await query;
    return (data as List).map((json) {
      final post = json as Map<String, dynamic>;
      post['is_liked'] = (post['user_likes'] as List?)?.isNotEmpty ?? false;
      post['is_reposted'] = (post['user_reposts'] as List?)?.isNotEmpty ?? false;
      post['is_bookmarked'] = (post['user_bookmarks'] as List?)?.isNotEmpty ?? false;
      return PostModel.fromJson(post);
    }).toList();
  }

  String _getFollowingSubquery(String userId) =>
      'SELECT following_id FROM follows WHERE follower_id = \'$userId\'';

  // ─── Fetch Explore / Trending ─────────────────────────────────────────
  Future<List<PostModel>> fetchExplorePosts({int page = 0}) async {
    final data = await _supabase
        .from('posts')
        .select('''
          *,
          author:profiles!author_id(id, username, display_name, avatar_url, is_verified, is_admin)
        ''')
        .eq('is_deleted', false)
        .eq('visibility', 'everyone')
        .order('likes_count', ascending: false)
        .order('created_at', ascending: false)
        .range(page * AppConstants.feedPageSize, (page + 1) * AppConstants.feedPageSize - 1);

    return (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ─── Fetch Reels ──────────────────────────────────────────────────────
  Future<List<PostModel>> fetchReels({int page = 0}) async {
    final data = await _supabase
        .from('posts')
        .select('''
          *,
          author:profiles!author_id(id, username, display_name, avatar_url, is_verified, is_admin)
        ''')
        .eq('type', 'reel')
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .range(page * AppConstants.reelsPageSize, (page + 1) * AppConstants.reelsPageSize - 1);

    return (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ─── Fetch Stories ────────────────────────────────────────────────────
  Future<List<PostModel>> fetchStories({required String userId}) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
    final data = await _supabase
        .from('posts')
        .select('''
          *,
          author:profiles!author_id(id, username, display_name, avatar_url, is_verified, is_admin)
        ''')
        .eq('type', 'story')
        .gt('created_at', cutoff)
        .order('created_at', ascending: false);

    return (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ─── Fetch User Posts ─────────────────────────────────────────────────
  Future<List<PostModel>> fetchUserPosts({
    required String userId,
    bool includeReplies = false,
    bool mediaOnly = false,
    int page = 0,
  }) async {
    var query = _supabase
        .from('posts')
        .select('''
          *,
          author:profiles!author_id(id, username, display_name, avatar_url, is_verified, is_admin)
        ''')
        .eq('author_id', userId)
        .eq('is_deleted', false);

    if (!includeReplies) {
      query = query.is_('reply_to_id', null) as dynamic;
    }
    if (mediaOnly) {
      query = query.not('media', 'is', null) as dynamic;
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(page * AppConstants.feedPageSize, (page + 1) * AppConstants.feedPageSize - 1);

    return (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ─── Create Post ──────────────────────────────────────────────────────
  Future<PostModel> createPost({
    required String authorId,
    required PostType type,
    String? text,
    List<File>? mediaFiles,
    List<String>? pollOptions,
    DateTime? pollExpiresAt,
    PostVisibility visibility = PostVisibility.everyone,
    String? replyToId,
    String? location,
  }) async {
    final postId = 'post_${DateTime.now().millisecondsSinceEpoch}';

    // Upload media
    final List<Map<String, dynamic>> mediaData = [];
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      for (final file in mediaFiles) {
        final ext = file.path.split('.').last;
        final path = '$authorId/$postId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        final bucket = type == PostType.reel ? AppConstants.reelsBucket
            : type == PostType.story ? AppConstants.storiesBucket
            : AppConstants.postsBucket;
        await _supabase.storage.from(bucket).upload(path, file);
        final url = _supabase.storage.from(bucket).getPublicUrl(path);
        mediaData.add({
          'url': url,
          'is_video': ext == 'mp4' || ext == 'mov' || ext == 'avi',
        });
      }
    }

    // Extract hashtags & mentions
    final hashtags = AppConstants.hashtagRegex
        .allMatches(text ?? '')
        .map((m) => m.group(1)!)
        .toList();
    final mentions = AppConstants.mentionRegex
        .allMatches(text ?? '')
        .map((m) => m.group(1)!)
        .toList();

    // Story auto-expires in 24h
    DateTime? expiresAt;
    if (type == PostType.story) {
      expiresAt = DateTime.now().add(const Duration(hours: 24));
    }

    final postData = {
      'author_id': authorId,
      'type': type.name,
      'text': text,
      'media': mediaData,
      'poll_options': pollOptions?.asMap().entries.map((e) => {
        'id': 'opt_${e.key}',
        'text': e.value,
        'vote_count': 0,
      }).toList(),
      'poll_expires_at': pollExpiresAt?.toIso8601String(),
      'visibility': visibility.name,
      'reply_to_id': replyToId,
      'hashtags': hashtags,
      'mentions': mentions,
      'location': location,
      'likes_count': 0,
      'comments_count': 0,
      'reposts_count': 0,
      'views_count': 0,
      'shares_count': 0,
      'bookmarks_count': 0,
      'is_deleted': false,
      'is_pinned': false,
      'is_edited': false,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };

    final result = await _supabase.from('posts').insert(postData).select().single();

    // Update posts count
    await _supabase.rpc('increment_posts_count', params: {'user_id': authorId});

    // Notify mentions
    for (final mention in mentions) {
      final mentionedUser = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', mention)
          .maybeSingle();
      if (mentionedUser != null) {
        await _createNotification(
          userId: mentionedUser['id'] as String,
          type: 'mention',
          actorId: authorId,
          postId: result['id'] as String,
        );
      }
    }

    return PostModel.fromJson({
      ...result,
      'author': await _supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url, is_verified, is_admin')
          .eq('id', authorId)
          .single(),
    });
  }

  // ─── Like / Unlike ────────────────────────────────────────────────────
  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    if (currentlyLiked) {
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      await _supabase.rpc('decrement_likes_count', params: {'post_id': postId});
    } else {
      await _supabase
          .from('post_likes')
          .insert({'post_id': postId, 'user_id': userId});
      await _supabase.rpc('increment_likes_count', params: {'post_id': postId});
    }
  }

  // ─── Repost ───────────────────────────────────────────────────────────
  Future<void> toggleRepost({
    required String postId,
    required String userId,
    required bool currentlyReposted,
  }) async {
    if (currentlyReposted) {
      await _supabase
          .from('post_reposts')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
      await _supabase.rpc('decrement_reposts_count', params: {'post_id': postId});
    } else {
      await _supabase
          .from('post_reposts')
          .insert({'post_id': postId, 'user_id': userId, 'created_at': DateTime.now().toIso8601String()});
      await _supabase.rpc('increment_reposts_count', params: {'post_id': postId});
    }
  }

  // ─── Bookmark ─────────────────────────────────────────────────────────
  Future<void> toggleBookmark({
    required String postId,
    required String userId,
    required bool currentlyBookmarked,
  }) async {
    if (currentlyBookmarked) {
      await _supabase
          .from('post_bookmarks')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await _supabase.from('post_bookmarks').insert({
        'post_id': postId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ─── Delete Post ──────────────────────────────────────────────────────
  Future<void> deletePost({required String postId, required String authorId}) async {
    await _supabase
        .from('posts')
        .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', postId)
        .eq('author_id', authorId);
  }

  // ─── Search Posts ─────────────────────────────────────────────────────
  Future<List<PostModel>> searchPosts(String query) async {
    final data = await _supabase
        .from('posts')
        .select('''
          *,
          author:profiles!author_id(id, username, display_name, avatar_url, is_verified, is_admin)
        ''')
        .ilike('text', '%$query%')
        .eq('is_deleted', false)
        .order('likes_count', ascending: false)
        .limit(AppConstants.searchPageSize);

    return (data as List).map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ─── Trending Hashtags ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchTrendingHashtags() async {
    final data = await _supabase.rpc('get_trending_hashtags');
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ─── Pin Post ─────────────────────────────────────────────────────────
  Future<void> pinPost({required String postId, required String authorId, required bool pin}) async {
    // Unpin all first
    if (pin) {
      await _supabase
          .from('posts')
          .update({'is_pinned': false})
          .eq('author_id', authorId);
    }
    await _supabase
        .from('posts')
        .update({'is_pinned': pin})
        .eq('id', postId);
  }

  // ─── Helper ───────────────────────────────────────────────────────────
  Future<void> _createNotification({
    required String userId,
    required String type,
    required String actorId,
    String? postId,
    String? message,
  }) async {
    if (userId == actorId) return;
    await _supabase.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'actor_id': actorId,
      'post_id': postId,
      'message': message ?? '',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
