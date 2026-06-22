// lib/screens/feed/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nexus_logo.dart';
import '../../widgets/user_avatar.dart';
import '../home/post_card.dart';
import '../home/story_bar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _scrollController.addListener(_onScroll);
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    context.read<FeedProvider>().loadFeed(userId, refresh: true);
    context.read<FeedProvider>().loadStories(userId);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<FeedProvider>().loadFeed(userId);
      }
    }
  }

  Future<void> _onRefresh() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context.read<FeedProvider>().loadFeed(userId, refresh: true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final feed = context.watch<FeedProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const NexusLogo(size: 32),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 26),
            onPressed: () => context.push('/notifications'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'For You'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedList(feed, auth, isDark),
          _buildFeedList(feed, auth, isDark, followingOnly: true),
        ],
      ),
    );
  }

  Widget _buildFeedList(
    FeedProvider feed,
    AuthProvider auth,
    bool isDark, {
    bool followingOnly = false,
  }) {
    if (feed.isLoading && feed.feedPosts.isEmpty) {
      return _buildSkeleton(isDark);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: isDark ? AppTheme.white : AppTheme.black,
      backgroundColor: isDark ? AppTheme.grey900 : AppTheme.white,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Stories
          SliverToBoxAdapter(
            child: StoryBar(
              stories: feed.stories,
              currentUser: auth.currentUser,
            ),
          ),

          // Posts
          if (feed.feedPosts.isEmpty && !feed.isLoading)
            SliverFillRemaining(
              child: _buildEmptyState(isDark),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == feed.feedPosts.length) {
                    return feed.hasMore
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                "You're all caught up! 🎉",
                                style: TextStyle(color: AppTheme.grey400),
                              ),
                            ),
                          );
                  }
                  final post = feed.feedPosts[index];
                  return PostCard(
                    post: post,
                    currentUserId: auth.currentUser?.id ?? '',
                    onLike: () => feed.toggleLike(post.id, auth.currentUser?.id ?? ''),
                    onBookmark: () => feed.toggleBookmark(post.id, auth.currentUser?.id ?? ''),
                    onTap: () => context.push('/post/${post.id}'),
                    onUserTap: () => context.push('/profile/${post.authorUsername}'),
                  );
                },
                childCount: feed.feedPosts.length + 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, __) => _PostSkeleton(isDark: isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dynamic_feed_rounded,
            size: 64,
            color: isDark ? AppTheme.grey700 : AppTheme.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing here yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.grey600 : AppTheme.grey400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow people to see their posts here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.grey700 : AppTheme.grey300,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/explore'),
            child: const Text('Discover People'),
          ),
        ],
      ),
    );
  }
}

class _PostSkeleton extends StatefulWidget {
  final bool isDark;
  const _PostSkeleton({required this.isDark});

  @override
  State<_PostSkeleton> createState() => _PostSkeletonState();
}

class _PostSkeletonState extends State<_PostSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? AppTheme.grey900 : AppTheme.grey100;
    return FadeTransition(
      opacity: _anim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(height: 10, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 200, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 12),
                  Container(height: 180, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(12))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
