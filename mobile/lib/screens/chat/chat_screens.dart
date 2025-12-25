import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/providers/auth_provider.dart';

/// Chat List Screen - Connected to Backend
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        title: Text('Messages', style: AppTypography.headlineMedium),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: chatsAsync.when(
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
      ),
    );
  }
}

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

/// Chat Detail Screen - Connected to Backend
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatDetailScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markAsRead(widget.chatId);
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final user = ref.read(currentUserProvider);
      await ref.read(chatRepositoryProvider).sendMessage(widget.chatId, text, currentUserId: user?.id);
      ref.invalidate(chatMessagesProvider((chatId: widget.chatId, userId: user?.id)));
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesProvider((chatId: widget.chatId, userId: user?.id)));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: messagesAsync.when(
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Chat'),
          data: (messages) => Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text('U', style: TextStyle(color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat', style: AppTypography.titleSmall),
                  Text('${messages.length} messages', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) => ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  return _MessageBubble(message: msg);
                },
              ),
            ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate, color: AppColors.textSecondaryLight),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppColors.backgroundLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _isSending ? AppColors.textSecondaryLight : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: AppTypography.bodyMedium.copyWith(
                color: message.isMe ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: message.isMe ? Colors.white70 : AppColors.textSecondaryLight,
                  ),
                ),
                if (message.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.white : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
