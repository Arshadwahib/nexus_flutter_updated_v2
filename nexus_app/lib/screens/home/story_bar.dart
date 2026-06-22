// lib/screens/home/story_bar.dart
import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class StoryBar extends StatelessWidget {
  final List<PostModel> stories;
  final UserModel? currentUser;

  const StoryBar({super.key, required this.stories, this.currentUser});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group stories by author
    final Map<String, List<PostModel>> grouped = {};
    for (final s in stories) {
      grouped.putIfAbsent(s.authorId, () => []).add(s);
    }

    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.grey900 : AppTheme.grey200,
            width: 0.5,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          // Add story button
          _StoryItem(
            name: 'Your Story',
            imageUrl: currentUser?.avatarUrl,
            isAddButton: true,
          ),
          // Other stories
          ...grouped.entries.map((entry) {
            final first = entry.value.first;
            return _StoryItem(
              name: first.authorDisplayName,
              imageUrl: first.authorAvatarUrl,
              hasStory: true,
            );
          }),
        ],
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool isAddButton;
  final bool hasStory;

  const _StoryItem({
    required this.name,
    this.imageUrl,
    this.isAddButton = false,
    this.hasStory = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Stack(
              children: [
                UserAvatar(
                  imageUrl: imageUrl,
                  name: name,
                  radius: 28,
                  hasStory: hasStory,
                ),
                if (isAddButton)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppTheme.black : AppTheme.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 60,
              child: Text(
                isAddButton ? 'Your Story' : name.split(' ').first,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
