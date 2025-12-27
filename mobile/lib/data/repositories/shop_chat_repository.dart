import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../data.dart';

/// Repository for handling shop chat operations (separate from auction chats)
class ShopChatRepository {
  final DioClient _client;

  ShopChatRepository(this._client);

  /// Get all shop conversations for the current user
  Future<List<ShopConversation>> getConversations() async {
    try {
      final response = await _client.get('/shop-chats');
      final List<dynamic> list = response.data['conversations'] ?? [];
      return list.map((json) => ShopConversation.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get messages for a conversation
  Future<List<ShopMessage>> getMessages(String conversationId) async {
    try {
      final response = await _client.get('/shop-chats/$conversationId/messages');
      final List<dynamic> list = response.data['messages'] ?? [];
      return list.map((json) => ShopMessage.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Send a message in a conversation
  Future<ShopMessage> sendMessage(String conversationId, String content, {String? productId}) async {
    try {
      final response = await _client.post('/shop-chats/$conversationId/messages', data: {
        'content': content,
        if (productId != null) 'product_id': productId,
      });
      return ShopMessage.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Start a new conversation with a store
  Future<String> startConversation(String storeId, {String? productId, String? message}) async {
    try {
      final response = await _client.post('/shop-chats/start', data: {
        'store_id': storeId,
        if (productId != null) 'product_id': productId,
        if (message != null) 'message': message,
      });
      return response.data['conversation_id'];
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a conversation as read
  Future<void> markAsRead(String conversationId) async {
    try {
      await _client.put('/shop-chats/$conversationId/read', data: {});
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final response = await _client.get('/shop-chats/unread-count');
      return response.data['unread_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

// ============ MODELS ============

class ShopConversation {
  final String id;
  final String storeId;
  final String storeName;
  final String? storeLogo;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final String? productId;
  final String? productTitle;
  final String? productImage;
  final bool isStoreOwner;
  final String otherName;
  final String? otherAvatar;
  final ShopLastMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  ShopConversation({
    required this.id,
    required this.storeId,
    required this.storeName,
    this.storeLogo,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    this.productId,
    this.productTitle,
    this.productImage,
    required this.isStoreOwner,
    required this.otherName,
    this.otherAvatar,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ShopConversation.fromJson(Map<String, dynamic> json) {
    return ShopConversation(
      id: json['id'] ?? '',
      storeId: json['store_id'] ?? '',
      storeName: json['store_name'] ?? '',
      storeLogo: json['store_logo'],
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerAvatar: json['customer_avatar'],
      productId: json['product_id'],
      productTitle: json['product_title'],
      productImage: json['product_image'],
      isStoreOwner: json['is_store_owner'] ?? false,
      otherName: json['other_name'] ?? '',
      otherAvatar: json['other_avatar'],
      lastMessage: json['last_message'] != null 
          ? ShopLastMessage.fromJson(json['last_message']) 
          : null,
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class ShopLastMessage {
  final String content;
  final DateTime createdAt;

  ShopLastMessage({required this.content, required this.createdAt});

  factory ShopLastMessage.fromJson(Map<String, dynamic> json) {
    return ShopLastMessage(
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class ShopMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final String messageType;
  final String? productId;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime createdAt;

  ShopMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    this.messageType = 'text',
    this.productId,
    this.attachmentUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory ShopMessage.fromJson(Map<String, dynamic> json) {
    return ShopMessage(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'text',
      productId: json['product_id'],
      attachmentUrl: json['attachment_url'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// ============ PROVIDERS ============

final shopChatRepositoryProvider = Provider<ShopChatRepository>((ref) {
  return ShopChatRepository(ref.watch(dioClientProvider));
});

final shopConversationsProvider = FutureProvider<List<ShopConversation>>((ref) async {
  return ref.watch(shopChatRepositoryProvider).getConversations();
});

final shopMessagesProvider = FutureProvider.family<List<ShopMessage>, String>((ref, conversationId) async {
  return ref.watch(shopChatRepositoryProvider).getMessages(conversationId);
});

final unreadShopChatCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(shopChatRepositoryProvider).getUnreadCount();
});
