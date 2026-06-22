// lib/screens/chat/conversations_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  final _chatService = ChatService();
  late TabController _tabCtrl;
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    try {
      final convos = await _chatService.fetchConversations(userId);
      if (mounted) setState(() { _conversations = convos; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () => _showNewMessageSheet(isDark),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'All'), Tab(text: 'Requests')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildConversationsList(isDark, theme, currentUser?.id ?? ''),
          _buildRequests(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildConversationsList(bool isDark, ThemeData theme, String currentUserId) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 64,
                color: isDark ? AppTheme.grey700 : AppTheme.grey300),
            const SizedBox(height: 16),
            Text('No messages yet', style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? AppTheme.grey600 : AppTheme.grey400)),
            const SizedBox(height: 8),
            Text('Start a conversation', style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.grey700 : AppTheme.grey300)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      color: isDark ? AppTheme.white : AppTheme.black,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (_, i) {
          final convo = _conversations[i];
          final displayName = convo.getDisplayName(currentUserId);
          final avatarUrl = convo.getDisplayAvatar(currentUserId);
          final lastMsg = convo.lastMessage;
          final hasUnread = convo.unreadCount > 0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Stack(
              children: [
                UserAvatar(
                  imageUrl: avatarUrl,
                  name: displayName,
                  radius: 26,
                ),
                if (convo.isGroup)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.grey800 : AppTheme.grey200,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isDark ? AppTheme.black : AppTheme.white, width: 2),
                      ),
                      child: Icon(Icons.group_rounded, size: 10,
                          color: isDark ? AppTheme.grey400 : AppTheme.grey500),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  lastMsg != null ? timeago.format(lastMsg.createdAt) : '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                    color: hasUnread
                        ? (isDark ? AppTheme.white : AppTheme.black)
                        : (isDark ? AppTheme.grey600 : AppTheme.grey400),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    lastMsg?.type == MessageType.deleted
                        ? 'Message deleted'
                        : lastMsg?.text ?? (lastMsg != null ? '📎 Media' : 'Start chatting'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      color: hasUnread
                          ? (isDark ? AppTheme.grey300 : AppTheme.grey600)
                          : (isDark ? AppTheme.grey600 : AppTheme.grey400),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.white : AppTheme.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${convo.unreadCount}',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.black : AppTheme.white,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () {
              final other = convo.participants.firstWhere(
                (p) => p['id'] != currentUserId,
                orElse: () => {},
              );
              context.push(
                '/chat/${convo.id}?userId=${other['id'] ?? ''}&username=${other['username'] ?? ''}',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequests(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_chat_unread_outlined, size: 56,
              color: isDark ? AppTheme.grey700 : AppTheme.grey300),
          const SizedBox(height: 14),
          Text('No message requests', style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? AppTheme.grey600 : AppTheme.grey400)),
        ],
      ),
    );
  }

  void _showNewMessageSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.grey900 : AppTheme.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.grey700 : AppTheme.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('New Message',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text('Search for people to message',
                    style: TextStyle(
                        color: isDark ? AppTheme.grey600 : AppTheme.grey400)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
