import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// Category Feed - National (Grouped by Town) - Connected to Backend
class CategoryFeedNationalScreen extends ConsumerWidget {
  final String categoryId;
  final String categoryName;
  const CategoryFeedNationalScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final townsAsync = ref.watch(townsProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: AppColors.surfaceLight,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            actions: [
              IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
              IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search')),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(categoryName, style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryLight)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.secondary.withValues(alpha: 0.1), Colors.white]),
                ),
              ),
            ),
          ),
          // National indicator
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.public, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Viewing $categoryName auctions from all towns', style: AppTypography.bodySmall)),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text('My Town', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                ),
              ]),
            ),
          ),
          // Towns sections
          townsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (towns) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _TownSection(
                  town: towns[i],
                  categoryId: categoryId,
                  categoryName: categoryName,
                ),
                childCount: towns.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _TownSection extends ConsumerWidget {
  final Town town;
  final String categoryId;
  final String categoryName;
  const _TownSection({required this.town, required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(townCategoryAuctionsProvider((townId: town.id, categoryId: categoryId)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Icon(Icons.location_on, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(town.name, style: AppTypography.titleMedium),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/category/$categoryId/town/${town.id}?name=$categoryName&town=${town.name}'),
              child: Text('See all', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
            ),
          ]),
        ),
        SizedBox(
          height: 180,
          child: auctionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text('Error loading', style: AppTypography.bodySmall)),
            data: (response) {
              if (response.auctions.isEmpty) {
                return Center(
                  child: Text('No auctions in ${town.name}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: response.auctions.length > 5 ? 5 : response.auctions.length,
                itemBuilder: (_, i) => _AuctionCard(auction: response.auctions[i], categoryName: categoryName),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AuctionCard extends StatelessWidget {
  final Auction auction;
  final String categoryName;
  const _AuctionCard({required this.auction, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${auction.id}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        child: CachedNetworkImage(imageUrl: auction.primaryImage!, fit: BoxFit.cover, width: double.infinity),
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
          ],
        ),
      ),
    );
  }
}

/// Category Feed - Town Scoped - Connected to Backend
class CategoryFeedTownScreen extends ConsumerWidget {
  final String categoryId;
  final String categoryName;
  final String townId;
  final String townName;
  const CategoryFeedTownScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.townId,
    required this.townName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionsAsync = ref.watch(townCategoryAuctionsProvider((townId: townId, categoryId: categoryId)));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surfaceLight,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(categoryName, style: AppTypography.titleLarge),
              Text(townName, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
            ]),
            actions: [
              IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
              IconButton(icon: const Icon(Icons.grid_view), onPressed: () {}),
            ],
          ),
          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                auctionsAsync.when(
                  data: (r) => _StatPill(icon: Icons.gavel, label: '${r.auctions.length} Active'),
                  loading: () => _StatPill(icon: Icons.gavel, label: 'Loading...'),
                  error: (_, __) => _StatPill(icon: Icons.gavel, label: '0 Active'),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/category/$categoryId'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Icon(Icons.public, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('National', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          // Filters
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: ['All', 'New Today', 'Ending Soon', 'Most Bids'].map((f) => Container(
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
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No $categoryName auctions', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.push('/category/$categoryId'),
                        child: const Text('View National'),
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
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _CategoryGridItem(auction: response.auctions[i], categoryName: categoryName),
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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

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

class _CategoryGridItem extends StatelessWidget {
  final Auction auction;
  final String categoryName;
  const _CategoryGridItem({required this.auction, required this.categoryName});

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
                    if (auction.timeRemaining != null && auction.timeRemaining!.startsWith('2'))
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(4)),
                          child: Row(children: [
                            Icon(Icons.timer, size: 10, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(auction.timeRemaining!, style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 10)),
                          ]),
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
                    Text(auction.suburb?.name ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                    const Spacer(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                      Text('${auction.totalBids} bids', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
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

/// National Category View - Just a wrapper
class NationalCategoryViewScreen extends ConsumerWidget {
  final String categoryId;
  final String categoryName;
  const NationalCategoryViewScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CategoryFeedNationalScreen(categoryId: categoryId, categoryName: categoryName);
  }
}
