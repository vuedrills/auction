import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/repositories/notification_repository.dart';

/// Notification Detail Screen - Connected to Backend
class NotificationDetailScreen extends ConsumerWidget {
  final String notificationId;
  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ref.read(notificationsProvider.notifier).delete(notificationId);
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          // Try to find the notification
          final notification = notifications.where((n) => n.id == notificationId).firstOrNull;
          
          if (notification == null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Notification not found', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
              ]),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_getNotificationIcon(notification.type), color: _getNotificationColor(notification.type), size: 32),
                ),
                const SizedBox(height: 20),
                // Title
                Text(notification.title, style: AppTypography.headlineLarge),
                const SizedBox(height: 8),
                Text(_formatTime(notification.createdAt), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 24),
                // Content
                Text(
                  notification.body,
                  style: AppTypography.bodyMedium.copyWith(height: 1.6),
                ),
                const SizedBox(height: 32),
                // Actions
                if (notification.auctionId != null) ...[
                  ElevatedButton(
                    onPressed: () => context.push('/auction/${notification.auctionId}'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(56)),
                    child: Text('View Auction', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: Text('Dismiss', style: AppTypography.titleMedium),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.outbid: return Icons.gavel;
      case NotificationType.auctionWon: return Icons.emoji_events;
      case NotificationType.auctionSold: return Icons.sell;
      case NotificationType.auctionEnding: return Icons.timer;
      case NotificationType.newAuction: return Icons.fiber_new;
      case NotificationType.watchlist: return Icons.bookmark;
      case NotificationType.message: return Icons.chat_bubble;
      case NotificationType.system: return Icons.info;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.outbid: return AppColors.warning;
      case NotificationType.auctionWon: return AppColors.success;
      case NotificationType.auctionSold: return AppColors.success;
      case NotificationType.auctionEnding: return AppColors.secondary;
      case NotificationType.newAuction: return AppColors.primary;
      case NotificationType.watchlist: return AppColors.info;
      case NotificationType.message: return AppColors.info;
      case NotificationType.system: return AppColors.textSecondaryLight;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${time.month}/${time.day}/${time.year}';
  }
}

/// Notification Preferences Screen - Connected to Backend
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  Map<String, bool> _preferences = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    try {
      final prefsAsync = ref.read(notificationPreferencesProvider);
      prefsAsync.whenData((prefs) {
        setState(() {
          _preferences = prefs.map((k, v) => MapEntry(k, v as bool? ?? false));
          _isLoading = false;
        });
      });
    } catch (e) {
      // Use defaults
      setState(() {
        _preferences = {
          'outbid_alerts': true,
          'auction_ending': true,
          'won_auction': true,
          'new_in_category': false,
          'new_in_town': true,
          'messages': true,
          'promotions': false,
          'push_enabled': true,
          'email_enabled': true,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    setState(() => _preferences[key] = value);
    await ref.read(notificationRepositoryProvider).updatePreferences({key: value});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          title: Text('Notification Preferences', style: AppTypography.titleLarge),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Notification Preferences', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Auction Alerts'),
          _ToggleItem(
            title: 'Outbid Notifications',
            subtitle: 'Get notified when someone outbids you',
            value: _preferences['outbid_alerts'] ?? true,
            onChanged: (v) => _updatePreference('outbid_alerts', v),
          ),
          _ToggleItem(
            title: 'Auction Ending Soon',
            subtitle: 'Alerts for auctions ending in 1 hour',
            value: _preferences['auction_ending'] ?? true,
            onChanged: (v) => _updatePreference('auction_ending', v),
          ),
          _ToggleItem(
            title: 'Won Auction',
            subtitle: 'Confirmation when you win an auction',
            value: _preferences['won_auction'] ?? true,
            onChanged: (v) => _updatePreference('won_auction', v),
          ),
          const SizedBox(height: 24),
          _SectionHeader('Discovery'),
          _ToggleItem(
            title: 'New in Favorite Categories',
            subtitle: 'New auctions in categories you follow',
            value: _preferences['new_in_category'] ?? false,
            onChanged: (v) => _updatePreference('new_in_category', v),
          ),
          _ToggleItem(
            title: 'New in My Town',
            subtitle: 'Fresh listings in your home town',
            value: _preferences['new_in_town'] ?? true,
            onChanged: (v) => _updatePreference('new_in_town', v),
          ),
          const SizedBox(height: 24),
          _SectionHeader('Communication'),
          _ToggleItem(
            title: 'Messages',
            subtitle: 'Direct messages from buyers/sellers',
            value: _preferences['messages'] ?? true,
            onChanged: (v) => _updatePreference('messages', v),
          ),
          _ToggleItem(
            title: 'Promotions',
            subtitle: 'Special offers and announcements',
            value: _preferences['promotions'] ?? false,
            onChanged: (v) => _updatePreference('promotions', v),
          ),
          const SizedBox(height: 24),
          _SectionHeader('Delivery Method'),
          _ToggleItem(
            title: 'Push Notifications',
            subtitle: 'Receive alerts on your device',
            value: _preferences['push_enabled'] ?? true,
            onChanged: (v) => _updatePreference('push_enabled', v),
          ),
          _ToggleItem(
            title: 'Email Notifications',
            subtitle: 'Receive alerts via email',
            value: _preferences['email_enabled'] ?? true,
            onChanged: (v) => _updatePreference('email_enabled', v),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight, letterSpacing: 1)),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleItem({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTypography.titleSmall),
            Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
          ])),
          Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary),
        ],
      ),
    );
  }
}
