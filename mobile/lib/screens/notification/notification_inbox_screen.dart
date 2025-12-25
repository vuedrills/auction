import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repositories/notification_repository.dart';

/// Notification Inbox Screen - Connected to Backend
class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends ConsumerState<NotificationInboxScreen> {
  bool _showNational = false;

  @override
  void initState() {
    super.initState();
    // Load notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.backgroundLight,
            title: Text('Inbox', style: AppTypography.headlineMedium),
            actions: [
              TextButton(
                onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
                child: Text('Mark all read', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          
          // Toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showNational = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_showNational ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: !_showNational ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                        ),
                        child: Center(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.location_on, size: 18, color: !_showNational ? AppColors.textPrimaryLight : Colors.grey),
                            const SizedBox(width: 6),
                            Text('My Town', style: AppTypography.titleSmall.copyWith(
                              color: !_showNational ? AppColors.textPrimaryLight : Colors.grey,
                              fontWeight: !_showNational ? FontWeight.w600 : FontWeight.w400,
                            )),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showNational = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _showNational ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _showNational ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                        ),
                        child: Center(
                          child: Text('National', style: AppTypography.titleSmall.copyWith(
                            color: _showNational ? AppColors.textPrimaryLight : Colors.grey,
                            fontWeight: _showNational ? FontWeight.w600 : FontWeight.w400,
                          )),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          
          // Notifications
          notificationsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (notifications) {
              if (notifications.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondaryLight),
                      const SizedBox(height: 16),
                      Text('No notifications yet', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                    ]),
                  ),
                );
              }
              
              // Group by date
              final today = DateTime.now();
              final todayNotifications = notifications.where((n) => _isToday(n.createdAt, today)).toList();
              final yesterdayNotifications = notifications.where((n) => _isYesterday(n.createdAt, today)).toList();
              final olderNotifications = notifications.where((n) => !_isToday(n.createdAt, today) && !_isYesterday(n.createdAt, today)).toList();
              
              return SliverList(
                delegate: SliverChildListDelegate([
                  if (todayNotifications.isNotEmpty) ...[
                    _buildDateHeader('TODAY'),
                    ...todayNotifications.map((n) => _NotificationCard(
                      notification: n,
                      onTap: () => _handleNotificationTap(n),
                      onMarkRead: () => ref.read(notificationsProvider.notifier).markAsRead(n.id),
                    )),
                  ],
                  if (yesterdayNotifications.isNotEmpty) ...[
                    _buildDateHeader('YESTERDAY'),
                    ...yesterdayNotifications.map((n) => _NotificationCard(
                      notification: n,
                      onTap: () => _handleNotificationTap(n),
                      onMarkRead: () => ref.read(notificationsProvider.notifier).markAsRead(n.id),
                    )),
                  ],
                  if (olderNotifications.isNotEmpty) ...[
                    _buildDateHeader('EARLIER'),
                    ...olderNotifications.map((n) => _NotificationCard(
                      notification: n,
                      onTap: () => _handleNotificationTap(n),
                      onMarkRead: () => ref.read(notificationsProvider.notifier).markAsRead(n.id),
                    )),
                  ],
                  const SizedBox(height: 100),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight, letterSpacing: 1)),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    if (notification.auctionId != null) {
      context.push('/auction/${notification.auctionId}');
    }
  }

  bool _isToday(DateTime date, DateTime today) {
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  bool _isYesterday(DateTime date, DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
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
        icon = Icons.check_circle;
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
