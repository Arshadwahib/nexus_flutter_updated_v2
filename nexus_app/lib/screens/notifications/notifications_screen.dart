// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    try {
      final data = await _supabase
          .from('notifications')
          .select('''*, actor:profiles!actor_id(
            id, username, display_name, avatar_url, is_verified, is_admin
          )''')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(60);

      final notifs = (data as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() { _notifications = notifs; _isLoading = false; });
        context.read<NotificationProvider>().setNotifications(notifs);
      }

      // Mark all as read
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _notifications = _notifications.map((n) => NotificationModel(
                  id: n.id, userId: n.userId, type: n.type, actorId: n.actorId,
                  actorUsername: n.actorUsername, actorDisplayName: n.actorDisplayName,
                  actorAvatarUrl: n.actorAvatarUrl, actorIsVerified: n.actorIsVerified,
                  postId: n.postId, postPreviewUrl: n.postPreviewUrl,
                  commentText: n.commentText, message: n.message,
                  isRead: true, createdAt: n.createdAt,
                )).toList();
              });
            },
            child: const Text('Mark all read', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _notifications.isEmpty
              ? _buildEmpty(isDark, theme)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: isDark ? AppTheme.white : AppTheme.black,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) =>
                        _NotifTile(notif: _notifications[i], isDark: isDark, theme: theme),
                  ),
                ),
    );
  }

  Widget _buildEmpty(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64,
              color: isDark ? AppTheme.grey700 : AppTheme.grey300),
          const SizedBox(height: 16),
          Text('No notifications yet', style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? AppTheme.grey600 : AppTheme.grey400)),
          const SizedBox(height: 8),
          Text("When someone likes or follows you,\nyou'll see it here.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.grey700 : AppTheme.grey300)),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final bool isDark;
  final ThemeData theme;

  const _NotifTile({required this.notif, required this.isDark, required this.theme});

  IconData get _typeIcon {
    switch (notif.type) {
      case NotificationType.like: return Icons.favorite_rounded;
      case NotificationType.comment: return Icons.chat_bubble_rounded;
      case NotificationType.follow: return Icons.person_add_rounded;
      case NotificationType.followRequest: return Icons.person_add_alt_1_rounded;
      case NotificationType.mention: return Icons.alternate_email_rounded;
      case NotificationType.repost: return Icons.repeat_rounded;
      case NotificationType.reply: return Icons.reply_rounded;
      case NotificationType.pollVote: return Icons.bar_chart_rounded;
      case NotificationType.storyView: return Icons.circle_rounded;
      case NotificationType.liveStart: return Icons.live_tv_rounded;
      case NotificationType.newPost: return Icons.article_rounded;
      case NotificationType.adminAction: return Icons.shield_rounded;
      case NotificationType.verifiedBadge: return Icons.verified_rounded;
      case NotificationType.systemMessage: return Icons.info_rounded;
    }
  }

  Color get _typeColor {
    switch (notif.type) {
      case NotificationType.like: return AppTheme.danger;
      case NotificationType.comment: return AppTheme.accent;
      case NotificationType.follow: return AppTheme.success;
      case NotificationType.followRequest: return AppTheme.success;
      case NotificationType.mention: return AppTheme.accent;
      case NotificationType.repost: return AppTheme.success;
      case NotificationType.reply: return AppTheme.accent;
      case NotificationType.pollVote: return Colors.orange;
      case NotificationType.storyView: return Colors.purple;
      case NotificationType.liveStart: return AppTheme.danger;
      case NotificationType.newPost: return AppTheme.accent;
      case NotificationType.adminAction: return AppTheme.adminBlue;
      case NotificationType.verifiedBadge: return AppTheme.accentGold;
      case NotificationType.systemMessage: return AppTheme.grey500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: notif.isRead
          ? Colors.transparent
          : (isDark ? AppTheme.grey900.withOpacity(0.5) : AppTheme.grey100),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(
              imageUrl: notif.actorAvatarUrl,
              name: notif.actorDisplayName,
              radius: 22,
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _typeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppTheme.black : AppTheme.white,
                    width: 1.5,
                  ),
                ),
                child: Icon(_typeIcon, size: 11, color: Colors.white),
              ),
            ),
          ],
        ),
        title: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(
                text: notif.actorDisplayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' '),
              TextSpan(text: _actionText),
              if (notif.commentText != null) ...[
                const TextSpan(text: ': '),
                TextSpan(
                  text: '"${notif.commentText}"',
                  style: TextStyle(
                    color: isDark ? AppTheme.grey400 : AppTheme.grey500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        subtitle: Text(
          timeago.format(notif.createdAt),
          style: theme.textTheme.labelSmall,
        ),
        trailing: notif.postPreviewUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  notif.postPreviewUrl!,
                  width: 44, height: 44, fit: BoxFit.cover,
                ),
              )
            : (notif.type == NotificationType.follow ||
                    notif.type == NotificationType.followRequest)
                ? OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Follow'),
                  )
                : null,
        onTap: () {
          if (notif.postId != null) {
            context.push('/post/${notif.postId}');
          } else {
            context.push('/profile/${notif.actorUsername}');
          }
        },
      ),
    );
  }

  String get _actionText {
    switch (notif.type) {
      case NotificationType.like: return 'liked your post';
      case NotificationType.comment: return 'commented on your post';
      case NotificationType.follow: return 'started following you';
      case NotificationType.followRequest: return 'requested to follow you';
      case NotificationType.mention: return 'mentioned you in a post';
      case NotificationType.repost: return 'reposted your post';
      case NotificationType.reply: return 'replied to your post';
      case NotificationType.pollVote: return 'voted in your poll';
      case NotificationType.storyView: return 'viewed your story';
      case NotificationType.liveStart: return 'started a live stream';
      case NotificationType.newPost: return 'posted something new';
      case NotificationType.adminAction: return notif.message;
      case NotificationType.verifiedBadge: return 'You\'ve been verified! ✓';
      case NotificationType.systemMessage: return notif.message;
    }
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// lib/screens/profile/edit_profile_screen.dart
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/nexus_text_field.dart';
import '../../widgets/nexus_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _locationCtrl;
  bool _isPrivate = false;
  bool _isSaving = false;
  File? _newAvatar;
  File? _newCover;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _websiteCtrl = TextEditingController(text: user?.website ?? '');
    _locationCtrl = TextEditingController(text: user?.location ?? '');
    _isPrivate = user?.isPrivate ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _websiteCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _newAvatar = File(file.path));
  }

  Future<void> _pickCover() async {
    final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _newCover = File(file.path));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id ?? '';
      String? avatarUrl;
      String? coverUrl;

      if (_newAvatar != null) {
        final path = 'avatars/$userId.jpg';
        await Supabase.instance.client.storage
            .from('avatars')
            .upload(path, _newAvatar!, fileOptions: const FileOptions(upsert: true));
        avatarUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
      }

      if (_newCover != null) {
        final path = 'covers/$userId.jpg';
        await Supabase.instance.client.storage
            .from('avatars')
            .upload(path, _newCover!, fileOptions: const FileOptions(upsert: true));
        coverUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
      }

      final updatedUser = await _authService.updateProfile(
        userId: userId,
        displayName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        isPrivate: _isPrivate,
      );

      if (avatarUrl != null || coverUrl != null) {
        final updates = <String, dynamic>{};
        if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
        if (coverUrl != null) updates['cover_image_url'] = coverUrl;
        await Supabase.instance.client
            .from('profiles')
            .update(updates)
            .eq('id', userId);
      }

      if (mounted) {
        context.read<AuthProvider>().updateCurrentUser(updatedUser);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text('Cancel',
              style: TextStyle(
                  color: isDark ? AppTheme.white : AppTheme.black)),
        ),
        leadingWidth: 80,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: Size.zero,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover photo
            GestureDetector(
              onTap: _pickCover,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                    child: _newCover != null
                        ? Image.file(_newCover!, fit: BoxFit.cover)
                        : user?.coverImageUrl != null
                            ? Image.network(user!.coverImageUrl!, fit: BoxFit.cover)
                            : Icon(Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: isDark ? AppTheme.grey600 : AppTheme.grey400),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            // Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, -32),
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.black : AppTheme.white,
                          shape: BoxShape.circle,
                        ),
                        child: _newAvatar != null
                            ? ClipOval(
                                child: Image.file(_newAvatar!,
                                    width: 80, height: 80, fit: BoxFit.cover),
                              )
                            : UserAvatar(
                                imageUrl: user?.avatarUrl,
                                name: user?.displayName ?? '',
                                radius: 40,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.white : AppTheme.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppTheme.black : AppTheme.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(Icons.camera_alt_rounded, size: 14,
                              color: isDark ? AppTheme.black : AppTheme.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form fields
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  NexusTextField(
                    controller: _nameCtrl,
                    label: 'Display Name',
                    prefixIcon: Icons.badge_outlined,
                    maxLength: 50,
                  ),
                  const SizedBox(height: 14),
                  NexusTextField(
                    controller: _bioCtrl,
                    label: 'Bio',
                    hint: 'Tell the world about yourself...',
                    prefixIcon: Icons.info_outline_rounded,
                    maxLines: 4,
                    maxLength: 160,
                  ),
                  const SizedBox(height: 14),
                  NexusTextField(
                    controller: _websiteCtrl,
                    label: 'Website',
                    hint: 'https://yoursite.com',
                    prefixIcon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  NexusTextField(
                    controller: _locationCtrl,
                    label: 'Location',
                    hint: 'City, Country',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Private account toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 22,
                            color: isDark ? AppTheme.grey400 : AppTheme.grey500),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Private Account', style: theme.textTheme.titleSmall),
                              Text('Only approved followers can see your posts',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPrivate,
                          onChanged: (v) => setState(() => _isPrivate = v),
                          activeColor: isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
