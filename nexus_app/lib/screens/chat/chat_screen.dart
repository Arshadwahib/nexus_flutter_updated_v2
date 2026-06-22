// lib/screens/chat/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/verified_badge.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUsername;
  final String? otherDisplayName;
  final String? otherAvatarUrl;
  final bool otherIsVerified;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUsername,
    this.otherDisplayName,
    this.otherAvatarUrl,
    this.otherIsVerified = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  StreamSubscription? _typingSubscription;
  Timer? _typingTimer;
  String? _replyToId;
  MessageModel? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenTyping();
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _chatService.fetchMessages(
        conversationId: widget.conversationId,
      );
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _listenTyping() {
    _typingSubscription = _chatService
        .typingStream(widget.conversationId, widget.otherUserId)
        .listen((typing) {
      if (mounted) setState(() => _isTyping = typing);
    });
  }

  void _onTextChanged() {
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    _chatService.setTyping(
      conversationId: widget.conversationId,
      userId: userId,
      isTyping: true,
    );
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _chatService.setTyping(
        conversationId: widget.conversationId,
        userId: userId,
        isTyping: false,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';

    setState(() => _isSending = true);
    _messageController.clear();
    _clearReply();

    try {
      final msg = await _chatService.sendMessage(
        conversationId: widget.conversationId,
        senderId: userId,
        type: MessageType.text,
        text: text,
        replyToId: _replyToId,
      );
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _setReply(MessageModel msg) {
    setState(() {
      _replyToId = msg.id;
      _replyToMessage = msg;
    });
    _focusNode.requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyToId = null;
      _replyToMessage = null;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = context.read<AuthProvider>().currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              UserAvatar(
                imageUrl: widget.otherAvatarUrl,
                name: widget.otherDisplayName ?? widget.otherUsername,
                radius: 18,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.otherDisplayName ?? widget.otherUsername,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (widget.otherIsVerified) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 14),
                      ],
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isTyping
                        ? Text(
                            'typing...',
                            key: const ValueKey('typing'),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.accent,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Text(
                            '@${widget.otherUsername}',
                            key: const ValueKey('username'),
                            style: theme.textTheme.labelSmall,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, size: 24),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _messages.isEmpty
                    ? _buildEmptyState(isDark, theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, index) {
                          final msg = _messages[index];
                          final isMine = msg.senderId == currentUserId;
                          final showDate = index == 0 ||
                              _messages[index - 1].createdAt.day != msg.createdAt.day;

                          return Column(
                            children: [
                              if (showDate) _DateDivider(date: msg.createdAt, isDark: isDark),
                              GestureDetector(
                                onLongPress: () => _showMessageOptions(context, msg, isMine, isDark),
                                child: _MessageBubble(
                                  message: msg,
                                  isMine: isMine,
                                  isDark: isDark,
                                  theme: theme,
                                  onReply: () => _setReply(msg),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Reply preview
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                border: Border(
                  top: BorderSide(color: isDark ? AppTheme.grey800 : AppTheme.grey200),
                ),
              ),
              child: Row(
                children: [
                  Container(width: 3, height: 36, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to @${_replyToMessage!.senderUsername}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _replyToMessage!.text ?? '[media]',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: _clearReply,
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.black : AppTheme.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.grey900 : AppTheme.grey200,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
                  onPressed: () => _showAttachOptions(context, isDark),
                  color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.grey900 : AppTheme.grey100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Message...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              hintStyle: TextStyle(
                                color: isDark ? AppTheme.grey600 : AppTheme.grey400,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.newline,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined, size: 22),
                          onPressed: () {},
                          color: isDark ? AppTheme.grey500 : AppTheme.grey400,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder(
                  valueListenable: _messageController,
                  builder: (_, ctrl, __) {
                    final hasText = (ctrl as TextEditingValue).text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: hasText ? _sendMessage : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: hasText
                              ? (isDark ? AppTheme.white : AppTheme.black)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasText ? Icons.send_rounded : Icons.mic_rounded,
                          size: 20,
                          color: hasText
                              ? (isDark ? AppTheme.black : AppTheme.white)
                              : (isDark ? AppTheme.grey500 : AppTheme.grey400),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: isDark ? AppTheme.grey700 : AppTheme.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? AppTheme.grey600 : AppTheme.grey400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to say hello!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.grey700 : AppTheme.grey300,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext ctx, MessageModel msg, bool isMine, bool isDark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? AppTheme.grey900 : AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Emoji reactions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['❤️', '😂', '😮', '😢', '👍', '👎'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _chatService.reactToMessage(
                        messageId: msg.id,
                        userId: context.read<AuthProvider>().currentUser?.id ?? '',
                        emoji: emoji,
                      );
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                _setReply(msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: msg.text ?? ''));
              },
            ),
            if (isMine)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                title: Text('Delete', style: TextStyle(color: AppTheme.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _chatService.deleteMessage(
                    messageId: msg.id,
                    senderId: context.read<AuthProvider>().currentUser?.id ?? '',
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAttachOptions(BuildContext ctx, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: isDark ? AppTheme.grey900 : AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(icon: Icons.photo_library_rounded, label: 'Gallery', color: Colors.purple),
                  _AttachOption(icon: Icons.camera_alt_rounded, label: 'Camera', color: Colors.blue),
                  _AttachOption(icon: Icons.videocam_rounded, label: 'Video', color: Colors.red),
                  _AttachOption(icon: Icons.mic_rounded, label: 'Audio', color: Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AttachOption(icon: Icons.location_on_rounded, label: 'Location', color: Colors.green),
                  _AttachOption(icon: Icons.gif_box_rounded, label: 'GIF', color: Colors.teal),
                  _AttachOption(icon: Icons.sticky_note_2_rounded, label: 'Sticker', color: Colors.amber),
                  _AttachOption(icon: Icons.insert_drive_file_rounded, label: 'File', color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onReply;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
    required this.theme,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? (isDark ? AppTheme.white : AppTheme.black)
        : (isDark ? AppTheme.grey800 : AppTheme.grey100);
    final textColor = isMine
        ? (isDark ? AppTheme.black : AppTheme.white)
        : (isDark ? AppTheme.white : AppTheme.black);

    if (message.isDeleted) {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.grey900 : AppTheme.grey100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppTheme.grey800 : AppTheme.grey200),
            ),
            child: Text(
              'Message deleted',
              style: TextStyle(
                color: isDark ? AppTheme.grey600 : AppTheme.grey400,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: isMine ? 48 : 0,
          right: isMine ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.text != null)
                    Text(
                      message.text!,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppTheme.grey600 : AppTheme.grey400,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.read
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 12,
                    color: message.status == MessageStatus.read
                        ? AppTheme.accent
                        : (isDark ? AppTheme.grey600 : AppTheme.grey400),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const _DateDivider({required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: isDark ? AppTheme.grey800 : AppTheme.grey200)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.grey600 : AppTheme.grey400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: isDark ? AppTheme.grey800 : AppTheme.grey200)),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AttachOption({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
