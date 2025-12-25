import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_button.dart';

/// User Profile Screen (Other User) - Connected to Backend
class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));
    final userAuctionsAsync = ref.watch(userAuctionsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
              actions: [
                IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)])),
                  child: SafeArea(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: user.avatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 40, color: Colors.grey),
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                              ),
                            )
                          : const Icon(Icons.person, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(user.fullName, style: AppTypography.headlineMedium.copyWith(color: Colors.white)),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.location_on, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(user.homeTown?.name ?? '', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
            // Stats
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: userAuctionsAsync.when(
                  data: (auctionResponse) {
                    final ratingsAsync = ref.watch(userRatingsProvider(userId));
                    
                    return ratingsAsync.when(
                      data: (ratingsResponse) => Row(children: [
                        _StatItem(value: '${auctionResponse.auctions.length}', label: 'Auctions'),
                        GestureDetector(
                          onTap: () => context.push('/user/$userId/reviews'),
                          child: _StatItem(
                            value: ratingsResponse.totalRatings > 0
                                ? ratingsResponse.average.toStringAsFixed(1)
                                : '-',
                            label: 'Rating',
                          ),
                        ),
                        _StatItem(value: '89%', label: 'Response'),
                        _StatItem(value: _memberDuration(user.createdAt), label: 'Member'),
                      ]),
                      loading: () => Row(children: [
                        _StatItem(value: '${auctionResponse.auctions.length}', label: 'Auctions'),
                        _StatItem(value: '...', label: 'Rating'),
                        _StatItem(value: '89%', label: 'Response'),
                        _StatItem(value: _memberDuration(user.createdAt), label: 'Member'),
                      ]),
                      error: (_, __) => Row(children: [
                        _StatItem(value: '${auctionResponse.auctions.length}', label: 'Auctions'),
                        _StatItem(value: '-', label: 'Rating'),
                        _StatItem(value: '89%', label: 'Response'),
                        _StatItem(value: _memberDuration(user.createdAt), label: 'Member'),
                      ]),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Row(children: [
                    _StatItem(value: '0', label: 'Auctions'),
                    _StatItem(value: '-', label: 'Rating'),
                    _StatItem(value: '-', label: 'Response'),
                    _StatItem(value: _memberDuration(user.createdAt), label: 'Member'),
                  ]),
                ),
              ),
            ),
            // See Reviews Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer(
                  builder: (context, ref, _) {
                    final ratingsAsync = ref.watch(userRatingsProvider(userId));
                    return ratingsAsync.whenOrNull(
                      data: (response) {
                        if (response.totalRatings == 0) return const SizedBox.shrink();
                        return OutlinedButton.icon(
                          onPressed: () => context.push('/user/$userId/reviews'),
                          icon: const Icon(Icons.rate_review),
                          label: Text('See ${response.totalRatings} ${response.totalRatings == 1 ? 'Review' : 'Reviews'}'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ) ?? const SizedBox.shrink();
                  },
                ),
              ),
            ),
            // Verification badges
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  if (user.isVerified) _Badge(icon: Icons.verified, label: 'Verified', color: AppColors.info),
                ]),
              ),
            ),
            // Active listings
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Active Listings', style: AppTypography.headlineSmall),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: userAuctionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading auctions')),
                  data: (response) {
                    if (response.auctions.isEmpty) {
                      return Center(
                        child: Text('No active listings', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: response.auctions.length > 5 ? 5 : response.auctions.length,
                      itemBuilder: (_, i) => _ListingCard(auction: response.auctions[i]),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.borderLight))),
        child: SafeArea(
          top: false,
          child: AppButton(label: 'Message Seller', onPressed: () => context.push('/chat/new?userId=$userId'), icon: Icons.message),
        ),
      ),
    );
  }

  String _memberDuration(DateTime joinDate) {
    final diff = DateTime.now().difference(joinDate);
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}m';
    return '${(diff.inDays / 365).floor()}y';
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: AppTypography.headlineMedium.copyWith(color: AppColors.primary)),
      Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
    ]));
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
      ]),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Auction auction;
  const _ListingCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${auction.id}'),
      child: Container(
        width: 150, margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: auction.primaryImage != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: auction.primaryImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                    ),
                  )
                : Center(child: Icon(Icons.image, color: Colors.grey.shade400)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auction.title, style: AppTypography.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                  Text(auction.timeRemaining ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Waiting List Screen - Connected to Backend
class WaitingListScreen extends ConsumerWidget {
  const WaitingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitingListAsync = ref.watch(waitingListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Waiting List', style: AppTypography.titleLarge),
      ),
      body: waitingListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (positions) {
          if (positions.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No waiting list positions', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Text('Join waiting lists for full categories', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
              ]),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(child: Text("You're on the waiting list for these full categories. We'll notify you when a slot opens.", style: AppTypography.bodySmall)),
                ]),
              ),
              const SizedBox(height: 20),
              // Waiting items
              ...positions.map((position) => _WaitingListItem(
                position: position,
                onRemove: () async {
                  await ref.read(waitingListActionsProvider.notifier).leave(position.categoryId, position.townId);
                  ref.invalidate(waitingListProvider);
                },
              )),
            ],
          );
        },
      ),
    );
  }
}

class _WaitingListItem extends StatelessWidget {
  final WaitingListPosition position;
  final VoidCallback onRemove;

  const _WaitingListItem({required this.position, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.category, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(position.categoryName, style: AppTypography.titleMedium),
            Text('${position.townName} • Position #${position.position}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
          ])),
          IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondaryLight), onPressed: onRemove),
        ]),
        const Divider(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Joined ${_formatDate(position.joinedAt)}', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('#${position.position} in queue', style: AppTypography.labelSmall.copyWith(color: AppColors.warning)),
          ),
        ]),
      ]),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays < 1) return 'today';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}';
  }
}
