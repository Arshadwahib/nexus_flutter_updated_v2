// lib/screens/home/create_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/post_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class CreatePostScreen extends StatefulWidget {
  final PostType initialType;
  const CreatePostScreen({super.key, this.initialType = PostType.text});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  final _postService = PostService();
  final _picker = ImagePicker();

  PostType _selectedType = PostType.text;
  PostVisibility _visibility = PostVisibility.everyone;
  List<File> _mediaFiles = [];
  List<String> _pollOptions = ['', ''];
  DateTime? _pollExpiry;
  String? _location;
  bool _isPosting = false;
  int _charCount = 0;
  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _textController.addListener(() {
      setState(() => _charCount = _textController.text.length);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({bool video = false}) async {
    final XFile? file = video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _mediaFiles.add(File(file.path)));
  }

  Future<void> _pickMultipleImages() async {
    final List<XFile> files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isNotEmpty) {
      setState(() => _mediaFiles.addAll(files.take(10).map((f) => File(f.path))));
    }
  }

  Future<void> _post() async {
    if (_isPosting) return;
    final text = _textController.text.trim();
    if (text.isEmpty && _mediaFiles.isEmpty) {
      _showSnack('Add some content to post');
      return;
    }
    setState(() => _isPosting = true);
    try {
      final userId = context.read<AuthProvider>().currentUser!.id;
      final post = await _postService.createPost(
        authorId: userId,
        type: _selectedType,
        text: text.isEmpty ? null : text,
        mediaFiles: _mediaFiles.isNotEmpty ? _mediaFiles : null,
        pollOptions: _selectedType == PostType.poll
            ? _pollOptions.where((o) => o.trim().isNotEmpty).toList()
            : null,
        pollExpiresAt: _pollExpiry,
        visibility: _visibility,
        location: _location,
      );
      if (mounted) {
        context.read<FeedProvider>().addNewPost(post);
        context.pop();
        _showSnack('Posted successfully!', success: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to post. Please try again.');
        setState(() => _isPosting = false);
      }
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppTheme.success : AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;
    final remaining = _maxChars - _charCount;
    final isOverLimit = remaining < 0;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text('Cancel',
              style: TextStyle(
                  color: isDark ? AppTheme.white : AppTheme.black, fontSize: 15)),
        ),
        leadingWidth: 80,
        title: _VisibilityPicker(
          current: _visibility,
          isDark: isDark,
          onChanged: (v) => setState(() => _visibility = v),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: isOverLimit || _isPosting ? null : _post,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: Size.zero,
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Type chips
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.grey900 : AppTheme.grey200,
                  width: 0.5,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _TypeChip(label: 'Text', icon: Icons.article_outlined,
                      isSelected: _selectedType == PostType.text, isDark: isDark,
                      onTap: () => setState(() => _selectedType = PostType.text)),
                  _TypeChip(label: 'Photo', icon: Icons.photo_outlined,
                      isSelected: _selectedType == PostType.image, isDark: isDark,
                      onTap: () { setState(() => _selectedType = PostType.image); _pickMultipleImages(); }),
                  _TypeChip(label: 'Video', icon: Icons.videocam_outlined,
                      isSelected: _selectedType == PostType.video, isDark: isDark,
                      onTap: () { setState(() => _selectedType = PostType.video); _pickMedia(video: true); }),
                  _TypeChip(label: 'Reel', icon: Icons.play_circle_outline_rounded,
                      isSelected: _selectedType == PostType.reel, isDark: isDark,
                      onTap: () { setState(() => _selectedType = PostType.reel); _pickMedia(video: true); }),
                  _TypeChip(label: 'Story', icon: Icons.circle_outlined,
                      isSelected: _selectedType == PostType.story, isDark: isDark,
                      onTap: () { setState(() => _selectedType = PostType.story); _pickMedia(); }),
                  _TypeChip(label: 'Poll', icon: Icons.bar_chart_rounded,
                      isSelected: _selectedType == PostType.poll, isDark: isDark,
                      onTap: () => setState(() => _selectedType = PostType.poll)),
                  _TypeChip(label: 'Thread', icon: Icons.format_list_bulleted_rounded,
                      isSelected: _selectedType == PostType.thread, isDark: isDark,
                      onTap: () => setState(() => _selectedType = PostType.thread)),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        imageUrl: user?.avatarUrl,
                        name: user?.displayName ?? '',
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          minLines: 4,
                          autofocus: true,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: _hintText,
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(
                              color: isDark ? AppTheme.grey600 : AppTheme.grey400,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Media preview strip
                  if (_mediaFiles.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 104,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mediaFiles.length + (_mediaFiles.length < 10 ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _mediaFiles.length) {
                            return GestureDetector(
                              onTap: _pickMultipleImages,
                              child: Container(
                                width: 104,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isDark ? AppTheme.grey700 : AppTheme.grey300),
                                ),
                                child: Icon(Icons.add_rounded,
                                    color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                                    size: 30),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              Container(
                                width: 104,
                                height: 104,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(_mediaFiles[i]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => setState(() => _mediaFiles.removeAt(i)),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  // Poll builder
                  if (_selectedType == PostType.poll) ...[
                    const SizedBox(height: 16),
                    _buildPollBuilder(isDark, theme),
                  ],

                  // Location chip
                  if (_location != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 16, color: AppTheme.accent),
                        const SizedBox(width: 6),
                        Text(_location!,
                            style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _location = null),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: AppTheme.grey400),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom toolbar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.black : AppTheme.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.grey900 : AppTheme.grey200,
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: 4,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 28,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined, size: 22),
                  onPressed: _pickMultipleImages,
                  color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined, size: 22),
                  onPressed: () => _pickMedia(video: true),
                  color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                ),
                IconButton(
                  icon: const Icon(Icons.gif_box_outlined, size: 22),
                  onPressed: () {},
                  color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                ),
                IconButton(
                  icon: const Icon(Icons.location_on_outlined, size: 22),
                  onPressed: () => setState(() => _location = 'My Location'),
                  color: _location != null
                      ? AppTheme.accent
                      : (isDark ? AppTheme.grey500 : AppTheme.grey400),
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, size: 22),
                  onPressed: () {},
                  color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                ),
                const Spacer(),
                // Character counter ring
                if (_charCount > 0) ...[
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (_charCount / _maxChars).clamp(0.0, 1.0),
                          strokeWidth: 2.5,
                          backgroundColor:
                              isDark ? AppTheme.grey800 : AppTheme.grey200,
                          color: isOverLimit
                              ? AppTheme.danger
                              : remaining < 50
                                  ? Colors.orange
                                  : AppTheme.accent,
                        ),
                        if (remaining < 50)
                          Text(
                            '$remaining',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isOverLimit
                                  ? AppTheme.danger
                                  : isDark
                                      ? AppTheme.grey400
                                      : AppTheme.grey500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 1,
                    height: 22,
                    color: isDark ? AppTheme.grey800 : AppTheme.grey200,
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 24,
                      color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollBuilder(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Poll Options', style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        ...List.generate(_pollOptions.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => _pollOptions[i] = v,
                    decoration: InputDecoration(
                      hintText: 'Choice ${i + 1}',
                      filled: true,
                      fillColor: isDark ? AppTheme.grey900 : AppTheme.grey100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                if (_pollOptions.length > 2) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _pollOptions.removeAt(i)),
                    child: Icon(Icons.close_rounded,
                        size: 20,
                        color: isDark ? AppTheme.grey500 : AppTheme.grey400),
                  ),
                ],
              ],
            ),
          );
        }),
        if (_pollOptions.length < 4)
          TextButton.icon(
            onPressed: () => setState(() => _pollOptions.add('')),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add option'),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.accent),
          ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate:
                  DateTime.now().add(const Duration(days: 7)),
            );
            if (picked != null) setState(() => _pollExpiry = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.grey900 : AppTheme.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 18,
                    color: isDark
                        ? AppTheme.grey500
                        : AppTheme.grey400),
                const SizedBox(width: 10),
                Text(
                  _pollExpiry != null
                      ? 'Expires: ${_pollExpiry!.day}/${_pollExpiry!.month}/${_pollExpiry!.year}'
                      : 'Set poll expiry (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.grey500
                        : AppTheme.grey400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _hintText {
    switch (_selectedType) {
      case PostType.text:   return "What's on your mind?";
      case PostType.image:  return "Write a caption...";
      case PostType.video:  return "Describe your video...";
      case PostType.reel:   return "Add a caption...";
      case PostType.story:  return "Add text to your story...";
      case PostType.poll:   return "Ask your question...";
      case PostType.thread: return "Start your thread...";
      case PostType.audio:  return "Describe your audio...";
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.white : AppTheme.black)
              : (isDark ? AppTheme.grey900 : AppTheme.grey100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: isSelected
                    ? (isDark ? AppTheme.black : AppTheme.white)
                    : (isDark ? AppTheme.grey500 : AppTheme.grey400)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppTheme.black : AppTheme.white)
                    : (isDark ? AppTheme.grey500 : AppTheme.grey400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityPicker extends StatelessWidget {
  final PostVisibility current;
  final bool isDark;
  final void Function(PostVisibility) onChanged;

  const _VisibilityPicker(
      {required this.current, required this.isDark, required this.onChanged});

  IconData get _icon {
    switch (current) {
      case PostVisibility.everyone:  return Icons.public_rounded;
      case PostVisibility.followers: return Icons.people_rounded;
      case PostVisibility.mutuals:   return Icons.group_rounded;
      case PostVisibility.onlyMe:    return Icons.lock_rounded;
    }
  }

  String get _label {
    switch (current) {
      case PostVisibility.everyone:  return 'Everyone';
      case PostVisibility.followers: return 'Followers';
      case PostVisibility.mutuals:   return 'Mutuals';
      case PostVisibility.onlyMe:    return 'Only Me';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.grey900 : AppTheme.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon,
                size: 14,
                color: isDark ? AppTheme.grey400 : AppTheme.grey500),
            const SizedBox(width: 6),
            Text(_label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.grey300 : AppTheme.grey600)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isDark ? AppTheme.grey400 : AppTheme.grey500),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
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
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.grey700 : AppTheme.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Who can see this?',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.white : AppTheme.black)),
              ),
            ),
            const SizedBox(height: 8),
            ...PostVisibility.values.map((v) {
              final selected = v == current;
              final icons = {
                PostVisibility.everyone: Icons.public_rounded,
                PostVisibility.followers: Icons.people_rounded,
                PostVisibility.mutuals: Icons.group_rounded,
                PostVisibility.onlyMe: Icons.lock_rounded,
              };
              final labels = {
                PostVisibility.everyone: 'Everyone',
                PostVisibility.followers: 'Followers Only',
                PostVisibility.mutuals: 'Mutuals',
                PostVisibility.onlyMe: 'Only Me',
              };
              final subtitles = {
                PostVisibility.everyone: 'Anyone on Nexus can see this',
                PostVisibility.followers: 'Only people who follow you',
                PostVisibility.mutuals: 'People you both follow each other',
                PostVisibility.onlyMe: 'Only visible to you',
              };
              return ListTile(
                leading: Icon(icons[v],
                    color: selected
                        ? (isDark ? AppTheme.white : AppTheme.black)
                        : (isDark ? AppTheme.grey500 : AppTheme.grey400)),
                title: Text(labels[v]!,
                    style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected
                            ? (isDark ? AppTheme.white : AppTheme.black)
                            : (isDark ? AppTheme.grey400 : AppTheme.grey500))),
                subtitle: Text(subtitles[v]!,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? AppTheme.grey600 : AppTheme.grey400)),
                trailing: selected
                    ? Icon(Icons.check_rounded,
                        color: isDark ? AppTheme.white : AppTheme.black)
                    : null,
                onTap: () {
                  onChanged(v);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
