// lib/screens/home/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';
import 'post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _supabase = Supabase.instance.client;
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  PostModel? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;
  String? _replyToId;
  String? _replyToUsername;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
  }

  Future<void> _loadPost() async {
    try {
      final data = await _supabase
          .from('posts')
          .select('''*,
            author:profiles!author_id(
              id, username, display_name, avatar_url, is_verified, is_admin
            )''')
          .eq('id', widget.postId)
          .single();
      if (mounted) {
        setState(() { _post = PostModel.fromJson(data as Map<String, dynamic>); _isLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadComments() async {
    try {
      final data = await _supabase
          .from('comments')
          .select('''*, author:profiles!author_id(
            id, username, display_name, avatar_url, is_verified, is_admin
          )''')
          .eq('post_id', widget.postId)
          .eq('is_deleted', false)
          .is_('parent_id', null)
          .order('created_at', ascending: true)
          .limit(100);
      if (mounted) {
        setState(() => _comments = List<Map<String, dynamic>>.from(data as List));
      }
    } catch (_) {}
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isPosting) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    setState(() => _isPosting = true);
    try {
      await _supabase.from('comments').insert({
        'post_id': widget.postId,
        'author_id': userId,
        'text': text,
        'parent_id': _replyToId,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _supabase.rpc('increment_comments_count', params: {'post_id': widget.postId});
      _commentCtrl.clear();
      setState(() { _replyToId = null; _replyToUsername = null; });
      _loadComments();
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _post == null
                    ? Center(
                        child: Text('Post not found',
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: isDark ? AppTheme.grey600 : AppTheme.grey400)))
                    : CustomScrollView(
                        controller: _scrollCtrl,
                        slivers: [
                          // Post card (non-tappable in detail view)
                          SliverToBoxAdapter(
                            child: PostCard(
                              post: _post!,
                              currentUserId: currentUser?.id ?? '',
                            ),
                          ),
                          // Stats row
                          SliverToBoxAdapter(
                            child: _buildStatsRow(isDark, theme),
                          ),
                          const SliverToBoxAdapter(child: Divider(height: 0)),
                          // Comments label
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Text(
                                '${_post!.commentsCount} Comments',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    color: isDark ? AppTheme.grey500 : AppTheme.grey400),
                              ),
                            ),
                          ),
                          // Comments list
                          if (_comments.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded,
                                          size: 40,
                                          color: isDark ? AppTheme.grey700 : AppTheme.grey300),
                                      const SizedBox(height: 10),
                                      Text('No comments yet. Be the first!',
                                          style: TextStyle(
                                              color: isDark ? AppTheme.grey600 : AppTheme.grey400)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _CommentTile(
                                  comment: _comments[i],
                                  isDark: isDark,
                                  theme: theme,
                                  onReply: (id, username) {
                                    setState(() {
                                      _replyToId = id;
                                      _replyToUsername = username;
                                    });
                                    FocusScope.of(context).requestFocus();
                                  },
                                ),
                                childCount: _comments.length,
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 80)),
                        ],
                      ),
          ),

          // Reply indicator
          if (_replyToUsername != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppTheme.grey900 : AppTheme.grey100,
              child: Row(
                children: [
                  Text('Replying to @$_replyToUsername',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() { _replyToId = null; _replyToUsername = null; }),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.grey400),
                  ),
                ],
              ),
            ),

          // Comment input
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.black : AppTheme.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.grey900 : AppTheme.grey200,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: currentUser?.avatarUrl,
                  name: currentUser?.displayName ?? '',
                  radius: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: _replyToUsername != null
                            ? 'Reply to @$_replyToUsername...'
                            : 'Add a comment...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        hintStyle: TextStyle(
                            color: isDark ? AppTheme.grey600 : AppTheme.grey400,
                            fontSize: 14),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder(
                  valueListenable: _commentCtrl,
                  builder: (_, ctrl, __) {
                    final hasText = (ctrl as TextEditingValue).text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: hasText ? _postComment : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: hasText
                              ? (isDark ? AppTheme.white : AppTheme.black)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: hasText
                              ? (isDark ? AppTheme.black : AppTheme.white)
                              : (isDark ? AppTheme.grey600 : AppTheme.grey300),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, ThemeData theme) {
    if (_post == null) return const SizedBox.shrink();
    String _format(int n) {
      if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
      return '$n';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _StatChip(
              count: _format(_post!.repostsCount), label: 'Reposts', isDark: isDark),
          const SizedBox(width: 20),
          _StatChip(
              count: _format(_post!.likesCount), label: 'Likes', isDark: isDark),
          const SizedBox(width: 20),
          _StatChip(
              count: _format(_post!.bookmarksCount), label: 'Saves', isDark: isDark),
          const SizedBox(width: 20),
          _StatChip(
              count: _format(_post!.viewsCount), label: 'Views', isDark: isDark),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String count;
  final String label;
  final bool isDark;

  const _StatChip({required this.count, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          TextSpan(
            text: count,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: '  $label',
            style: TextStyle(
                color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final bool isDark;
  final ThemeData theme;
  final void Function(String id, String username) onReply;

  const _CommentTile({
    required this.comment,
    required this.isDark,
    required this.theme,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final author = comment['author'] as Map<String, dynamic>? ?? {};
    final createdAt = DateTime.tryParse(comment['created_at'] as String? ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            imageUrl: author['avatar_url'] as String?,
            name: author['display_name'] as String? ?? '',
            radius: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author['display_name'] as String? ?? '',
                      style: theme.textTheme.labelLarge,
                    ),
                    if (author['is_verified'] == true || author['is_admin'] == true) ...[
                      const SizedBox(width: 4),
                      VerifiedBadge(isAdmin: author['is_admin'] == true, size: 12),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      createdAt != null ? timeago.format(createdAt) : '',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment['text'] as String? ?? '', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onReply(
                        comment['id'] as String,
                        author['username'] as String? ?? '',
                      ),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite_border_rounded, size: 14,
                        color: isDark ? AppTheme.grey600 : AppTheme.grey400),
                    const SizedBox(width: 4),
                    Text(
                      '${comment['likes_count'] ?? 0}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.grey600 : AppTheme.grey400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
