// lib/models/notification_model.dart

enum NotificationType {
  like,
  comment,
  follow,
  followRequest,
  mention,
  repost,
  reply,
  pollVote,
  storyView,
  liveStart,
  newPost,
  adminAction,
  verifiedBadge,
  systemMessage,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String actorId;
  final String actorUsername;
  final String actorDisplayName;
  final String? actorAvatarUrl;
  final bool actorIsVerified;
  final String? postId;
  final String? postPreviewUrl;
  final String? commentText;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.actorId,
    required this.actorUsername,
    required this.actorDisplayName,
    this.actorAvatarUrl,
    this.actorIsVerified = false,
    this.postId,
    this.postPreviewUrl,
    this.commentText,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'like'),
        orElse: () => NotificationType.like,
      ),
      actorId: json['actor_id'] as String,
      actorUsername: actor?['username'] as String? ?? '',
      actorDisplayName: actor?['display_name'] as String? ?? '',
      actorAvatarUrl: actor?['avatar_url'] as String?,
      actorIsVerified: actor?['is_verified'] as bool? ?? false,
      postId: json['post_id'] as String?,
      postPreviewUrl: json['post_preview_url'] as String?,
      commentText: json['comment_text'] as String?,
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get displayMessage {
    switch (type) {
      case NotificationType.like:
        return '$actorDisplayName liked your post.';
      case NotificationType.comment:
        return '$actorDisplayName commented: "${commentText ?? ''}"';
      case NotificationType.follow:
        return '$actorDisplayName started following you.';
      case NotificationType.followRequest:
        return '$actorDisplayName requested to follow you.';
      case NotificationType.mention:
        return '$actorDisplayName mentioned you in a post.';
      case NotificationType.repost:
        return '$actorDisplayName reposted your post.';
      case NotificationType.reply:
        return '$actorDisplayName replied to your post.';
      case NotificationType.pollVote:
        return '$actorDisplayName voted in your poll.';
      case NotificationType.storyView:
        return '$actorDisplayName viewed your story.';
      case NotificationType.liveStart:
        return '$actorDisplayName started a live stream.';
      case NotificationType.newPost:
        return '$actorDisplayName posted something new.';
      case NotificationType.adminAction:
        return message;
      case NotificationType.verifiedBadge:
        return 'Congratulations! You\'ve been awarded a verified badge. ✓';
      case NotificationType.systemMessage:
        return message;
    }
  }
}
