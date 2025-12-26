import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// Sort options for auction listings
enum _SortOption {
  endingSoon,
  newlyListed,
  priceHighToLow,
  priceLowToHigh,
  mostBids,
  leastBids,
  featuredFirst,
}

/// Suburb Selector Screen - Connected to Backend
class SuburbSelectorScreen extends ConsumerStatefulWidget {
  final String townId;
  final String townName;
  const SuburbSelectorScreen({super.key, required this.townId, required this.townName});

  @override
  ConsumerState<SuburbSelectorScreen> createState() => _SuburbSelectorScreenState();
}

class _SuburbSelectorScreenState extends ConsumerState<SuburbSelectorScreen> {

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
            title: Text('Select Suburb', style: AppTypography.titleLarge),
            actions: const [],
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
              if (suburbs.isEmpty) {
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
                  (_, i) => _SuburbListItem(
                    suburb: suburbs[i], 
                    townId: widget.townId,
                    townName: widget.townName,
                  ),
                  childCount: suburbs.length,
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
  final String townName;

  const _SuburbListItem({
    required this.suburb, 
    required this.townId,
    required this.townName,
  });

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
          '${suburb.activeAuctions} ${suburb.activeAuctions == 1 ? 'listing' : 'listings'}',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/suburb/${suburb.id}/auctions?name=${Uri.encodeComponent(suburb.name)}&town=${Uri.encodeComponent(townName)}'),
      ),
    );
  }
}

/// Suburb Auction Feed Screen - Connected to Backend
class SuburbAuctionFeedScreen extends ConsumerStatefulWidget {
  final String suburbId;
  final String suburbName;
  final String townName;
  const SuburbAuctionFeedScreen({super.key, required this.suburbId, required this.suburbName, required this.townName});

  @override
  ConsumerState<SuburbAuctionFeedScreen> createState() => _SuburbAuctionFeedScreenState();
}

class _SuburbAuctionFeedScreenState extends ConsumerState<SuburbAuctionFeedScreen> {
  Category? _selectedCategory;
  _SortOption _sortOption = _SortOption.endingSoon;

  @override
  Widget build(BuildContext context) {
    final auctionsAsync = ref.watch(suburbAuctionsProvider(widget.suburbId));
    final categoriesAsync = ref.watch(categoriesProvider);

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
              IconButton(icon: const Icon(Icons.sort), onPressed: () => _showSortBottomSheet(context)),
              IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search/national?suburbId=${widget.suburbId}')),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.suburbName, style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryLight)),
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
                  _StatChip(icon: Icons.location_on, label: widget.townName),
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
          // Filter chips (Categories)
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (categories) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _CategoryFilterChip(
                      label: 'All', 
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ...categories.map((c) => _CategoryFilterChip(
                      label: c.name,
                      isSelected: _selectedCategory?.id == c.id,
                      onTap: () => setState(() => _selectedCategory = c),
                    )),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          // Grid
          auctionsAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (response) {
              
              // Apply local filtering
              var filteredAuctions = _selectedCategory == null 
                  ? response.auctions.toList() 
                  : response.auctions.where((a) => a.categoryId == _selectedCategory!.id).toList();
              
              // Apply sorting
              filteredAuctions = _applySorting(filteredAuctions);

              if (filteredAuctions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.gavel_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No auctions found', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 8),
                      // Only show button if no auctions at all, otherwise just show empty state
                      if (response.auctions.isEmpty)
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
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final auction = filteredAuctions[i];
                      return _AuctionCard(auction: auction, showFeaturedBadge: auction.isFeatured);
                    },
                    childCount: filteredAuctions.length,
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

  List<Auction> _applySorting(List<Auction> auctions) {
    switch (_sortOption) {
      case _SortOption.endingSoon:
        auctions.sort((a, b) => (a.endTime ?? DateTime.now()).compareTo(b.endTime ?? DateTime.now()));
        break;
      case _SortOption.newlyListed:
        auctions.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      case _SortOption.priceHighToLow:
        auctions.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
        break;
      case _SortOption.priceLowToHigh:
        auctions.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
        break;
      case _SortOption.mostBids:
        auctions.sort((a, b) => b.totalBids.compareTo(a.totalBids));
        break;
      case _SortOption.leastBids:
        auctions.sort((a, b) => a.totalBids.compareTo(b.totalBids));
        break;
      case _SortOption.featuredFirst:
        auctions.sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
        break;
    }
    return auctions;
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.sort, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Sort Listings', style: AppTypography.titleLarge),
                ],
              ),
            ),
            const Divider(height: 1),
            // Sort options
            _SortOptionTile(
              icon: Icons.timer_outlined,
              title: 'Ending Soon',
              subtitle: 'Auctions closing first',
              isSelected: _sortOption == _SortOption.endingSoon,
              onTap: () => _selectSort(_SortOption.endingSoon),
            ),
            _SortOptionTile(
              icon: Icons.new_releases_outlined,
              title: 'Newly Listed',
              subtitle: 'Most recent listings first',
              isSelected: _sortOption == _SortOption.newlyListed,
              onTap: () => _selectSort(_SortOption.newlyListed),
            ),
            _SortOptionTile(
              icon: Icons.arrow_upward,
              title: 'Price: High to Low',
              subtitle: 'Highest priced first',
              isSelected: _sortOption == _SortOption.priceHighToLow,
              onTap: () => _selectSort(_SortOption.priceHighToLow),
            ),
            _SortOptionTile(
              icon: Icons.arrow_downward,
              title: 'Price: Low to High',
              subtitle: 'Lowest priced first',
              isSelected: _sortOption == _SortOption.priceLowToHigh,
              onTap: () => _selectSort(_SortOption.priceLowToHigh),
            ),
            _SortOptionTile(
              icon: Icons.local_fire_department_outlined,
              title: 'Most Bids',
              subtitle: 'Most popular auctions',
              isSelected: _sortOption == _SortOption.mostBids,
              onTap: () => _selectSort(_SortOption.mostBids),
            ),
            _SortOptionTile(
              icon: Icons.remove_circle_outline,
              title: 'Least Bids',
              subtitle: 'Hidden gems with no bids',
              isSelected: _sortOption == _SortOption.leastBids,
              onTap: () => _selectSort(_SortOption.leastBids),
            ),
            _SortOptionTile(
              icon: Icons.star_outline,
              title: 'Featured First',
              subtitle: 'Promoted listings first',
              isSelected: _sortOption == _SortOption.featuredFirst,
              onTap: () => _selectSort(_SortOption.featuredFirst),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _selectSort(_SortOption option) {
    setState(() => _sortOption = option);
    Navigator.pop(context);
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

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _CategoryFilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.textPrimaryLight : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderLight),
          ),
          child: Text(label, style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          )),
        ),
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600, size: 20),
      ),
      title: Text(title, style: AppTypography.titleSmall.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textPrimaryLight,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      )),
      subtitle: Text(subtitle, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
      trailing: isSelected 
          ? Icon(Icons.check_circle, color: AppColors.primary)
          : Icon(Icons.circle_outlined, color: Colors.grey.shade300),
      onTap: onTap,
    );
  }
}

class _AuctionCard extends StatelessWidget {
  final Auction auction;
  final bool showFeaturedBadge;
  const _AuctionCard({required this.auction, this.showFeaturedBadge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${auction.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: auction.primaryImage != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: auction.primaryImage!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(child: Icon(Icons.image, color: Colors.grey.shade400)),
                              errorWidget: (_, __, ___) => Center(child: Icon(Icons.broken_image, color: Colors.grey.shade400)),
                            ),
                          )
                        : Center(child: Icon(Icons.image_rounded, size: 40, color: Colors.grey.shade400)),
                  ),
                  // Timer badge
                  if (auction.timeRemaining != null)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: auction.isEndingSoon ? AppColors.secondary : Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(auction.timeRemaining!, style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  // Featured badge
                  if (showFeaturedBadge)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.amber.shade600, Colors.orange]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('FEATURED', 
                              style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auction.title, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(auction.suburb?.name ?? auction.town?.name ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${auction.displayPrice.toStringAsFixed(0)}', 
                          style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        Text('${auction.totalBids} bids', 
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                      ],
                    ),
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
