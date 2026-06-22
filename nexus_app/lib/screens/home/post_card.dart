// lib/screens/home/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool compact;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onLike,
    this.onBookmark,
    this.onTap,
    this.onUserTap,
    this.onRepost,
    this.onShare,
    this.onDelete,
    this.showActions = true,
    this.compact = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  bool _showHeart = false;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    // Double-tap to like (Instagram style)
    if (!widget.post.isLiked) {
      widget.onLike?.call();
    }
    setState(() => _showHeart = true);
    HapticFeedback.mediumImpact();
    _heartCtrl.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showHeart = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final post = widget.post;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppTheme.grey900 : AppTheme.grey200,
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Repost indicator
              if (post.repostOfId != null)
                Padding(
                  padding: const EdgeInsets.only(left: 42, bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.repeat_rounded, size: 14, color: AppTheme.grey500),
                      const SizedBox(width: 6),
                      Text(
                        '${post.authorDisplayName} reposted',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.grey500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: widget.onUserTap,
                    child: UserAvatar(
                      imageUrl: post.authorAvatarUrl,
                      name: post.authorDisplayName,
                      radius: 21,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onUserTap,
                              child: Row(
                                children: [
                                  Text(
                                    post.authorDisplayName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (post.authorIsVerified || post.authorIsAdmin) ...[
                                    const SizedBox(width: 4),
                                    VerifiedBadge(
                                      isAdmin: post.authorIsAdmin,
                                      size: 15,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '@${post.authorUsername}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeago.format(post.createdAt, allowFromNow: true),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _MoreMenu(
                              post: post,
                              currentUserId: widget.currentUserId,
                              onDelete: widget.onDelete,
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Pinned indicator
                        if (post.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(Icons.push_pin_rounded, size: 12, color: AppTheme.grey500),
                                const SizedBox(width: 4),
                                Text(
                                  'Pinned',
                                  style: TextStyle(fontSize: 11, color: AppTheme.grey500),
                                ),
                              ],
                            ),
                          ),

                        // Text content
                        if (post.text != null && post.text!.isNotEmpty)
                          _RichText(text: post.text!, theme: theme, isDark: isDark),

                        // Media
                        if (post.hasMedia) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onDoubleTap: _handleDoubleTap,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _MediaGrid(media: post.media),
                                if (_showHeart)
                                  ScaleTransition(
                                    scale: CurvedAnimation(
                                      parent: _heartCtrl,
                                      curve: Curves.elasticOut,
                                    ),
                                    child: const Icon(
                                      Icons.favorite_rounded,
                                      color: AppTheme.danger,
                                      size: 80,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // Poll
                        if (post.isPoll && post.pollOptions != null)
                          _PollWidget(post: post, theme: theme, isDark: isDark),

                        // Location
                        if (post.location != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: AppTheme.grey500),
                                const SizedBox(width: 4),
                                Text(
                                  post.location!,
                                  style: TextStyle(fontSize: 12, color: AppTheme.grey500),
                                ),
                              ],
                            ),
                          ),

                        // Action row
                        if (widget.showActions) ...[
                          const SizedBox(height: 12),
                          _ActionRow(
                            post: post,
                            isDark: isDark,
                            onLike: widget.onLike,
                            onBookmark: widget.onBookmark,
                            onRepost: widget.onRepost,
                            onShare: widget.onShare,
                            onComment: widget.onTap,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RichText extends StatelessWidget {
  final String text;
  final ThemeData theme;
  final bool isDark;

  const _RichText({required this.text, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final words = text.split(' ');

    for (final word in words) {
      if (word.startsWith('#')) {
        spans.add(TextSpan(
          text: '$word ',
          style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w500),
        ));
      } else if (word.startsWith('@')) {
        spans.add(TextSpan(
          text: '$word ',
          style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w500),
        ));
      } else {
        spans.add(TextSpan(text: '$word '));
      }
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        children: spans,
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<MediaItem> media;
  const _MediaGrid({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.length == 1) {
      return _MediaTile(item: media[0], borderRadius: BorderRadius.circular(14));
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 3,
      mainAxisSpacing: 3,
      children: media.take(4).toList().asMap().entries.map((e) {
        final isLast = e.key == 3 && media.length > 4;
        return Stack(
          fit: StackFit.expand,
          children: [
            _MediaTile(item: e.value, borderRadius: BorderRadius.circular(8)),
            if (isLast)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '+${media.length - 3}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final MediaItem item;
  final BorderRadius borderRadius;

  const _MediaTile({required this.item, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: item.aspectRatio ?? 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.isVideo ? (item.thumbnailUrl ?? item.url) : item.url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: isDark ? AppTheme.grey900 : AppTheme.grey100,
              ),
            ),
            if (item.isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PollWidget extends StatelessWidget {
  final PostModel post;
  final ThemeData theme;
  final bool isDark;

  const _PollWidget({required this.post, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = post.totalPollVotes;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: post.pollOptions!.map((opt) {
          final pct = total == 0 ? 0.0 : opt.voteCount / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Stack(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.grey800 : AppTheme.grey100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: opt.hasVoted
                          ? (isDark ? AppTheme.white : AppTheme.black)
                          : (isDark ? AppTheme.grey700 : AppTheme.grey200),
                      width: 1.5,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: Container(
                      height: 44,
                      color: isDark
                          ? AppTheme.white.withOpacity(0.12)
                          : AppTheme.black.withOpacity(0.08),
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        if (opt.hasVoted)
                          Icon(Icons.check_circle_rounded, size: 16,
                              color: isDark ? AppTheme.white : AppTheme.black),
                        if (opt.hasVoted) const SizedBox(width: 8),
                        Expanded(
                          child: Text(opt.text, style: theme.textTheme.bodyMedium),
                        ),
                        Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onRepost;
  final VoidCallback? onShare;
  final VoidCallback? onComment;

  const _ActionRow({
    required this.post,
    required this.isDark,
    this.onLike,
    this.onBookmark,
    this.onRepost,
    this.onShare,
    this.onComment,
  });

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionBtn(
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
          count: post.commentsCount,
          isActive: false,
          onTap: onComment,
          isDark: isDark,
        ),
        _ActionBtn(
          icon: Icons.repeat_rounded,
          count: post.repostsCount,
          isActive: post.isReposted,
          activeColor: AppTheme.success,
          onTap: onRepost,
          isDark: isDark,
        ),
        _ActionBtn(
          icon: Icons.favorite_border_rounded,
          activeIcon: Icons.favorite_rounded,
          count: post.likesCount,
          isActive: post.isLiked,
          activeColor: AppTheme.danger,
          onTap: onLike,
          isDark: isDark,
          haptic: true,
        ),
        _ActionBtn(
          icon: Icons.bar_chart_rounded,
          count: post.viewsCount,
          isActive: false,
          onTap: null,
          isDark: isDark,
        ),
        const Spacer(),
        _ActionBtn(
          icon: Icons.bookmark_border_rounded,
          activeIcon: Icons.bookmark_rounded,
          count: 0,
          isActive: post.isBookmarked,
          onTap: onBookmark,
          isDark: isDark,
        ),
        const SizedBox(width: 4),
        _ActionBtn(
          icon: Icons.ios_share_rounded,
          count: 0,
          isActive: false,
          onTap: onShare,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final int count;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;
  final bool isDark;
  final bool haptic;

  const _ActionBtn({
    required this.icon,
    this.activeIcon,
    required this.count,
    required this.isActive,
    this.activeColor,
    this.onTap,
    required this.isDark,
    this.haptic = false,
  });

  String _format(int n) {
    if (n == 0) return '';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? (isDark ? AppTheme.white : AppTheme.black))
        : (isDark ? AppTheme.grey600 : AppTheme.grey400);

    return GestureDetector(
      onTap: () {
        if (haptic) HapticFeedback.lightImpact();
        onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Row(
          children: [
            Icon(
              isActive && activeIcon != null ? activeIcon : icon,
              size: 20,
              color: color,
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                _format(count),
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback? onDelete;

  const _MoreMenu({required this.post, required this.currentUserId, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showMenu(context, isDark),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: isDark ? AppTheme.grey600 : AppTheme.grey400,
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, bool isDark) {
    final isOwner = post.authorId == currentUserId;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.grey900 : AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.grey700 : AppTheme.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (isOwner) ...[
              _SheetOption(
                icon: Icons.push_pin_outlined,
                label: post.isPinned ? 'Unpin post' : 'Pin post',
                onTap: () => Navigator.pop(ctx),
              ),
              _SheetOption(
                icon: Icons.edit_outlined,
                label: 'Edit post',
                onTap: () => Navigator.pop(ctx),
              ),
              _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Delete post',
                color: AppTheme.danger,
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete?.call();
                },
              ),
            ] else ...[
              _SheetOption(
                icon: Icons.person_remove_outlined,
                label: 'Unfollow @${post.authorUsername}',
                onTap: () => Navigator.pop(ctx),
              ),
              _SheetOption(
                icon: Icons.volume_off_outlined,
                label: 'Mute @${post.authorUsername}',
                onTap: () => Navigator.pop(ctx),
              ),
              _SheetOption(
                icon: Icons.flag_outlined,
                label: 'Report post',
                color: AppTheme.danger,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? AppTheme.white : AppTheme.black);
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
    );
  }
}
