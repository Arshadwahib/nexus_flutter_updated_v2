// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/follow_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';
import '../home/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? username; // null = own profile

  const ProfileScreen({super.key, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _postService = PostService();
  final _followService = FollowService();
  late TabController _tabCtrl;

  UserModel? _profileUser;
  List<PostModel> _posts = [];
  List<PostModel> _mediaPosts = [];
  List<PostModel> _likedPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    _isOwnProfile = widget.username == null ||
        widget.username == currentUser?.username;

    try {
      if (_isOwnProfile) {
        _profileUser = currentUser;
      } else {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('username', widget.username!)
            .single();
        _profileUser = UserModel.fromJson(data as Map<String, dynamic>);
      }

      if (_profileUser != null) {
        final posts = await _postService.fetchUserPosts(userId: _profileUser!.id);
        final media = await _postService.fetchUserPosts(
            userId: _profileUser!.id, mediaOnly: true);

        if (!_isOwnProfile && currentUser != null) {
          _isFollowing = await _followService.isFollowing(
            followerId: currentUser.id,
            followingId: _profileUser!.id,
          );
        }

        setState(() {
          _posts = posts;
          _mediaPosts = media;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null || _profileUser == null) return;

    if (_isFollowing) {
      await _followService.unfollowUser(
        followerId: currentUser.id,
        followingId: _profileUser!.id,
      );
    } else {
      await _followService.followUser(
        followerId: currentUser.id,
        followingId: _profileUser!.id,
        isPrivateAccount: _profileUser!.isPrivate,
      );
    }
    setState(() => _isFollowing = !_isFollowing);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = context.watch<AuthProvider>().currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_profileUser == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text('User not found',
              style: theme.textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.grey600 : AppTheme.grey400)),
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (_isOwnProfile) ...[
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  onPressed: () => _showSettingsSheet(isDark),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 22),
                  onPressed: () => _showProfileOptions(isDark),
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  if (_profileUser!.coverImageUrl != null)
                    CachedNetworkImage(
                      imageUrl: _profileUser!.coverImageUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                    ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark ? AppTheme.black : AppTheme.white)
                                .withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + action button row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Avatar (overlapping the cover)
                      Transform.translate(
                        offset: const Offset(0, -36),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.black : AppTheme.white,
                            shape: BoxShape.circle,
                          ),
                          child: UserAvatar(
                            imageUrl: _profileUser!.avatarUrl,
                            name: _profileUser!.displayName,
                            radius: 40,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 12),
                      // Action buttons
                      if (_isOwnProfile) ...[
                        OutlinedButton(
                          onPressed: () => context.push('/edit-profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Edit Profile',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        if (currentUser?.isAdmin == true) ...[
                          OutlinedButton(
                            onPressed: () => context.push('/admin'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              foregroundColor: AppTheme.adminBlue,
                              side: BorderSide(color: AppTheme.adminBlue),
                            ),
                            child: const Icon(Icons.shield_rounded, size: 18),
                          ),
                        ],
                      ] else ...[
                        ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            minimumSize: Size.zero,
                            backgroundColor: _isFollowing
                                ? (isDark ? AppTheme.grey800 : AppTheme.grey100)
                                : (isDark ? AppTheme.white : AppTheme.black),
                            foregroundColor: _isFollowing
                                ? (isDark ? AppTheme.white : AppTheme.black)
                                : (isDark ? AppTheme.black : AppTheme.white),
                          ),
                          child: Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Icon(Icons.mail_outline_rounded, size: 18),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Name + verified
                  Row(
                    children: [
                      Text(_profileUser!.displayName,
                          style: theme.textTheme.headlineMedium),
                      if (_profileUser!.isVerified ||
                          _profileUser!.isAdmin) ...[
                        const SizedBox(width: 6),
                        VerifiedBadge(
                            isAdmin: _profileUser!.isAdmin, size: 18),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('@${_profileUser!.username}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppTheme.grey500
                              : AppTheme.grey400)),

                  if (_profileUser!.bio != null &&
                      _profileUser!.bio!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_profileUser!.bio!,
                        style: theme.textTheme.bodyMedium),
                  ],

                  if (_profileUser!.website != null ||
                      _profileUser!.location != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      children: [
                        if (_profileUser!.location != null)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.location_on_outlined,
                                size: 14,
                                color: isDark
                                    ? AppTheme.grey500
                                    : AppTheme.grey400),
                            const SizedBox(width: 4),
                            Text(_profileUser!.location!,
                                style: theme.textTheme.bodySmall),
                          ]),
                        if (_profileUser!.website != null)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.link_rounded,
                                size: 14, color: AppTheme.accent),
                            const SizedBox(width: 4),
                            Text(_profileUser!.website!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w500)),
                          ]),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Stats row
                  Row(
                    children: [
                      _StatItem(
                          count: _profileUser!.postsCount,
                          label: 'Posts',
                          isDark: isDark),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {},
                        child: _StatItem(
                            count: _profileUser!.followersCount,
                            label: 'Followers',
                            isDark: isDark),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {},
                        child: _StatItem(
                            count: _profileUser!.followingCount,
                            label: 'Following',
                            isDark: isDark),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                  Tab(icon: Icon(Icons.article_outlined, size: 22)),
                  Tab(icon: Icon(Icons.favorite_border_rounded, size: 22)),
                ],
              ),
              isDark: isDark,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // Media grid
            _buildMediaGrid(isDark),
            // Posts list
            _buildPostsList(isDark),
            // Liked posts
            _buildLikedPosts(isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(bool isDark) {
    if (_mediaPosts.isEmpty) {
      return _EmptyTab(
          icon: Icons.photo_library_outlined,
          message: 'No photos or videos yet',
          isDark: isDark);
    }
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: _mediaPosts.length,
      itemBuilder: (_, i) {
        final post = _mediaPosts[i];
        final media = post.media.isNotEmpty ? post.media.first : null;
        return GestureDetector(
          onTap: () => context.push('/post/${post.id}'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (media != null)
                CachedNetworkImage(
                  imageUrl: media.isVideo
                      ? (media.thumbnailUrl ?? media.url)
                      : media.url,
                  fit: BoxFit.cover,
                )
              else
                Container(
                    color: isDark ? AppTheme.grey900 : AppTheme.grey100),
              if (media?.isVideo == true)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 18),
                ),
              if (post.media.length > 1)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.copy_rounded,
                      color: Colors.white, size: 16),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostsList(bool isDark) {
    if (_posts.isEmpty) {
      return _EmptyTab(
          icon: Icons.article_outlined,
          message: 'No posts yet',
          isDark: isDark);
    }
    final currentUserId =
        context.read<AuthProvider>().currentUser?.id ?? '';
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (_, i) => PostCard(
        post: _posts[i],
        currentUserId: currentUserId,
        onTap: () => context.push('/post/${_posts[i].id}'),
        onUserTap: () {},
      ),
    );
  }

  Widget _buildLikedPosts(bool isDark, ThemeData theme) {
    if (!_isOwnProfile) {
      return _EmptyTab(
          icon: Icons.lock_outlined,
          message: 'Liked posts are private',
          isDark: isDark);
    }
    if (_likedPosts.isEmpty) {
      return _EmptyTab(
          icon: Icons.favorite_border_rounded,
          message: 'No liked posts yet',
          isDark: isDark);
    }
    final currentUserId =
        context.read<AuthProvider>().currentUser?.id ?? '';
    return ListView.builder(
      itemCount: _likedPosts.length,
      itemBuilder: (_, i) => PostCard(
        post: _likedPosts[i],
        currentUserId: currentUserId,
        onTap: () => context.push('/post/${_likedPosts[i].id}'),
        onUserTap: () {},
      ),
    );
  }

  void _showSettingsSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.grey900 : AppTheme.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.grey700 : AppTheme.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Edit Profile'),
              onTap: () { Navigator.pop(context); context.push('/edit-profile'); },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline_rounded),
              title: const Text('Saved Posts'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Appearance'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none_rounded),
              title: const Text('Notifications'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Privacy'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: AppTheme.danger),
              title: Text('Sign Out',
                  style: TextStyle(color: AppTheme.danger)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().signOut();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showProfileOptions(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.grey900 : AppTheme.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.volume_off_outlined),
              title: Text('Mute @${_profileUser?.username}'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: Text('Block @${_profileUser?.username}'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: AppTheme.danger),
              title: Text('Report',
                  style: TextStyle(color: AppTheme.danger)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final bool isDark;

  const _StatItem(
      {required this.count, required this.label, required this.isDark});

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_format(count),
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.grey500 : AppTheme.grey400)),
      ],
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;

  const _EmptyTab(
      {required this.icon, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 56,
              color: isDark ? AppTheme.grey700 : AppTheme.grey300),
          const SizedBox(height: 14),
          Text(message,
              style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppTheme.grey600 : AppTheme.grey400,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  const _TabBarDelegate(this.tabBar, {required this.isDark});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppTheme.black : AppTheme.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// Supabase import needed in profile_screen
import 'package:supabase_flutter/supabase_flutter.dart';
