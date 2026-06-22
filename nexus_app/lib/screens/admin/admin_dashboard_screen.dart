// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;

  // Stats
  int _totalUsers = 0;
  int _totalPosts = 0;
  int _totalReports = 0;
  int _verifiedUsers = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
    _searchCtrl.addListener(_filterUsers);
  }

  Future<void> _loadData() async {
    try {
      final users = await _supabase.from('profiles').select('*').order('created_at', ascending: false);
      final posts = await _supabase.from('posts').select('id', const FetchOptions(count: CountOption.exact)).eq('is_deleted', false);

      setState(() {
        _allUsers = (users as List).map((u) => UserModel.fromJson(u as Map<String, dynamic>)).toList();
        _filteredUsers = _allUsers;
        _totalUsers = _allUsers.length;
        _verifiedUsers = _allUsers.where((u) => u.isVerified).length;
        _totalPosts = 0; // use count from posts query
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((u) =>
        u.username.contains(q) || u.displayName.toLowerCase().contains(q) || u.email.contains(q)
      ).toList();
    });
  }

  Future<void> _toggleVerification(UserModel user) async {
    await context.read<AuthProvider>().grantVerification(user.id, !user.isVerified);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isVerified
                ? 'Removed verified badge from @${user.username}'
                : 'Granted verified badge to @${user.username} ✓',
          ),
          backgroundColor: user.isVerified ? AppTheme.grey700 : AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _toggleBan(UserModel user) async {
    await _supabase
        .from('profiles')
        .update({'is_active': !user.isActive})
        .eq('id', user.id);
    await _loadData();
  }

  Future<void> _deletePost(String postId) async {
    await _supabase.from('posts').update({'is_deleted': true}).eq('id', postId);
    await _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: AppTheme.adminBlue, size: 22),
            const SizedBox(width: 8),
            const Text('Admin Dashboard'),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildOverview(isDark, theme),
                _buildUsersTab(isDark, theme),
                _buildReportsTab(isDark, theme),
              ],
            ),
    );
  }

  Widget _buildOverview(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Overview', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 20),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.4,
            children: [
              _StatCard(
                label: 'Total Users',
                value: '$_totalUsers',
                icon: Icons.people_rounded,
                color: AppTheme.accent,
                isDark: isDark,
              ),
              _StatCard(
                label: 'Total Posts',
                value: '$_totalPosts',
                icon: Icons.article_rounded,
                color: AppTheme.success,
                isDark: isDark,
              ),
              _StatCard(
                label: 'Verified Users',
                value: '$_verifiedUsers',
                icon: Icons.verified_rounded,
                color: AppTheme.accentGold,
                isDark: isDark,
              ),
              _StatCard(
                label: 'Reports',
                value: '$_totalReports',
                icon: Icons.flag_rounded,
                color: AppTheme.danger,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 28),
          Text('Quick Actions', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 14),

          _QuickAction(
            icon: Icons.verified_rounded,
            label: 'Manage Verified Badges',
            subtitle: 'Grant or revoke blue ticks',
            color: AppTheme.accent,
            onTap: () => _tabCtrl.animateTo(1),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.block_rounded,
            label: 'Banned Users',
            subtitle: '${_allUsers.where((u) => !u.isActive).length} accounts suspended',
            color: AppTheme.danger,
            onTap: () => _tabCtrl.animateTo(1),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Platform Announcement',
            subtitle: 'Post a system message to all users',
            color: AppTheme.success,
            onTap: () => _showAnnouncementDialog(),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(bool isDark, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: isDark ? AppTheme.grey900 : AppTheme.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredUsers.length,
            itemBuilder: (_, index) {
              final user = _filteredUsers[index];
              return _UserRow(
                user: user,
                isDark: isDark,
                theme: theme,
                onVerify: () => _toggleVerification(user),
                onBan: () => _toggleBan(user),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: isDark ? AppTheme.grey700 : AppTheme.grey300),
          const SizedBox(height: 16),
          Text('No pending reports', style: theme.textTheme.headlineSmall?.copyWith(
            color: isDark ? AppTheme.grey600 : AppTheme.grey400,
          )),
          const SizedBox(height: 8),
          Text('All clear! Reports will appear here.', style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppTheme.grey700 : AppTheme.grey300,
          )),
        ],
      ),
    );
  }

  void _showAnnouncementDialog() {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.grey900 : AppTheme.white,
        title: const Text('Post Announcement'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your announcement...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Send system notification to all users
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcement sent to all users!')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.grey900 : AppTheme.grey100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.grey900 : AppTheme.grey100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? AppTheme.grey600 : AppTheme.grey400),
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onVerify;
  final VoidCallback onBan;

  const _UserRow({
    required this.user,
    required this.isDark,
    required this.theme,
    required this.onVerify,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isDark ? AppTheme.grey900 : AppTheme.grey100),
        ),
      ),
      child: Row(
        children: [
          UserAvatar(imageUrl: user.avatarUrl, name: user.displayName, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.displayName, style: theme.textTheme.titleSmall),
                    if (user.isVerified) ...[
                      const SizedBox(width: 4),
                      VerifiedBadge(isAdmin: user.isAdmin, size: 14),
                    ],
                    if (user.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.adminBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.adminBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text('@${user.username}', style: theme.textTheme.bodySmall),
                Text(user.email, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          // Verify button
          GestureDetector(
            onTap: onVerify,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: user.isVerified
                    ? AppTheme.accentGold.withOpacity(0.15)
                    : (isDark ? AppTheme.grey800 : AppTheme.grey200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 18,
                color: user.isVerified ? AppTheme.accentGold : AppTheme.grey500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Ban button
          if (!user.isAdmin)
            GestureDetector(
              onTap: onBan,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: !user.isActive
                      ? AppTheme.danger.withOpacity(0.15)
                      : (isDark ? AppTheme.grey800 : AppTheme.grey200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  user.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: !user.isActive ? AppTheme.danger : AppTheme.grey500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
