// lib/screens/reels/reels_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageCtrl = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedProvider>().loadReels(refresh: true);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reels = context.watch<FeedProvider>().reels;
    final isLoading = context.watch<FeedProvider>().isLoading;

    // Full-screen reels layout — hide status bar
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Reels',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined,
                  color: Colors.white, size: 24),
              onPressed: () {},
            ),
          ],
        ),
        body: isLoading && reels.isEmpty
            ? const Center(
                child:
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : reels.isEmpty
                ? _buildEmpty()
                : PageView.builder(
                    controller: _pageCtrl,
                    scrollDirection: Axis.vertical,
                    itemCount: reels.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (_, i) => _ReelItem(
                      reel: reels[i],
                      isActive: i == _currentIndex,
                      currentUserId:
                          context.read<AuthProvider>().currentUser?.id ?? '',
                      onUserTap: () =>
                          context.push('/profile/${reels[i].authorUsername}'),
                      onLike: () => context
                          .read<FeedProvider>()
                          .toggleLike(reels[i].id,
                              context.read<AuthProvider>().currentUser?.id ?? ''),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline_rounded,
              color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text('No Reels yet',
              style: TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Be the first to post a Reel!',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/create'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Reel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelItem extends StatefulWidget {
  final PostModel reel;
  final bool isActive;
  final String currentUserId;
  final VoidCallback onUserTap;
  final VoidCallback onLike;

  const _ReelItem({
    required this.reel,
    required this.isActive,
    required this.currentUserId,
    required this.onUserTap,
    required this.onLike,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoCtrl;
  bool _initialized = false;
  bool _isMuted = false;
  bool _isLiked = false;
  late AnimationController _likeAnim;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reel.isLiked;
    _likeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.reel.media.isNotEmpty && widget.reel.media.first.isVideo) {
      _initVideo(widget.reel.media.first.url);
    }
  }

  Future<void> _initVideo(String url) async {
    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoCtrl!.initialize();
    _videoCtrl!.setLooping(true);
    if (widget.isActive) _videoCtrl!.play();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void didUpdateWidget(_ReelItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _videoCtrl?.play();
    } else if (!widget.isActive && old.isActive) {
      _videoCtrl?.pause();
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _likeAnim.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!_isLiked) {
      widget.onLike();
      setState(() => _isLiked = true);
    }
    _likeAnim.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _videoCtrl?.setVolume(_isMuted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTap: () {
        if (_videoCtrl?.value.isPlaying == true) {
          _videoCtrl?.pause();
        } else {
          _videoCtrl?.play();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video background
          _initialized && _videoCtrl != null
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoCtrl!.value.size.width,
                    height: _videoCtrl!.value.size.height,
                    child: VideoPlayer(_videoCtrl!),
                  ),
                )
              : Container(
                  color: AppTheme.grey900,
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white54, strokeWidth: 2),
                  ),
                ),

          // Gradient overlays
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Double-tap heart animation
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _likeAnim,
                curve: Curves.elasticOut,
              ),
              child: FadeTransition(
                opacity: Tween(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(
                    parent: _likeAnim,
                    curve: const Interval(0.5, 1.0),
                  ),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 90,
                ),
              ),
            ),
          ),

          // Right-side action buttons
          Positioned(
            right: 12,
            bottom: 120,
            child: Column(
              children: [
                _ReelAction(
                  icon: _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _format(widget.reel.likesCount +
                      (_isLiked && !widget.reel.isLiked ? 1 : 0)),
                  color: _isLiked ? AppTheme.danger : Colors.white,
                  onTap: () {
                    widget.onLike();
                    setState(() => _isLiked = !_isLiked);
                    HapticFeedback.lightImpact();
                  },
                ),
                const SizedBox(height: 20),
                _ReelAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: _format(widget.reel.commentsCount),
                  onTap: () => _showComments(context),
                ),
                const SizedBox(height: 20),
                _ReelAction(
                  icon: Icons.repeat_rounded,
                  label: _format(widget.reel.repostsCount),
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                _ReelAction(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                // Mute button
                GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom author info
          Positioned(
            left: 16,
            right: 80,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                GestureDetector(
                  onTap: widget.onUserTap,
                  child: Row(
                    children: [
                      UserAvatar(
                        imageUrl: widget.reel.authorAvatarUrl,
                        name: widget.reel.authorDisplayName,
                        radius: 18,
                        showBorder: true,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.reel.authorDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (widget.reel.authorIsVerified ||
                          widget.reel.authorIsAdmin) ...[
                        const SizedBox(width: 4),
                        VerifiedBadge(
                            isAdmin: widget.reel.authorIsAdmin, size: 14),
                      ],
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Follow',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.reel.text != null &&
                    widget.reel.text!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.reel.text!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (widget.reel.hashtags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: widget.reel.hashtags
                        .take(3)
                        .map((tag) => Text(
                              '#$tag',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 8),
                // Music row
                Row(
                  children: [
                    const Icon(Icons.music_note_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'Original Audio',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Video progress bar
          if (_initialized && _videoCtrl != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _videoCtrl!,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: VideoProgressColors(
                  playedColor: Colors.white,
                  backgroundColor: Colors.white24,
                  bufferedColor: Colors.white38,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppTheme.grey900
              : AppTheme.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Comments',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            const Divider(height: 0),
            Expanded(
              child: Center(
                child: Text('No comments yet',
                    style: TextStyle(color: AppTheme.grey500)),
              ),
            ),
            const Divider(height: 0),
            const Padding(
              padding: EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  filled: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ReelAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}
