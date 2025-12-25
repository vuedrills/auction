import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/chat_repository.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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
                  ],
                ),
                
                // Custom Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _tabController.animateTo(0);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _currentTabIndex == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _currentTabIndex == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                            ),
                            child: Center(
                              child: Text('Notifications', style: AppTypography.titleSmall.copyWith(
                                color: _currentTabIndex == 0 ? AppColors.textPrimaryLight : Colors.grey,
                                fontWeight: _currentTabIndex == 0 ? FontWeight.w600 : FontWeight.w400,
                              )),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _tabController.animateTo(1);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _currentTabIndex == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _currentTabIndex == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                            ),
                            child: Center(
                              child: Text('Messages', style: AppTypography.titleSmall.copyWith(
                                color: _currentTabIndex == 1 ? AppColors.textPrimaryLight : Colors.grey,
                                fontWeight: _currentTabIndex == 1 ? FontWeight.w600 : FontWeight.w400,
                              )),
                            ),
                          ),
                        ),
                      ),
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
                _MessagesTab(),
              ],
            ),
          ),
        ],
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
    
    // For auction won/sold, try to find the chat by auction ID
    if (notification.type == NotificationType.auctionWon || 
        notification.type == NotificationType.auctionSold) {
      // Try to find the chat for this auction from the loaded chats
      final chatsAsync = ref.read(chatsProvider);
      chatsAsync.whenData((chats) {
        final matchingChat = chats.where((c) => c.auctionId == notification.auctionId).firstOrNull;
        if (matchingChat != null) {
          context.push('/chats/${matchingChat.id}');
        } else {
          // No matching chat found, go to chat list
          context.push('/chats');
        }
      });
      // If chats aren't loaded yet, just go to chat list
      if (!chatsAsync.hasValue) {
        context.push('/chats');
      }
      return;
    }
    
    // For other notifications with auction, go to auction detail
    if (notification.auctionId != null) {
      context.push('/auction/${notification.auctionId}');
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
                  backgroundImage: chat.participantAvatar != null
                    ? CachedNetworkImageProvider(chat.participantAvatar!)
                    : null,
                  child: chat.participantAvatar == null
                    ? Text(chat.participantName[0].toUpperCase(), style: AppTypography.headlineSmall.copyWith(color: AppColors.primary))
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
                        chat.participantName,
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

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
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
            if (notification.isUrgent && notification.auctionId != null) ...[
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
