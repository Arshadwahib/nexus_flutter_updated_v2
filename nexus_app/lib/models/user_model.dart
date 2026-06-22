// lib/models/user_model.dart

enum UserRole { user, admin }

class UserModel {
  final String id;
  final String email;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String? website;
  final String? location;
  final bool isVerified;         // Blue tick
  final bool isAdmin;
  final UserRole role;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final DateTime createdAt;
  final bool isPrivate;
  final bool isActive;
  final String? coverImageUrl;
  final List<String> interests;
  final bool notificationsEnabled;
  final String? pushToken;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.website,
    this.location,
    this.isVerified = false,
    this.isAdmin = false,
    this.role = UserRole.user,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    required this.createdAt,
    this.isPrivate = false,
    this.isActive = true,
    this.coverImageUrl,
    this.interests = const [],
    this.notificationsEnabled = true,
    this.pushToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String? ?? json['username'],
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      website: json['website'] as String?,
      location: json['location'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      role: (json['role'] as String?) == 'admin' ? UserRole.admin : UserRole.user,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPrivate: json['is_private'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      coverImageUrl: json['cover_image_url'] as String?,
      interests: List<String>.from(json['interests'] as List? ?? []),
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      pushToken: json['push_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'bio': bio,
    'website': website,
    'location': location,
    'is_verified': isVerified,
    'is_admin': isAdmin,
    'role': role.name,
    'followers_count': followersCount,
    'following_count': followingCount,
    'posts_count': postsCount,
    'created_at': createdAt.toIso8601String(),
    'is_private': isPrivate,
    'is_active': isActive,
    'cover_image_url': coverImageUrl,
    'interests': interests,
    'notifications_enabled': notificationsEnabled,
    'push_token': pushToken,
  };

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? website,
    String? location,
    bool? isVerified,
    bool? isAdmin,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isPrivate,
    bool? isActive,
    String? coverImageUrl,
    List<String>? interests,
    bool? notificationsEnabled,
    String? pushToken,
  }) {
    return UserModel(
      id: id,
      email: email,
      username: username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      role: isAdmin == true ? UserRole.admin : role,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      createdAt: createdAt,
      isPrivate: isPrivate ?? this.isPrivate,
      isActive: isActive ?? this.isActive,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      interests: interests ?? this.interests,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pushToken: pushToken ?? this.pushToken,
    );
  }

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
