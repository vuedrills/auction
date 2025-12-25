import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/websocket_service.dart';

/// Notification repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(dioClientProvider));
});

/// Notification type
enum NotificationType { outbid, auctionEnding, auctionWon, auctionSold, newAuction, watchlist, message, system }

extension NotificationTypeX on NotificationType {
  static NotificationType fromString(String value) {
    switch (value) {
      case 'outbid': return NotificationType.outbid;
      case 'auction_ending': return NotificationType.auctionEnding;
      case 'auction_won': return NotificationType.auctionWon;
      case 'auction_sold': return NotificationType.auctionSold;
      case 'new_auction': return NotificationType.newAuction;
      case 'watchlist': return NotificationType.watchlist;
      case 'message': return NotificationType.message;
      default: return NotificationType.system;
    }
  }
}

/// Notification model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? auctionId;
  final String? imageUrl;
  final String? location;
  final bool isRead;
  final bool isUrgent;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  
  // Helper getter for chat_id from data
  // Handle both String and other types (UUID might come as different formats)
  String? get chatId {
    final value = data?['chat_id'];
    if (value == null) return null;
    return value.toString();
  }
  
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.auctionId,
    this.imageUrl,
    this.location,
    this.isRead = false,
    this.isUrgent = false,
    required this.createdAt,
    this.data,
  });
  
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationTypeX.fromString(json['type'] as String? ?? 'system'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      auctionId: json['auction_id'] as String?,
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      isUrgent: json['is_urgent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Notification repository
class NotificationRepository {
  final DioClient _client;
  
  NotificationRepository(this._client);
  
  /// Get notifications
  Future<List<AppNotification>> getNotifications({bool? unreadOnly, int page = 1, int limit = 50}) async {
    final response = await _client.get('/notifications', queryParameters: {
      if (unreadOnly != null) 'unread_only': unreadOnly,
      'page': page,
      'limit': limit,
    });
    return (response.data['notifications'] as List?)
        ?.map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
        .toList() ?? [];
  }
  
  /// Get notification by ID
  Future<AppNotification> getNotification(String id) async {
    final response = await _client.get('/notifications/$id');
    return AppNotification.fromJson(response.data);
  }
  
  /// Mark as read
  Future<void> markAsRead(String id) async {
    await _client.put('/notifications/$id/read');
  }
  
  /// Mark all as read
  Future<void> markAllAsRead() async {
    await _client.put('/notifications/read-all');
  }
  
  /// Delete notification
  Future<void> deleteNotification(String id) async {
    await _client.delete('/notifications/$id');
  }
  
  /// Get unread count
  Future<int> getUnreadCount() async {
    final response = await _client.get('/notifications/unread-count');
    return response.data['count'] as int? ?? 0;
  }
  
  /// Update notification preferences
  Future<void> updatePreferences(Map<String, bool> preferences) async {
    await _client.put('/users/me/notification-preferences', data: preferences);
  }
  
  /// Get notification preferences
  Future<Map<String, bool>> getPreferences() async {
    final response = await _client.get('/users/me/notification-preferences');
    return Map<String, bool>.from(response.data as Map);
  }
}

/// Notification providers
class NotificationsNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repository;
  StreamSubscription? _wsSubscription;
  
  NotificationsNotifier(this._repository, {Stream<dynamic>? notificationStream}) : super(const AsyncValue.loading()) {
    if (notificationStream != null) {
      _wsSubscription = notificationStream.listen(_handleWsNotification);
    }
  }
  
  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _handleWsNotification(dynamic message) {
    // message is likely a Map or a class with data
    final data = message.data ?? {};
    final typeStr = data['type'] as String? ?? 'system';
    
    final newNotif = AppNotification(
      id: DateTime.now().toIso8601String(), // Temporary ID for real-time
      type: NotificationTypeX.fromString(typeStr),
      title: data['title'] as String? ?? 'New Notification',
      body: data['body'] as String? ?? '',
      auctionId: data['auction_id'] as String? ?? message.auctionId,
      isRead: false,
      isUrgent: true,
      createdAt: DateTime.now(),
      data: data,
    );

    state.whenData((notifications) {
      // Avoid duplicates if possible (though temp ID makes it hard, usually we refresh anyway)
      state = AsyncValue.data([newNotif, ...notifications]);
    });
  }
  
  Future<void> load({bool refresh = false}) async {
    if (!refresh) state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    state.whenData((notifications) {
      state = AsyncValue.data(
        notifications.map((n) => n.id == id 
          ? AppNotification(
              id: n.id, type: n.type, title: n.title, body: n.body,
              auctionId: n.auctionId, imageUrl: n.imageUrl, location: n.location,
              isRead: true, isUrgent: n.isUrgent, createdAt: n.createdAt, data: n.data,
            )
          : n
        ).toList(),
      );
    });
  }
  
  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    state.whenData((notifications) {
      state = AsyncValue.data(
        notifications.map((n) => AppNotification(
          id: n.id, type: n.type, title: n.title, body: n.body,
          auctionId: n.auctionId, imageUrl: n.imageUrl, location: n.location,
          isRead: true, isUrgent: n.isUrgent, createdAt: n.createdAt, data: n.data,
        )).toList(),
      );
    });
  }
  
  Future<void> delete(String id) async {
    await _repository.deleteNotification(id);
    state.whenData((notifications) {
      state = AsyncValue.data(notifications.where((n) => n.id != id).toList());
    });
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<List<AppNotification>>>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  final notifier = NotificationsNotifier(
    ref.read(notificationRepositoryProvider),
    notificationStream: wsService.notifications,
  );
  notifier.load();
  return notifier;
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final notificationDetailProvider = FutureProvider.family<AppNotification, String>((ref, id) async {
  final repository = ref.read(notificationRepositoryProvider);
  return repository.getNotification(id);
});

final notificationPreferencesProvider = FutureProvider<Map<String, bool>>((ref) async {
  final repository = ref.read(notificationRepositoryProvider);
  return repository.getPreferences();
});
