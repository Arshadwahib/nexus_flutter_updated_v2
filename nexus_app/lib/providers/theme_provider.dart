// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode') ?? 'system';
    _themeMode = saved == 'light'
        ? ThemeMode.light
        : saved == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> toggleTheme() async {
    await setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

// lib/providers/feed_provider.dart
// (Separate file in real project)
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

class FeedProvider extends ChangeNotifier {
  final PostService _postService = PostService();

  List<PostModel> _feedPosts = [];
  List<PostModel> _reels = [];
  List<PostModel> _stories = [];
  List<PostModel> _explorePosts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;

  List<PostModel> get feedPosts => _feedPosts;
  List<PostModel> get reels => _reels;
  List<PostModel> get stories => _stories;
  List<PostModel> get explorePosts => _explorePosts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadFeed(String userId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _hasMore = true;
      _feedPosts = [];
    }
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final posts = await _postService.fetchHomeFeed(userId: userId, page: _currentPage);
      if (posts.isEmpty) {
        _hasMore = false;
      } else {
        _feedPosts.addAll(posts);
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReels({bool refresh = false}) async {
    if (refresh) _reels = [];
    _isLoading = true;
    notifyListeners();
    try {
      _reels = await _postService.fetchReels();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStories(String userId) async {
    try {
      _stories = await _postService.fetchStories(userId: userId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadExplorePosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _explorePosts = await _postService.fetchExplorePosts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleLike(String postId, String userId) {
    final index = _feedPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _feedPosts[index];
      _feedPosts[index] = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
      notifyListeners();
      _postService.toggleLike(postId: postId, userId: userId, currentlyLiked: post.isLiked);
    }
  }

  void toggleBookmark(String postId, String userId) {
    final index = _feedPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _feedPosts[index];
      _feedPosts[index] = post.copyWith(isBookmarked: !post.isBookmarked);
      notifyListeners();
      _postService.toggleBookmark(
        postId: postId, userId: userId, currentlyBookmarked: post.isBookmarked,
      );
    }
  }

  void addNewPost(PostModel post) {
    _feedPosts.insert(0, post);
    notifyListeners();
  }

  void removePost(String postId) {
    _feedPosts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }
}

// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  int _totalUnread = 0;

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  int get totalUnread => _totalUnread;

  void setConversations(List<ConversationModel> convos) {
    _conversations = convos;
    _totalUnread = convos.fold(0, (sum, c) => sum + c.unreadCount);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

// lib/providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void setNotifications(List<NotificationModel> notifs) {
    _notifications = notifs;
    _unreadCount = notifs.where((n) => !n.isRead).length;
    notifyListeners();
  }

  void markAllRead() {
    _notifications = _notifications.map((n) {
      return NotificationModel(
        id: n.id, userId: n.userId, type: n.type, actorId: n.actorId,
        actorUsername: n.actorUsername, actorDisplayName: n.actorDisplayName,
        actorAvatarUrl: n.actorAvatarUrl, actorIsVerified: n.actorIsVerified,
        postId: n.postId, postPreviewUrl: n.postPreviewUrl, commentText: n.commentText,
        message: n.message, isRead: true, createdAt: n.createdAt,
      );
    }).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  void incrementUnread() {
    _unreadCount++;
    notifyListeners();
  }
}
