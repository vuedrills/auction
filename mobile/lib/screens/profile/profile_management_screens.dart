import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_text_field.dart';

/// Edit Profile Screen - Connected to Backend
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  void _handleSave() async {
    setState(() => _isLoading = true);
    try {
      final success = await ref.read(authProvider.notifier).updateProfile(
        fullName: _nameController.text,
        phone: _phoneController.text,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text('Edit Profile', style: AppTypography.titleLarge),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: user?.avatarUrl != null
                    ? ClipOval(child: CachedNetworkImage(imageUrl: user!.avatarUrl!, fit: BoxFit.cover))
                    : const Icon(Icons.person, size: 48, color: AppColors.primary),
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AppTextField(controller: _nameController, label: 'Full Name'),
            const SizedBox(height: 16),
            AppTextField(controller: _usernameController, label: 'Username', prefixIcon: Icons.alternate_email),
            const SizedBox(height: 16),
            AppTextField(controller: _emailController, label: 'Email', keyboardType: TextInputType.emailAddress, prefixIcon: Icons.mail_outline, enabled: false),
            const SizedBox(height: 16),
            AppTextField(controller: _phoneController, label: 'Phone', keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined),
            const SizedBox(height: 24),
            // Home town (locked)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.location_on, color: AppColors.textSecondaryLight),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Home Town', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                  Text(user?.homeTown?.name ?? 'Not set', style: AppTypography.titleSmall),
                ])),
                Icon(Icons.lock_outline, color: AppColors.textSecondaryLight, size: 18),
              ]),
            ),
            const SizedBox(height: 8),
            Text('You can change your home town once every 30 days', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}

/// My Auctions Screen - Connected to Backend
class MyAuctionsScreen extends ConsumerStatefulWidget {
  const MyAuctionsScreen({super.key});

  @override
  ConsumerState<MyAuctionsScreen> createState() => _MyAuctionsScreenState();
}

class _MyAuctionsScreenState extends ConsumerState<MyAuctionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myAuctionsProvider.notifier).loadAuctions(refresh: true);
    });
    _tabController.addListener(() {
      final status = ['active', 'ended', null][_tabController.index];
      ref.read(myAuctionsProvider.notifier).setStatusFilter(status);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auctionState = ref.watch(myAuctionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('My Auctions', style: AppTypography.titleLarge),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Ended'), Tab(text: 'Drafts')],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myAuctionsProvider.notifier).refresh(),
        child: auctionState.isLoading && auctionState.auctions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : auctionState.auctions.isEmpty
            ? _buildEmptyState(_tabController.index)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: auctionState.auctions.length,
                itemBuilder: (_, i) => _MyAuctionCard(auction: auctionState.auctions[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-auction'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Auction', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    final icons = [Icons.gavel_outlined, Icons.check_circle_outline, Icons.drafts_outlined];
    final labels = ['No active auctions', 'No ended auctions', 'No drafts'];
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icons[tabIndex], size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(labels[tabIndex], style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
      ]),
    );
  }
}

class _MyAuctionCard extends StatelessWidget {
  final Auction auction;
  const _MyAuctionCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${auction.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
            child: auction.primaryImage != null
              ? ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: CachedNetworkImage(imageUrl: auction.primaryImage!, fit: BoxFit.cover),
                )
              : Icon(Icons.image, color: Colors.grey.shade400),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(auction.title, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (auction.status == AuctionStatus.active) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
                    child: Text('LIVE', style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 10)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.gavel, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text('${auction.totalBids} bids', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                  const SizedBox(width: 12),
                  if (auction.status == AuctionStatus.active) ...[
                    Icon(Icons.timer, size: 14, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text(auction.timeRemaining ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                  ] else
                    Text(auction.status.value.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                ]),
              ]),
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
          const SizedBox(width: 8),
        ]),
      ),
    );
  }
}

/// Bid History Screen - Connected to Backend
class BidHistoryScreen extends ConsumerWidget {
  const BidHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(myBidsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Bid History', style: AppTypography.titleLarge),
      ),
      body: bidsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bids) {
          if (bids.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No bids yet', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bids.length,
            itemBuilder: (_, i) => _BidHistoryCard(bid: bids[i]),
          );
        },
      ),
    );
  }
}

class _BidHistoryCard extends StatelessWidget {
  final Bid bid;
  const _BidHistoryCard({required this.bid});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${bid.auctionId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.gavel, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bid.auction?.title ?? 'Auction', style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Your bid: \$${bid.amount.toStringAsFixed(2)}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
            ])),
            _BidStatusBadge(isWinning: bid.isWinning),
          ]),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bid Amount', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
              Text('\$${bid.amount.toStringAsFixed(2)}', style: AppTypography.titleSmall),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Placed', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
              Text(_formatTime(bid.createdAt), style: AppTypography.titleSmall),
            ]),
          ]),
        ]),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _BidStatusBadge extends StatelessWidget {
  final bool isWinning;
  const _BidStatusBadge({required this.isWinning});

  @override
  Widget build(BuildContext context) {
    final color = isWinning ? AppColors.success : AppColors.warning;
    final label = isWinning ? 'Winning' : 'Outbid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(isWinning ? Icons.check_circle : Icons.warning, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
      ]),
    );
  }
}


/// Won Items Screen - Connected to Backend
class WonItemsScreen extends ConsumerWidget {
  const WonItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wonAsync = ref.watch(wonAuctionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Won Items', style: AppTypography.titleLarge),
      ),
      body: wonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (response) {
          if (response.auctions.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No won items yet', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Text('Start bidding to win!', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: response.auctions.length,
            itemBuilder: (_, i) => _WonItemCard(auction: response.auctions[i]),
          );
        },
      ),
    );
  }
}

class _WonItemCard extends StatelessWidget {
  final Auction auction;
  const _WonItemCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${auction.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Row(children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
              ),
              child: Stack(children: [
                if (auction.primaryImage != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
                    child: CachedNetworkImage(imageUrl: auction.primaryImage!, fit: BoxFit.cover, width: 100, height: 100),
                  )
                else
                  Center(child: Icon(Icons.image, color: Colors.grey.shade400)),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.emoji_events, color: Colors.white, size: 14),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(auction.title, style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Won for \$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleSmall.copyWith(color: AppColors.success)),
                  const SizedBox(height: 4),
                  Text('${auction.town?.name ?? ''}', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                ]),
              ),
            ),
          ]),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message, size: 16),
                label: const Text('Contact Seller'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Watchlist Screen - Connected to Backend
class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(watchlistProvider.notifier).loadWatchlist(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final watchlistState = ref.watch(watchlistProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Watchlist', style: AppTypography.titleLarge),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(watchlistProvider.notifier).refresh(),
        child: watchlistState.isLoading && watchlistState.auctions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : watchlistState.auctions.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.favorite_outline, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Watchlist is empty', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 8),
                  Text('Save auctions to see them here', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                ]),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: watchlistState.auctions.length,
                itemBuilder: (_, i) => _WatchlistCard(
                  auction: watchlistState.auctions[i],
                  onRemove: () => ref.read(watchlistProvider.notifier).removeFromWatchlist(watchlistState.auctions[i].id),
                ),
              ),
      ),
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback onRemove;
  const _WatchlistCard({required this.auction, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isEndingSoon = (auction.endTime?.difference(DateTime.now()).inHours ?? 0) < 24;

    return Dismissible(
      key: Key(auction.id),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      child: GestureDetector(
        onTap: () => context.push('/auction/${auction.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Stack(children: [
                if (auction.primaryImage != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    child: CachedNetworkImage(imageUrl: auction.primaryImage!, fit: BoxFit.cover, width: 100, height: 100),
                  )
                else
                  Center(child: Icon(Icons.image, color: Colors.grey.shade400)),
                const Positioned(
                  top: 8, right: 8,
                  child: Icon(Icons.favorite, color: AppColors.primary, size: 20),
                ),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(auction.title, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.timer, size: 14, color: isEndingSoon ? AppColors.secondary : AppColors.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text(
                      auction.timeRemaining ?? '',
                      style: AppTypography.labelSmall.copyWith(
                        color: isEndingSoon ? AppColors.secondary : AppColors.textSecondaryLight,
                        fontWeight: isEndingSoon ? FontWeight.w700 : null,
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
            const SizedBox(width: 8),
          ]),
        ),
      ),
    );
  }
}
