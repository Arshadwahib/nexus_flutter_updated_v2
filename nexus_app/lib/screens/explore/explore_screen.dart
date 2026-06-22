// lib/screens/explore/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/post_service.dart';
import '../../services/follow_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _postService = PostService();
  final _followService = FollowService();
  late TabController _tabCtrl;

  bool _isSearching = false;
  String _searchQuery = '';
  List<UserModel> _userResults = [];
  List<PostModel> _postResults = [];
  List<Map<String, dynamic>> _trendingTags = [];
  List<UserModel> _suggestedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadExploreFeed();
    _loadTrending();
    _loadSuggested();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _loadExploreFeed() async {
    await context.read<FeedProvider>().loadExplorePosts();
  }

  Future<void> _loadTrending() async {
    try {
      final tags = await _postService.fetchTrendingHashtags();
      setState(() => _trendingTags = tags);
    } catch (_) {}
  }

  Future<void> _loadSuggested() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    try {
      final users = await _followService.getSuggestedUsers(userId);
      setState(() => _suggestedUsers = users);
    } catch (_) {}
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
        _userResults = [];
        _postResults = [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchQuery = q;
    });
    _performSearch(q);
  }

  Future<void> _performSearch(String q) async {
    setState(() => _isLoading = true);
    try {
      final users = await _followService.searchUsers(q);
      final posts = await _postService.searchPosts(q);
      if (mounted) {
        setState(() {
          _userResults = users;
          _postResults = posts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.grey900 : AppTheme.grey100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search Nexus...',
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20,
                  color: isDark ? AppTheme.grey500 : AppTheme.grey400),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18,
                          color: isDark ? AppTheme.grey500 : AppTheme.grey400),
                      onPressed: () {
                        _searchCtrl.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              hintStyle: TextStyle(
                  color: isDark ? AppTheme.grey600 : AppTheme.grey400,
                  fontSize: 15),
            ),
          ),
        ),
        bottom: _isSearching
            ? null
            : TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(text: 'For You'),
                  Tab(text: 'Trending'),
                  Tab(text: 'People'),
                ],
              ),
      ),
      body: _isSearching
          ? _buildSearchResults(isDark, theme)
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildExploreGrid(isDark),
                _buildTrending(isDark, theme),
                _buildPeople(isDark, theme),
              ],
            ),
    );
  }

  Widget _buildExploreGrid(bool isDark) {
    final posts = context.watch<FeedProvider>().explorePosts;
    if (posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final post = posts[i];

        // Featured large tile every 7 items
        if (i % 7 == 0 && i > 0) {
          return GridTile(
            child: GestureDetector(
              onTap: () => context.push('/post/${post.id}'),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (post.hasMedia)
                    CachedNetworkImage(
                      imageUrl: post.media.first.isVideo
                          ? (post.media.first.thumbnailUrl ?? post.media.first.url)
                          : post.media.first.url,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                      padding: const EdgeInsets.all(12),
                      child: Text(post.text ?? '', style: const TextStyle(fontSize: 13)),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Row(
                      children: [
                        Icon(Icons.favorite_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _format(post.likesCount),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => context.push('/post/${post.id}'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (post.hasMedia)
                CachedNetworkImage(
                  imageUrl: post.media.first.isVideo
                      ? (post.media.first.thumbnailUrl ?? post.media.first.url)
                      : post.media.first.url,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                  padding: const EdgeInsets.all(8),
                  child: Text(post.text ?? '',
                      style: const TextStyle(fontSize: 11),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis),
                ),
              if (post.media.isNotEmpty && post.media.first.isVideo)
                const Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 16),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrending(bool isDark, ThemeData theme) {
    if (_trendingTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_rounded,
                size: 56,
                color: isDark ? AppTheme.grey700 : AppTheme.grey300),
            const SizedBox(height: 14),
            Text('Nothing trending yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: isDark ? AppTheme.grey600 : AppTheme.grey400)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _trendingTags.length,
      itemBuilder: (_, i) {
        final tag = _trendingTags[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.grey900 : AppTheme.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: i < 3
                        ? AppTheme.accent
                        : (isDark ? AppTheme.grey500 : AppTheme.grey400)),
              ),
            ),
          ),
          title: Text('#${tag['tag']}',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text('${_format(tag['post_count'] as int)} posts',
              style: theme.textTheme.bodySmall),
          trailing: Icon(Icons.trending_up_rounded,
              size: 18,
              color: isDark ? AppTheme.grey600 : AppTheme.grey300),
          onTap: () {
            _searchCtrl.text = '#${tag['tag']}';
            _performSearch('#${tag['tag']}');
          },
        );
      },
    );
  }

  Widget _buildPeople(bool isDark, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _suggestedUsers.length,
      itemBuilder: (_, i) {
        final user = _suggestedUsers[i];
        return _UserTile(
          user: user,
          isDark: isDark,
          theme: theme,
          onTap: () => context.push('/profile/${user.username}'),
          onFollow: () async {
            final currentUser =
                context.read<AuthProvider>().currentUser;
            if (currentUser == null) return;
            await _followService.followUser(
              followerId: currentUser.id,
              followingId: user.id,
              isPrivateAccount: user.isPrivate,
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(bool isDark, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_userResults.isEmpty && _postResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: isDark ? AppTheme.grey700 : AppTheme.grey300),
            const SizedBox(height: 14),
            Text('No results for "$_searchQuery"',
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: isDark ? AppTheme.grey600 : AppTheme.grey400)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (_userResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text('People',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: isDark ? AppTheme.grey500 : AppTheme.grey400)),
          ),
          ..._userResults.take(5).map((user) => _UserTile(
                user: user,
                isDark: isDark,
                theme: theme,
                onTap: () => context.push('/profile/${user.username}'),
                onFollow: () async {
                  final currentUser =
                      context.read<AuthProvider>().currentUser;
                  if (currentUser == null) return;
                  await _followService.followUser(
                    followerId: currentUser.id,
                    followingId: user.id,
                    isPrivateAccount: user.isPrivate,
                  );
                },
              )),
        ],
        if (_postResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Posts',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: isDark ? AppTheme.grey500 : AppTheme.grey400)),
          ),
          ..._postResults.map((post) => ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: UserAvatar(
                    imageUrl: post.authorAvatarUrl,
                    name: post.authorDisplayName,
                    radius: 18),
                title: Text(post.authorDisplayName,
                    style: theme.textTheme.titleSmall),
                subtitle: Text(
                  post.text ?? '[Media]',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () => context.push('/post/${post.id}'),
              )),
        ],
      ],
    );
  }

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onFollow;

  const _UserTile({
    required this.user,
    required this.isDark,
    required this.theme,
    required this.onTap,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: GestureDetector(
        onTap: onTap,
        child: UserAvatar(
            imageUrl: user.avatarUrl, name: user.displayName, radius: 22),
      ),
      title: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Text(user.displayName, style: theme.textTheme.titleSmall),
            if (user.isVerified || user.isAdmin) ...[
              const SizedBox(width: 4),
              VerifiedBadge(isAdmin: user.isAdmin, size: 14),
            ],
          ],
        ),
      ),
      subtitle: Text('@${user.username}', style: theme.textTheme.bodySmall),
      trailing: OutlinedButton(
        onPressed: onFollow,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          minimumSize: Size.zero,
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: const Text('Follow'),
      ),
      onTap: onTap,
    );
  }
}
