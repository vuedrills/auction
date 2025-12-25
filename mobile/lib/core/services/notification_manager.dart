import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../network/websocket_service.dart';
import '../../data/providers/websocket_provider.dart';
import './push_notification_service.dart';

/// Wraps the app to listen for global WebSocket notifications and show Snackbars
class NotificationManager extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationManager({super.key, required this.child});

  @override
  ConsumerState<NotificationManager> createState() => _NotificationManagerState();
}

class _NotificationManagerState extends ConsumerState<NotificationManager> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    
    // Connect WebSocket globally for real-time updates (chat, notifications, etc.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wsManagerProvider.notifier).connect();
    });
    
    // Initialize push notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize();
    });

    // Use manual subscription for Stream events
    final wsService = ref.read(wsServiceProvider);
    _subscription = wsService.notifications.listen(_handleNotification);
  }

  void _handleNotification(dynamic message) {
      if (!mounted) return;
      
      final data = message.data ?? {};
      final title = data['title'] as String? ?? 'Notification';
      final body = data['body'] as String? ?? '';
      final type = data['type'] as String?; // auction_won, auction_sold, outbid, etc.
      final auctionId = data['auction_id'] as String? ?? message.auctionId;
      final chatId = data['chat_id'] as String?;

      // Show Snackbar using the root ScaffoldMessenger
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (body.isNotEmpty) ...[
                 const SizedBox(height: 4),
                 Text(body, style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
          backgroundColor: _getColorForType(type),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: (type == 'auction_won' || type == 'auction_sold') && chatId != null
              ? SnackBarAction(
                  label: 'CHAT',
                  textColor: Colors.white,
                  onPressed: () => context.push('/chats/$chatId'),
                )
              : auctionId != null
                  ? SnackBarAction(
                      label: 'VIEW',
                      textColor: Colors.white,
                      onPressed: () => context.push('/auction/$auctionId'),
                    )
                  : null,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  Color _getColorForType(String? type) {
    if (type == null) return Colors.black87;
    
    switch (type.toLowerCase()) {
      case 'auction_won':
        return Colors.green.shade700;
      case 'auction_sold':
        return Colors.blue.shade700;
      case 'outbid':
        return Colors.orange.shade800;
      case 'auction_ended':
        return Colors.grey.shade800;
      case 'error':
        return Colors.red.shade700;
      default:
        return Colors.black87;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
