// lib/screens/profile/edit_profile_screen.dart
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
import '../../widgets/nexus_logo.dart';

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
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _newAvatar = File(file.path));
  }

  Future<void> _pickCover() async {
    final XFile? file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _newCover = File(file.path));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id ?? '';
      String? avatarUrl;
      String? coverUrl;

      if (_newAvatar != null) {
        const path = 'avatar.jpg';
        await Supabase.instance.client.storage
            .from('avatars')
            .upload('$userId/$path', _newAvatar!,
                fileOptions: const FileOptions(upsert: true));
        avatarUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl('$userId/$path');
      }

      if (_newCover != null) {
        const path = 'cover.jpg';
        await Supabase.instance.client.storage
            .from('avatars')
            .upload('$userId/$path', _newCover!,
                fileOptions: const FileOptions(upsert: true));
        coverUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl('$userId/$path');
      }

      final updatedUser = await _authService.updateProfile(
        userId: userId,
        displayName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        website:
            _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
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
            content: const Text('Profile updated successfully!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
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
          child: Text(
            'Cancel',
            style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black, fontSize: 15),
          ),
        ),
        leadingWidth: 80,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
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
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Photo ────────────────────────────────────────────
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
                            ? Image.network(user!.coverImageUrl!,
                                fit: BoxFit.cover)
                            : Center(
                                child: Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 36,
                                  color: isDark
                                      ? AppTheme.grey600
                                      : AppTheme.grey400,
                                ),
                              ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            // ── Avatar overlay ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Transform.translate(
                offset: const Offset(0, -36),
                child: Row(
                  children: [
                    GestureDetector(
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
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover),
                                  )
                                : UserAvatar(
                                    imageUrl: user?.avatarUrl,
                                    name: user?.displayName ?? '',
                                    radius: 42,
                                  ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.white
                                    : AppTheme.black,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.black
                                      : AppTheme.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 13,
                                color: isDark
                                    ? AppTheme.black
                                    : AppTheme.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Form ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Display Name', isDark),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _nameCtrl,
                    hint: 'Your name',
                    icon: Icons.badge_outlined,
                    isDark: isDark,
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),

                  _FieldLabel('Bio', isDark),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _bioCtrl,
                    hint: 'Tell the world about yourself...',
                    icon: Icons.info_outline_rounded,
                    isDark: isDark,
                    maxLines: 4,
                    maxLength: 160,
                  ),
                  const SizedBox(height: 16),

                  _FieldLabel('Website', isDark),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _websiteCtrl,
                    hint: 'https://yoursite.com',
                    icon: Icons.link_rounded,
                    isDark: isDark,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),

                  _FieldLabel('Location', isDark),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: _locationCtrl,
                    hint: 'City, Country',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // ── Private Account ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.grey800
                                : AppTheme.grey200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.lock_outline_rounded,
                              size: 20,
                              color: isDark
                                  ? AppTheme.grey400
                                  : AppTheme.grey500),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Private Account',
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                'Only approved followers can see your posts',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPrivate,
                          onChanged: (v) =>
                              setState(() => _isPrivate = v),
                          activeColor:
                              isDark ? AppTheme.white : AppTheme.black,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Notification Preferences ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.grey800
                                : AppTheme.grey200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.notifications_outlined,
                              size: 20,
                              color: isDark
                                  ? AppTheme.grey400
                                  : AppTheme.grey500),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Push Notifications',
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                'Get notified about likes, comments, follows',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: true,
                          onChanged: (v) {},
                          activeColor:
                              isDark ? AppTheme.white : AppTheme.black,
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? AppTheme.grey900 : AppTheme.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppTheme.grey800 : AppTheme.grey200,
              width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppTheme.white : AppTheme.black, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
            color: isDark ? AppTheme.grey600 : AppTheme.grey400, fontSize: 15),
        counterText: '',
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.grey400 : AppTheme.grey500,
        letterSpacing: 0.3,
      ),
    );
  }
}
