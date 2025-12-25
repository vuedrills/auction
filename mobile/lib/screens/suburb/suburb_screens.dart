import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// Suburb Selector Screen - Connected to Backend
class SuburbSelectorScreen extends ConsumerStatefulWidget {
  final String townId;
  final String townName;
  const SuburbSelectorScreen({super.key, required this.townId, required this.townName});

  @override
  ConsumerState<SuburbSelectorScreen> createState() => _SuburbSelectorScreenState();
}

class _SuburbSelectorScreenState extends ConsumerState<SuburbSelectorScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final suburbsAsync = ref.watch(suburbsProvider(widget.townId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surfaceLight,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Suburb', style: AppTypography.titleLarge),
                Text(widget.townName, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search neighborhoods...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryLight),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          // All of Town option
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.location_city, color: Colors.white),
                ),
                title: Text('All of ${widget.townName}', style: AppTypography.titleMedium),
                subtitle: Text('View all auctions in town', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/town/${widget.townId}/auctions'),
              ),
            ),
          ),
          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('NEIGHBORHOODS', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight, letterSpacing: 1)),
            ),
          ),
          // Suburb list
          suburbsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (suburbs) {
              final filtered = _searchQuery.isEmpty
                  ? suburbs
                  : suburbs.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.location_off_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No suburbs found', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                    ]),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _SuburbListItem(suburb: filtered[i], townId: widget.townId),
                  childCount: filtered.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _SuburbListItem extends StatelessWidget {
  final Suburb suburb;
  final String townId;

  const _SuburbListItem({required this.suburb, required this.townId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.location_on, color: AppColors.success, size: 20),
        ),
        title: Text(suburb.name, style: AppTypography.titleSmall),
        subtitle: Text(
          'View auctions',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/suburb/${suburb.id}/auctions?name=${suburb.name}&town=$townId'),
      ),
    );
  }
}

/// Suburb Auction Feed Screen - Connected to Backend
class SuburbAuctionFeedScreen extends ConsumerWidget {
  final String suburbId;
  final String suburbName;
  final String townName;
  const SuburbAuctionFeedScreen({super.key, required this.suburbId, required this.suburbName, required this.townName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(suburbAuctionsProvider(suburbId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.surfaceLight,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            actions: [
              IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
              IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search')),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(suburbName, style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryLight)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.1), Colors.white]),
                ),
              ),
            ),
          ),
          // Stats bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatChip(icon: Icons.location_on, label: townName),
                  const SizedBox(width: 8),
                  auctionsAsync.when(
                    data: (response) => _StatChip(icon: Icons.gavel, label: '${response.auctions.length} Active'),
                    loading: () => _StatChip(icon: Icons.gavel, label: 'Loading...'),
                    error: (_, __) => _StatChip(icon: Icons.gavel, label: '0 Active'),
                  ),
                ],
              ),
            ),
          ),
          // Filter chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: ['All', 'Ending Soon', 'Just Listed', 'Most Bids', 'Price: Low to High'].map((f) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: f == 'All' ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: f == 'All' ? AppColors.primary : AppColors.borderLight),
                ),
                child: Text(f, style: AppTypography.labelSmall.copyWith(color: f == 'All' ? Colors.white : AppColors.textPrimaryLight)),
              )).toList()),
            ),
          ),
          // Grid
          auctionsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (response) {
              if (response.auctions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.gavel_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No auctions in this suburb', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/create-auction'),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add First Auction', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ]),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _AuctionGridItem(auction: response.auctions[i]),
                    childCount: response.auctions.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
      ]),
    );
  }
}

class _AuctionGridItem extends StatelessWidget {
  final Auction auction;
  const _AuctionGridItem({required this.auction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${auction.id}'),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (auction.primaryImage != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(imageUrl: auction.primaryImage!, fit: BoxFit.cover),
                      )
                    else
                      Center(child: Icon(Icons.image, size: 40, color: Colors.grey.shade400)),
                    if (auction.status == AuctionStatus.active)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
                          child: Text('LIVE', style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auction.title, style: AppTypography.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                      Text(auction.timeRemaining ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
