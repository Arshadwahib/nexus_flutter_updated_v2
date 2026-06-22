// lib/services/chat_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Get or Create Conversation ──────────────────────────────────────
  Future<ConversationModel> getOrCreateConversation({
    required String userId,
    required String otherUserId,
  }) async {
    // Look for existing 1-on-1 conversation
    final existing = await _supabase
        .from('conversations')
        .select('''
          *,
          participants:conversation_participants(
            user:profiles(id, username, display_name, avatar_url, is_verified)
          )
        ''')
        .eq('is_group', false)
        .contains('participant_ids', [userId, otherUserId])
        .maybeSingle();

    if (existing != null) {
      return _parseConversation(existing as Map<String, dynamic>);
    }

    // Create new conversation
    final convoData = {
      'is_group': false,
      'participant_ids': [userId, otherUserId],
      'unread_count': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final created = await _supabase
        .from('conversations')
        .insert(convoData)
        .select()
        .single();

    // Add participants
    await _supabase.from('conversation_participants').insert([
      {'conversation_id': created['id'], 'user_id': userId},
      {'conversation_id': created['id'], 'user_id': otherUserId},
    ]);

    return ConversationModel.fromJson(created as Map<String, dynamic>);
  }

  // ─── Create Group Chat ────────────────────────────────────────────────
  Future<ConversationModel> createGroupChat({
    required String creatorId,
    required List<String> memberIds,
    required String groupName,
    File? groupAvatar,
  }) async {
    String? avatarUrl;
    if (groupAvatar != null) {
      final path = 'groups/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('avatars').upload(path, groupAvatar);
      avatarUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    }

    final allMembers = [creatorId, ...memberIds];
    final convoData = {
      'is_group': true,
      'group_name': groupName,
      'group_avatar_url': avatarUrl,
      'participant_ids': allMembers,
      'created_by': creatorId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final created = await _supabase
        .from('conversations')
        .insert(convoData)
        .select()
        .single();

    await _supabase.from('conversation_participants').insert(
      allMembers.map((id) => {
        'conversation_id': created['id'],
        'user_id': id,
        'is_admin': id == creatorId,
      }).toList(),
    );

    return ConversationModel.fromJson(created as Map<String, dynamic>);
  }

  // ─── Fetch Conversations ──────────────────────────────────────────────
  Future<List<ConversationModel>> fetchConversations(String userId) async {
    final data = await _supabase
        .from('conversations')
        .select('''
          *,
          participants:conversation_participants(
            user:profiles(id, username, display_name, avatar_url, is_verified, is_admin)
          )
        ''')
        .contains('participant_ids', [userId])
        .eq('is_archived', false)
        .order('updated_at', ascending: false);

    final conversations = (data as List).map((json) => _parseConversation(json as Map<String, dynamic>)).toList();

    // Fetch unread counts
    for (int i = 0; i < conversations.length; i++) {
      final count = await _supabase
          .from('messages')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('conversation_id', conversations[i].id)
          .eq('is_read', false)
          .neq('sender_id', userId);
      // Note: unread count needs to be updated based on response
    }

    return conversations;
  }

  ConversationModel _parseConversation(Map<String, dynamic> json) {
    final participants = (json['participants'] as List? ?? [])
        .map((p) => p['user'] as Map<String, dynamic>)
        .toList();
    return ConversationModel.fromJson({
      ...json,
      'participants': participants,
      'participant_ids': json['participant_ids'] ?? [],
    });
  }

  // ─── Fetch Messages ───────────────────────────────────────────────────
  Future<List<MessageModel>> fetchMessages({
    required String conversationId,
    int page = 0,
  }) async {
    final data = await _supabase
        .from('messages')
        .select('''
          *,
          sender:profiles!sender_id(id, username, display_name, avatar_url, is_verified)
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .range(
          page * AppConstants.chatPageSize,
          (page + 1) * AppConstants.chatPageSize - 1,
        );

    return (data as List)
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  // ─── Real-time Message Stream ─────────────────────────────────────────
  Stream<List<MessageModel>> messagesStream(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  // ─── Send Message ─────────────────────────────────────────────────────
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required MessageType type,
    String? text,
    File? mediaFile,
    String? replyToId,
    String? sharedPostId,
    String? gifUrl,
  }) async {
    String? mediaUrl;
    if (mediaFile != null) {
      final ext = mediaFile.path.split('.').last;
      final path = '$conversationId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _supabase.storage.from(AppConstants.chatMediaBucket).upload(path, mediaFile);
      mediaUrl = _supabase.storage.from(AppConstants.chatMediaBucket).getPublicUrl(path);
    }

    if (type == MessageType.gif && gifUrl != null) {
      mediaUrl = gifUrl;
    }

    final msgData = {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'type': type.name,
      'text': text,
      'media_url': mediaUrl,
      'reply_to_id': replyToId,
      'shared_post_id': sharedPostId,
      'status': 'sent',
      'reactions': {},
      'is_edited': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    final result = await _supabase.from('messages').insert(msgData).select('''
      *,
      sender:profiles!sender_id(id, username, display_name, avatar_url, is_verified)
    ''').single();

    // Update conversation timestamp
    await _supabase
        .from('conversations')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', conversationId);

    return MessageModel.fromJson(result as Map<String, dynamic>);
  }

  // ─── React to Message ─────────────────────────────────────────────────
  Future<void> reactToMessage({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final msg = await _supabase
        .from('messages')
        .select('reactions')
        .eq('id', messageId)
        .single();

    final reactions = Map<String, List<dynamic>>.from(
      (msg['reactions'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, List<dynamic>.from(v as List)),
      ),
    );

    if (reactions[emoji] == null) {
      reactions[emoji] = [userId];
    } else if (reactions[emoji]!.contains(userId)) {
      reactions[emoji]!.remove(userId);
      if (reactions[emoji]!.isEmpty) reactions.remove(emoji);
    } else {
      reactions[emoji]!.add(userId);
    }

    await _supabase
        .from('messages')
        .update({'reactions': reactions})
        .eq('id', messageId);
  }

  // ─── Mark as Read ─────────────────────────────────────────────────────
  Future<void> markConversationRead({
    required String conversationId,
    required String userId,
  }) async {
    await _supabase
        .from('messages')
        .update({'status': 'read'})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId);
  }

  // ─── Delete Message ───────────────────────────────────────────────────
  Future<void> deleteMessage({
    required String messageId,
    required String senderId,
  }) async {
    await _supabase
        .from('messages')
        .update({
          'deleted_at': DateTime.now().toIso8601String(),
          'type': 'deleted',
          'text': null,
          'media_url': null,
        })
        .eq('id', messageId)
        .eq('sender_id', senderId);
  }

  // ─── Typing Indicator ─────────────────────────────────────────────────
  Future<void> setTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    await _supabase.from('typing_indicators').upsert({
      'conversation_id': conversationId,
      'user_id': userId,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<bool> typingStream(String conversationId, String otherUserId) {
    return _supabase
        .from('typing_indicators')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('conversation_id', conversationId)
        .map((data) {
          final indicator = data.firstWhere(
            (d) => d['user_id'] == otherUserId,
            orElse: () => {},
          );
          return indicator['is_typing'] as bool? ?? false;
        });
  }
}
