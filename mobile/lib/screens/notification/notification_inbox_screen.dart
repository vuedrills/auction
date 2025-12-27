import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/shop_chat_repository.dart';
import '../../data/repositories/auction_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Notification Inbox Screen - Connected to Backend
class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends ConsumerState<NotificationInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Now 3 tabs
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    // Load notifications and chats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load(refresh: true);
      ref.read(chatsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Custom AppBar with toggle
          Container(
            color: AppColors.backgroundLight,
            child: Column(
              children: [
                AppBar(
                  backgroundColor: AppColors.backgroundLight,
                  title: Text('Inbox', style: AppTypography.headlineMedium),
                  actions: [
                    if (_currentTabIndex == 0)
                      TextButton(
                        onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
                        child: Text('Mark all read', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                      ),
                    if (_currentTabIndex == 1)
                      TextButton(
                        onPressed: () => ref.read(chatsProvider.notifier).markAllMessagesAsRead(),
                        child: Text('Mark all read', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                      ),
                    // Tab 2 (Shops) doesn't have mark all read yet
                  ],
                ),
                
                // 3-Tab Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      // Notifications Tab
                      _buildTabButton(0, 'Alerts', Icons.notifications_outlined, 
                        ref.watch(unreadNotificationCountProvider)),
                      const SizedBox(width: 4),
                      // Auctions Tab (auction chats)
                      _buildTabButton(1, 'Auctions', Icons.gavel, 
                        ref.watch(unreadChatCountProvider)),
                      const SizedBox(width: 4),
                      // Shops Tab (shop chats)
                      _buildTabButton(2, 'Shops', Icons.storefront_outlined, 
                        ref.watch(unreadShopChatCountProvider).valueOrNull ?? 0),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _NotificationsTab(),
                _MessagesTab(),     // Auction chats
                _ShopChatsTab(),    // Shop chats (NEW)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, int count) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primary : Colors.grey),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? AppColors.textPrimaryLight : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ), overflow: TextOverflow.ellipsis),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Notifications Tab Content
class _NotificationsTab extends ConsumerWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    
    return notificationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stackTrace) {
        print('Notifications error: $e');
        print('Stack trace: $stackTrace');
        return Center(child: Text('Error: $e'));
      },
      data: (notifications) {
        if (notifications.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondaryLight),
              const SizedBox(height: 16),
              Text('No notifications yet', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
            ]),
          );
        }
        
        // Group by date
        final today = DateTime.now();
        final todayNotifications = notifications.where((n) => _isToday(n.createdAt, today)).toList();
        final yesterdayNotifications = notifications.where((n) => _isYesterday(n.createdAt, today)).toList();
        final olderNotifications = notifications.where((n) => !_isToday(n.createdAt, today) && !_isYesterday(n.createdAt, today)).toList();
        
        final List<Widget> sliverChildren = [];
        
        if (todayNotifications.isNotEmpty) {
          sliverChildren.add(SliverToBoxAdapter(child: _buildDateHeader('TODAY')));
          sliverChildren.add(SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _NotificationCard(
                notification: todayNotifications[index],
                onTap: () => _handleNotificationTap(context, ref, todayNotifications[index]),
                onMarkRead: () => ref.read(notificationsProvider.notifier).markAsRead(todayNotifications[index].id),
                onMessage: () => _handleMessageTap(context, ref, todayNotifications[index]),
              ),
              childCount: todayNotifications.length,
            ),
          ));
        }
        
        if (yesterdayNotifications.isNotEmpty) {
          sliverChildren.add(SliverToBoxAdapter(child: _buildDateHeader('YESTERDAY')));
          sliverChildren.add(SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _NotificationCard(
                notification: yesterdayNotifications[index],
                onTap: () => _handleNotificationTap(context, ref, yesterdayNotifications[index]),
                onMarkRead: () => ref.read(notificationsProvider.notifier).markAsRead(yesterdayNotifications[index].id),
                onMessage: () => _handleMessageTap(context, ref, yesterdayNotifications[index]),
              ),
              childCount: yesterdayNotifications.length,
            ),
          ));
        }
        
        if (olderNotifications.isNotEmpty) {
          sliverChildren.add(SliverToBoxAdapter(child: _buildDateHeader('EARLIER')));
          sliverChildren.add(SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _NotificationCard(
                notification: olderNotifications[index],
                onTap: () => _handleNotificationTap(context, ref, olderNotifications[index]),
                onMarkRead: () => ref.read(notificationsProvider.notifier).markAsRead(olderNotifications[index].id),
                onMessage: () => _handleMessageTap(context, ref, olderNotifications[index]),
              ),
              childCount: olderNotifications.length,
            ),
          ));
        }
        
        sliverChildren.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));
        
        return CustomScrollView(
          slivers: sliverChildren,
        );
      },
    );
  }

  static Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight, letterSpacing: 1)),
    );
  }

  static bool _isToday(DateTime date, DateTime today) {
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  static bool _isYesterday(DateTime date, DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  static void _handleNotificationTap(BuildContext context, WidgetRef ref, AppNotification notification) {
    ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    
    // If notification has a chat_id, navigate directly to that chat conversation
    if (notification.chatId != null) {
      context.push('/chats/${notification.chatId}');
      return;
    }
    
    // For auction won/sold, navigate to Rate User screen
    if (notification.type == NotificationType.auctionWon || 
        notification.type == NotificationType.auctionSold) {
        
        // If already rated, go to auction detail
        if (notification.hasRated) {
           context.push('/auction/${notification.auctionId}');
           return;
        }

        // Fetch auction to find target user
        if (notification.auctionId != null) {
          try {
             // Try to extract target user from data if available, otherwise fallback
             final targetUserId = notification.data?['related_user_id'];
             if (targetUserId != null) {
               context.push('/rate/$targetUserId?auctionId=${notification.auctionId}');
             } else {
               // Fallback if we can't find user ID easily (this might need backend update to include it)
               // For now, let's go to auction detail as a fail-safe if we can't rate
               context.push('/auction/${notification.auctionId}');
             }
          } catch (e) {
             print('Error parsing for rate: $e');
             context.push('/auction/${notification.auctionId}');
          }
        }
        return;
    }
    
    // For other notifications with auction, go to auction detail
    if (notification.auctionId != null) {
      context.push('/auction/${notification.auctionId}');
    }
  }

  static Future<void> _handleMessageTap(BuildContext context, WidgetRef ref, AppNotification notification) async {
    // Only for won/sold - these are always auction-related
    if (notification.type != NotificationType.auctionWon && notification.type != NotificationType.auctionSold) return;

    if (notification.chatId != null) {
      context.push('/chats/${notification.chatId}');
      return;
    }
    
    // Get the target user ID from notification data
    final targetUserId = notification.data?['related_user_id']?.toString();
    
    if (targetUserId == null || targetUserId.isEmpty) {
      // Fallback: Check if we have a chat with this auction
      final chatsAsync = ref.read(chatsProvider);
      String? existingChatId;
      
      chatsAsync.whenData((chats) {
          final matchingChat = chats.where((c) => c.auctionId == notification.auctionId).firstOrNull;
          if (matchingChat != null) {
            existingChatId = matchingChat.id;
          }
      });

      if (existingChatId != null) {
         context.push('/chats/$existingChatId');
         return;
      }
      
      // Can't proceed without a target user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find user to message'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    // Start auction-related chat - always pass auctionId to associate the conversation
    try {
      final chatId = await ref.read(chatRepositoryProvider).startChatWithUser(
        targetUserId, 
        auctionId: notification.auctionId,
      );
      
      // Refresh chats list to include this one
      ref.read(chatsProvider.notifier).load();
      
      if (context.mounted) {
         context.push('/chats/$chatId');
      }
    } catch (e) {
        print('Error starting chat: $e');
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open chat: $e'), backgroundColor: AppColors.error),
           );
        }
    }
  }
}

/// Messages Tab Content
class _MessagesTab extends ConsumerWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider);

    return chatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (chats) {
        if (chats.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No messages yet', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 8),
              Text('Start a conversation with a seller', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
            ]),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(chatsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (_, i) => _ChatListItem(chat: chats[i]),
          ),
        );
      },
    );
  }
}

/// Shop Chats Tab Content (NEW - separate from auction chats)
class _ShopChatsTab extends ConsumerWidget {
  const _ShopChatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(shopConversationsProvider);

    return conversationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (conversations) {
        if (conversations.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No shop messages yet', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 8),
              Text('Contact a store about their products', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
            ]),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(shopConversationsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (_, i) => _ShopChatListItem(conversation: conversations[i]),
          ),
        );
      },
    );
  }
}

/// Shop Chat List Item Widget
class _ShopChatListItem extends StatelessWidget {
  final ShopConversation conversation;

  const _ShopChatListItem({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        '/shop-chats/${conversation.id}',
        extra: {
          'storeName': conversation.storeName,
          'storeSlug': null, // Would need to add this to the model
          'productTitle': conversation.productTitle,
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: conversation.unreadCount > 0 ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                // Store logo or icon
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: conversation.otherAvatar != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: conversation.otherAvatar!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.storefront, color: Colors.green, size: 28),
                ),
                if (conversation.unreadCount > 0)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.storefront, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                conversation.otherName,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: conversation.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatTime(conversation.updatedAt),
                        style: AppTypography.labelSmall.copyWith(
                          color: conversation.unreadCount > 0 ? Colors.green : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (conversation.productTitle != null)
                    Text(
                      '📦 ${conversation.productTitle}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage?.content ?? 'No messages yet',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }
}

/// Chat List Item Widget (extracted from chat_screens.dart for reuse)
class _ChatListItem extends StatelessWidget {
  final ChatThread chat;

  const _ChatListItem({required this.chat});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/chats/${chat.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: chat.unreadCount > 0 ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: (chat.participantAvatar != null && chat.participantAvatar!.isNotEmpty)
                    ? CachedNetworkImageProvider(chat.participantAvatar!)
                    : null,
                  child: (chat.participantAvatar == null || chat.participantAvatar!.isEmpty)
                    ? Text(chat.participantName.isNotEmpty ? chat.participantName[0].toUpperCase() : '?', style: AppTypography.headlineSmall.copyWith(color: AppColors.primary))
                    : null,
                ),
                if (chat.unreadCount > 0)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${chat.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.participantName.isNotEmpty ? chat.participantName : 'Unknown User',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: chat.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatTime(chat.updatedAt),
                        style: AppTypography.labelSmall.copyWith(
                          color: chat.unreadCount > 0 ? AppColors.primary : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (chat.auctionTitle.isNotEmpty)
                    Text(
                      chat.auctionTitle,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage?.content ?? 'No messages yet',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback? onMessage;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (notification.type) {
      case NotificationType.outbid:
        icon = Icons.gavel;
        color = AppColors.primary;
        break;
      case NotificationType.auctionEnding:
        icon = Icons.timer;
        color = AppColors.warning;
        break;
      case NotificationType.auctionWon:
        icon = Icons.emoji_events;
        color = AppColors.success;
        break;
      case NotificationType.auctionSold:
        icon = Icons.sell;
        color = AppColors.success;
        break;
      case NotificationType.newAuction:
        icon = Icons.new_releases;
        color = AppColors.info;
        break;
      case NotificationType.watchlist:
        icon = Icons.visibility;
        color = AppColors.secondary;
        break;
      case NotificationType.message:
        icon = Icons.chat;
        color = AppColors.info;
        break;
      case NotificationType.system:
        icon = Icons.info;
        color = AppColors.textSecondaryLight;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: notification.isUrgent ? const Border(left: BorderSide(color: AppColors.primary, width: 4)) : null,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(notification.title, style: AppTypography.titleSmall)),
              if (!notification.isRead) 
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 4),
            Text(notification.body, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 8),
            Row(children: [
              if (notification.location != null) ...[
                Icon(Icons.place, size: 12, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(notification.location!, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(width: 8),
              ],
              Text(_formatTime(notification.createdAt), style: AppTypography.labelSmall.copyWith(
                color: notification.isUrgent ? AppColors.primary : AppColors.textSecondaryLight,
                fontWeight: notification.isUrgent ? FontWeight.w700 : null,
              )),
            ]),
            if (notification.type == NotificationType.auctionWon || notification.type == NotificationType.auctionSold) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                   if (!notification.hasRated) ...[
                     Expanded(
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: notification.type == NotificationType.auctionWon ? AppColors.success : AppColors.primary, 
                          minimumSize: const Size.fromHeight(36)
                        ),
                        child: Text(
                          notification.type == NotificationType.auctionWon ? 'Rate Seller' : 'Rate Buyer', 
                          style: AppTypography.labelMedium.copyWith(color: Colors.white)
                        ),
                      ),
                     ),
                     if (onMessage != null) const SizedBox(width: 8),
                   ],
                   if (onMessage != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onMessage,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(36),
                            side: BorderSide(color: AppColors.primary),
                          ),
                          child: Text('Message', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                        ),
                      ),
                   ],
                ],
              ),
            ] else if (notification.isUrgent && notification.auctionId != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(36)),
                child: Text('View Auction', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
              ),
            ],
          ])),
        ]),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }
}
