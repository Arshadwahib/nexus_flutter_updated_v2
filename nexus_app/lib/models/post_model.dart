// lib/models/post_model.dart

enum PostType { text, image, video, reel, story, poll, thread, audio }
enum PostVisibility { everyone, followers, mutuals, onlyMe }

class MediaItem {
  final String url;
  final String? thumbnailUrl;
  final double? aspectRatio;
  final bool isVideo;
  final int? durationSeconds;

  const MediaItem({
    required this.url,
    this.thumbnailUrl,
    this.aspectRatio,
    this.isVideo = false,
    this.durationSeconds,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
    url: json['url'] as String,
    thumbnailUrl: json['thumbnail_url'] as String?,
    aspectRatio: (json['aspect_ratio'] as num?)?.toDouble(),
    isVideo: json['is_video'] as bool? ?? false,
    durationSeconds: json['duration_seconds'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'thumbnail_url': thumbnailUrl,
    'aspect_ratio': aspectRatio,
    'is_video': isVideo,
    'duration_seconds': durationSeconds,
  };
}

class PollOption {
  final String id;
  final String text;
  final int voteCount;
  final bool hasVoted;

  const PollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.hasVoted = false,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
    id: json['id'] as String,
    text: json['text'] as String,
    voteCount: json['vote_count'] as int? ?? 0,
    hasVoted: json['has_voted'] as bool? ?? false,
  );
}

class PostModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorDisplayName;
  final String? authorAvatarUrl;
  final bool authorIsVerified;
  final bool authorIsAdmin;

  final String? text;
  final PostType type;
  final PostVisibility visibility;
  final List<MediaItem> media;
  final List<PollOption>? pollOptions;
  final DateTime? pollExpiresAt;

  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final int viewsCount;
  final int sharesCount;
  final int bookmarksCount;

  final bool isLiked;
  final bool isReposted;
  final bool isBookmarked;

  final String? repostOfId;         // If this is a repost
  final PostModel? repostOf;        // Original post data
  final String? replyToId;          // If this is a reply
  final String? threadId;           // Thread chain ID

  final List<String> hashtags;
  final List<String> mentions;
  final String? location;
  final Map<String, dynamic>? metadata;

  final bool isPinned;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? expiresAt;        // For stories

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorDisplayName,
    this.authorAvatarUrl,
    this.authorIsVerified = false,
    this.authorIsAdmin = false,
    this.text,
    required this.type,
    this.visibility = PostVisibility.everyone,
    this.media = const [],
    this.pollOptions,
    this.pollExpiresAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.repostsCount = 0,
    this.viewsCount = 0,
    this.sharesCount = 0,
    this.bookmarksCount = 0,
    this.isLiked = false,
    this.isReposted = false,
    this.isBookmarked = false,
    this.repostOfId,
    this.repostOf,
    this.replyToId,
    this.threadId,
    this.hashtags = const [],
    this.mentions = const [],
    this.location,
    this.metadata,
    this.isPinned = false,
    this.isEdited = false,
    required this.createdAt,
    this.editedAt,
    this.expiresAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final authorData = json['author'] as Map<String, dynamic>?;
    return PostModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: authorData?['username'] as String? ?? '',
      authorDisplayName: authorData?['display_name'] as String? ?? '',
      authorAvatarUrl: authorData?['avatar_url'] as String?,
      authorIsVerified: authorData?['is_verified'] as bool? ?? false,
      authorIsAdmin: authorData?['is_admin'] as bool? ?? false,
      text: json['text'] as String?,
      type: PostType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'text'),
        orElse: () => PostType.text,
      ),
      visibility: PostVisibility.values.firstWhere(
        (e) => e.name == (json['visibility'] as String? ?? 'everyone'),
        orElse: () => PostVisibility.everyone,
      ),
      media: (json['media'] as List<dynamic>? ?? [])
          .map((m) => MediaItem.fromJson(m as Map<String, dynamic>))
          .toList(),
      pollOptions: (json['poll_options'] as List<dynamic>?)
          ?.map((o) => PollOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      pollExpiresAt: json['poll_expires_at'] != null
          ? DateTime.parse(json['poll_expires_at'] as String)
          : null,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      repostsCount: json['reposts_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
      bookmarksCount: json['bookmarks_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isReposted: json['is_reposted'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      repostOfId: json['repost_of_id'] as String?,
      repostOf: json['repost_of'] != null
          ? PostModel.fromJson(json['repost_of'] as Map<String, dynamic>)
          : null,
      replyToId: json['reply_to_id'] as String?,
      threadId: json['thread_id'] as String?,
      hashtags: List<String>.from(json['hashtags'] as List? ?? []),
      mentions: List<String>.from(json['mentions'] as List? ?? []),
      location: json['location'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isPinned: json['is_pinned'] as bool? ?? false,
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  bool get hasMedia => media.isNotEmpty;
  bool get isStory => type == PostType.story;
  bool get isReel => type == PostType.reel;
  bool get isPoll => type == PostType.poll;
  bool get isThread => type == PostType.thread;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  int get totalPollVotes =>
      pollOptions?.fold(0, (sum, opt) => sum! + opt.voteCount) ?? 0;

  PostModel copyWith({
    bool? isLiked,
    bool? isReposted,
    bool? isBookmarked,
    int? likesCount,
    int? commentsCount,
    int? repostsCount,
    int? bookmarksCount,
    int? viewsCount,
    bool? isPinned,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      authorUsername: authorUsername,
      authorDisplayName: authorDisplayName,
      authorAvatarUrl: authorAvatarUrl,
      authorIsVerified: authorIsVerified,
      authorIsAdmin: authorIsAdmin,
      text: text,
      type: type,
      visibility: visibility,
      media: media,
      pollOptions: pollOptions,
      pollExpiresAt: pollExpiresAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      repostsCount: repostsCount ?? this.repostsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      sharesCount: sharesCount,
      bookmarksCount: bookmarksCount ?? this.bookmarksCount,
      isLiked: isLiked ?? this.isLiked,
      isReposted: isReposted ?? this.isReposted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      repostOfId: repostOfId,
      repostOf: repostOf,
      replyToId: replyToId,
      threadId: threadId,
      hashtags: hashtags,
      mentions: mentions,
      location: location,
      metadata: metadata,
      isPinned: isPinned ?? this.isPinned,
      isEdited: isEdited,
      createdAt: createdAt,
      editedAt: editedAt,
      expiresAt: expiresAt,
    );
  }
}
