import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';

/// Chat repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(dioClientProvider));
});

/// Chat/Message model
class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final bool isMe; // Whether this message was sent by current user
  
  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
    this.isMe = false,
  });
  
  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = (json['sender_id'] as String?) ?? '';
    return ChatMessage(
      id: (json['id'] as String?) ?? '',
      chatId: (json['chat_id'] as String?) ?? '',
      senderId: senderId,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      isMe: currentUserId != null && senderId == currentUserId,
    );
  }
}

/// Chat thread model
class ChatThread {
  final String id;
  final String auctionId;
  final String auctionTitle;
  final String? auctionImage;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  
  ChatThread({
    required this.id,
    required this.auctionId,
    required this.auctionTitle,
    this.auctionImage,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });
  
  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: (json['id'] as String?) ?? '',
      auctionId: (json['auction_id'] as String?) ?? '',
      auctionTitle: json['auction_title'] as String? ?? '',
      auctionImage: json['auction_image'] as String?,
      participantId: (json['participant_id'] as String?) ?? '',
      participantName: json['participant_name'] as String? ?? 'User',
      participantAvatar: json['participant_avatar'] as String?,
      lastMessage: (json['last_message'] != null && json['last_message']['content'] != null)
          ? ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
    );
  }
}

/// Chat repository
class ChatRepository {
  final DioClient _client;
  
  ChatRepository(this._client);
  
  /// Get chat threads
  Future<List<ChatThread>> getChats() async {
    final response = await _client.get('/chats');
    return (response.data['chats'] as List?)
        ?.map((c) => ChatThread.fromJson(c as Map<String, dynamic>))
        .toList() ?? [];
  }
  
  /// Get messages for a chat
  Future<List<ChatMessage>> getMessages(String chatId, {String? currentUserId, int page = 1, int limit = 50}) async {
    final response = await _client.get('/chats/$chatId/messages', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return (response.data['messages'] as List?)
        ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>, currentUserId: currentUserId))
        .toList() ?? [];
  }
  
  /// Send message
  Future<ChatMessage> sendMessage(String chatId, String content, {String? imageUrl, String? currentUserId}) async {
    final response = await _client.post('/chats/$chatId/messages', data: {
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
    });
    return ChatMessage.fromJson(response.data, currentUserId: currentUserId);
  }
  
  /// Start a chat (for an auction)
  Future<ChatThread> startChat(String auctionId, String message) async {
    final response = await _client.post('/auctions/$auctionId/chat', data: {
      'message': message,
    });
    return ChatThread.fromJson(response.data);
  }
  
  /// Mark chat as read
  Future<void> markAsRead(String chatId) async {
    await _client.put('/chats/$chatId/read');
  }
}

/// Chat providers
final chatsProvider = FutureProvider<List<ChatThread>>((ref) async {
  final repository = ref.read(chatRepositoryProvider);
  return repository.getChats();
});

/// Chat messages provider with current user ID for isMe
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, ({String chatId, String? userId})>((ref, params) async {
  final repository = ref.read(chatRepositoryProvider);
  return repository.getMessages(params.chatId, currentUserId: params.userId);
});

/// Unread chat count
final unreadChatCountProvider = Provider<int>((ref) {
  final chatsAsync = ref.watch(chatsProvider);
  return chatsAsync.when(
    data: (chats) => chats.fold(0, (sum, c) => sum + c.unreadCount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

