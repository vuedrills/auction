import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// Auction Ended State Screen - Connected to Backend
class AuctionEndedScreen extends ConsumerWidget {
  final String auctionId;
  
  const AuctionEndedScreen({
    super.key,
    required this.auctionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionAsync = ref.watch(auctionDetailProvider(auctionId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Auction Ended', style: AppTypography.titleLarge),
      ),
      body: auctionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (auction) {
          final isWinner = auction.winner?.id == currentUser?.id;
          final isSeller = auction.seller?.id == currentUser?.id;
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Result banner
                      _ResultBanner(
                        isWinner: isWinner,
                        isSeller: isSeller,
                        auction: auction,
                      ),
                      const SizedBox(height: 24),
                      
                      // Item details
                      _ItemCard(auction: auction),
                      const SizedBox(height: 24),
                      
                      // Stats
                      Row(
                        children: [
                          Expanded(child: _StatCard(icon: Icons.gavel, value: '${auction.totalBids}', label: 'Total Bids')),
                          const SizedBox(width: 12),
                          Expanded(child: _StatCard(icon: Icons.people, value: '${auction.totalBids}', label: 'Bidders')),
                          const SizedBox(width: 12),
                          Expanded(child: _StatCard(icon: Icons.timer, value: '7d', label: 'Duration')),
                        ],
                      ),
                      
                      // Winner info (for seller)
                      if (isSeller && auction.winner != null) ...[
                        const SizedBox(height: 24),
                        _WinnerCard(winner: auction.winner!),
                      ],
                      
                      // Next steps (for winner)
                      if (isWinner) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.info),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Contact the seller to arrange payment and pickup.',
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // No winner (reserve not met)
                      if (!isSeller && auction.winner == null && auction.status == AuctionStatus.ended) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber, color: AppColors.warning),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Reserve price was not met. The item was not sold.',
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Bottom action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: SafeArea(
                  top: false,
                  child: _BottomActions(
                    auction: auction,
                    isWinner: isWinner,
                    isSeller: isSeller,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final bool isWinner;
  final bool isSeller;
  final Auction auction;

  const _ResultBanner({
    required this.isWinner,
    required this.isSeller,
    required this.auction,
  });

  @override
  Widget build(BuildContext context) {
    final hasWinner = auction.winner != null;
    Color bgColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (isWinner) {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      iconColor = AppColors.success;
      icon = Icons.emoji_events;
      title = 'Congratulations!';
      subtitle = 'You won this auction!';
    } else if (isSeller && hasWinner) {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      iconColor = AppColors.success;
      icon = Icons.check_circle;
      title = 'Sold!';
      subtitle = 'Your item has been sold for \$${auction.currentPrice?.toStringAsFixed(2)}';
    } else if (isSeller && !hasWinner) {
      bgColor = AppColors.warning.withValues(alpha: 0.1);
      iconColor = AppColors.warning;
      icon = Icons.timer_off;
      title = 'Auction Ended';
      subtitle = 'Reserve price was not met';
    } else {
      bgColor = Colors.grey.shade100;
      iconColor = AppColors.textSecondaryLight;
      icon = Icons.timer_off;
      title = 'Auction Closed';
      subtitle = 'This auction has ended';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.headlineMedium.copyWith(color: iconColor)),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Auction auction;

  const _ItemCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: auction.primaryImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: auction.primaryImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.image, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auction.title, style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text('Final Price', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                Text(
                  '\$${auction.displayPrice.toStringAsFixed(2)}',
                  style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondaryLight, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.titleMedium),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final User winner;

  const _WinnerCard({required this.winner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.success,
            backgroundImage: winner.avatarUrl != null 
                ? CachedNetworkImageProvider(winner.avatarUrl!) 
                : null,
            child: winner.avatarUrl == null 
                ? Text(winner.fullName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Winner', style: AppTypography.labelSmall.copyWith(color: AppColors.success)),
                Text(winner.fullName, style: AppTypography.titleMedium),
                if (winner.homeTown != null)
                  Text(winner.homeTown!.name, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Icon(Icons.emoji_events, color: AppColors.success),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final Auction auction;
  final bool isWinner;
  final bool isSeller;

  const _BottomActions({
    required this.auction,
    required this.isWinner,
    required this.isSeller,
  });

  @override
  Widget build(BuildContext context) {
    if (isWinner) {
      return ElevatedButton.icon(
        onPressed: () => _contactSeller(context),
        icon: const Icon(Icons.message, color: Colors.white),
        label: Text('Contact Seller', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(56)),
      );
    }
    
    if (isSeller && auction.winner != null) {
      return ElevatedButton.icon(
        onPressed: () => _contactWinner(context),
        icon: const Icon(Icons.message, color: Colors.white),
        label: Text('Contact Winner', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(56)),
      );
    }
    
    return OutlinedButton(
      onPressed: () => context.go('/home'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
      child: Text('Browse More Auctions', style: AppTypography.titleMedium),
    );
  }

  void _contactSeller(BuildContext context) {
    if (auction.seller?.id != null) {
      context.push('/chat/new?userId=${auction.seller!.id}&auctionId=${auction.id}');
    }
  }

  void _contactWinner(BuildContext context) {
    if (auction.winner?.id != null) {
      context.push('/chat/new?userId=${auction.winner!.id}&auctionId=${auction.id}');
    }
  }
}

/// Auction Seller View Screen - Connected to Backend
class AuctionSellerViewScreen extends ConsumerWidget {
  final String auctionId;
  const AuctionSellerViewScreen({super.key, required this.auctionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionAsync = ref.watch(auctionDetailProvider(auctionId));
    final bidsAsync = ref.watch(bidHistoryProvider(auctionId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: auctionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (auction) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 250,
              backgroundColor: AppColors.surfaceLight,
              leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/auction/$auctionId/edit'),
                ),
                PopupMenuButton(
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'share',
                      child: Row(children: [Icon(Icons.share), SizedBox(width: 8), Text('Share')]),
                    ),
                    PopupMenuItem(
                      value: 'end',
                      child: Row(children: [Icon(Icons.timer_off, color: AppColors.error), SizedBox(width: 8), Text('End Early', style: TextStyle(color: AppColors.error))]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))]),
                    ),
                  ],
                  onSelected: (v) => _handleMenuAction(context, ref, v, auction),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (auction.primaryImage != null)
                      CachedNetworkImage(
                        imageUrl: auction.primaryImage!,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image, size: 64, color: Colors.grey.shade400),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Owner badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.person, size: 16, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text('Your Listing', style: AppTypography.labelMedium.copyWith(color: AppColors.info)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title & location
                    Text(auction.title, style: AppTypography.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      '${auction.town?.name ?? ''} • ${auction.suburb?.name ?? ''} • ${auction.category?.name ?? ''}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 24),
                    
                    // Stats cards
                    Row(
                      children: [
                        Expanded(child: _SellerStatCard(
                          value: '\$${auction.displayPrice.toStringAsFixed(0)}',
                          label: 'Current Bid',
                          color: AppColors.primary,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _SellerStatCard(
                          value: '${auction.totalBids}',
                          label: 'Total Bids',
                          color: AppColors.secondary,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _SellerStatCard(
                          value: auction.timeRemaining ?? 'Ended',
                          label: 'Time Left',
                          color: AppColors.warning,
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Watchers & views
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MetricItem(icon: Icons.visibility, value: '${auction.views}', label: 'Views'),
                          _MetricItem(icon: Icons.bookmark, value: '0', label: 'Watchers'),
                          _MetricItem(icon: Icons.people, value: '${auction.totalBids}', label: 'Bids'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Recent bids
                    Text('Recent Bids', style: AppTypography.headlineSmall),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            
            // Bids list
            bidsAsync.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
              data: (bids) {
                if (bids.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.gavel_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No bids yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _BidItem(bid: bids[i], isLeading: i == 0),
                    childCount: bids.length > 10 ? 10 : bids.length,
                  ),
                );
              },
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: auctionAsync.maybeWhen(
        data: (auction) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: auction.status == AuctionStatus.active
                        ? () => _showEndEarlyDialog(context, ref, auction)
                        : null,
                    icon: const Icon(Icons.timer_off),
                    label: const Text('End Early'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareAuction(auction),
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text('Share', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action, Auction auction) {
    switch (action) {
      case 'share':
        _shareAuction(auction);
        break;
      case 'end':
        _showEndEarlyDialog(context, ref, auction);
        break;
      case 'delete':
        _showDeleteDialog(context, ref, auction);
        break;
    }
  }

  void _shareAuction(Auction auction) {
    final text = 'Check out this auction: ${auction.title}\nhttps://trabab.com/auction/${auction.id}';
    Clipboard.setData(ClipboardData(text: text));
  }

  void _showEndEarlyDialog(BuildContext context, WidgetRef ref, Auction auction) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Auction Early?'),
        content: Text(
          auction.totalBids > 0
              ? 'This will end the auction and sell to the current high bidder for \$${auction.displayPrice.toStringAsFixed(2)}.'
              : 'This will cancel the auction with no winner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(auctionRepositoryProvider).cancelAuction(auction.id);
                ref.invalidate(auctionDetailProvider(auction.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Auction ended'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text('End Auction', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Auction auction) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Auction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(auctionRepositoryProvider).cancelAuction(auction.id);
                if (context.mounted) {
                  context.go('/home');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SellerStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SellerStatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: AppTypography.titleLarge.copyWith(color: color)),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondaryLight),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.titleMedium),
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
      ],
    );
  }
}

class _BidItem extends StatelessWidget {
  final Bid bid;
  final bool isLeading;

  const _BidItem({required this.bid, required this.isLeading});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLeading ? AppColors.success.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isLeading ? Border.all(color: AppColors.success.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isLeading ? AppColors.success : AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: bid.bidder?.avatarUrl != null 
                ? CachedNetworkImageProvider(bid.bidder!.avatarUrl!) 
                : null,
            child: bid.bidder?.avatarUrl == null 
                ? Text(
                    (bid.bidder?.fullName ?? 'U')[0],
                    style: TextStyle(color: isLeading ? Colors.white : AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(bid.bidder?.fullName ?? 'Anonymous', style: AppTypography.titleSmall),
                    if (isLeading) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('LEADING', style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                Text(_formatTime(bid.createdAt), style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Text(
            '\$${bid.amount.toStringAsFixed(0)}',
            style: AppTypography.titleMedium.copyWith(color: isLeading ? AppColors.success : AppColors.textPrimaryLight),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
