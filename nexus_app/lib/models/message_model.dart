// lib/models/message_model.dart

enum MessageType { text, image, video, audio, gif, sticker, post, story, location, deleted }
enum MessageStatus { sending, sent, delivered, read, failed }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String? senderAvatarUrl;

  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final double? mediaAspectRatio;
  final String? replyToId;
  final MessageModel? replyTo;
  final String? sharedPostId;
  final Map<String, dynamic>? metadata;

  final MessageStatus status;
  final Map<String, List<String>> reactions; // emoji -> [userId, ...]
  final bool isEdited;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    this.senderAvatarUrl,
    required this.type,
    this.text,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaAspectRatio,
    this.replyToId,
    this.replyTo,
    this.sharedPostId,
    this.metadata,
    this.status = MessageStatus.sent,
    this.reactions = const {},
    this.isEdited = false,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final senderData = json['sender'] as Map<String, dynamic>?;
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderUsername: senderData?['username'] as String? ?? '',
      senderAvatarUrl: senderData?['avatar_url'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      text: json['text'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaThumbnailUrl: json['media_thumbnail_url'] as String?,
      mediaAspectRatio: (json['media_aspect_ratio'] as num?)?.toDouble(),
      replyToId: json['reply_to_id'] as String?,
      sharedPostId: json['shared_post_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      reactions: Map<String, List<String>>.from(
        (json['reactions'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        ),
      ),
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at'] as String) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  bool get isDeleted => deletedAt != null;
  bool get hasReactions => reactions.isNotEmpty;
  int get totalReactions => reactions.values.fold(0, (sum, list) => sum + list.length);
}

class ConversationModel {
  final String id;
  final bool isGroup;
  final String? groupName;
  final String? groupAvatarUrl;
  final List<String> participantIds;
  final List<Map<String, dynamic>> participants;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isMuted;
  final bool isArchived;
  final Map<String, dynamic>? metadata;

  const ConversationModel({
    required this.id,
    this.isGroup = false,
    this.groupName,
    this.groupAvatarUrl,
    required this.participantIds,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isMuted = false,
    this.isArchived = false,
    this.metadata,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      isGroup: json['is_group'] as bool? ?? false,
      groupName: json['group_name'] as String?,
      groupAvatarUrl: json['group_avatar_url'] as String?,
      participantIds: List<String>.from(json['participant_ids'] as List? ?? []),
      participants: List<Map<String, dynamic>>.from(json['participants'] as List? ?? []),
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      isMuted: json['is_muted'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  String getDisplayName(String currentUserId) {
    if (isGroup) return groupName ?? 'Group';
    final other = participants.firstWhere(
      (p) => p['id'] != currentUserId,
      orElse: () => {},
    );
    return other['display_name'] as String? ?? other['username'] as String? ?? 'Unknown';
  }

  String? getDisplayAvatar(String currentUserId) {
    if (isGroup) return groupAvatarUrl;
    final other = participants.firstWhere(
      (p) => p['id'] != currentUserId,
      orElse: () => {},
    );
    return other['avatar_url'] as String?;
  }
}
