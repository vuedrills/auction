import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// National town filter provider
final selectedTownFilterProvider = StateProvider<Town?>((ref) => null);

/// National Auctions Screen - Minimal, Award-Winning Design
class NationalAuctionsScreen extends ConsumerStatefulWidget {
  const NationalAuctionsScreen({super.key});

  @override
  ConsumerState<NationalAuctionsScreen> createState() => _NationalAuctionsScreenState();
}

class _NationalAuctionsScreenState extends ConsumerState<NationalAuctionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nationalAuctionsProvider.notifier).loadAuctions(refresh: true);
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auctionState = ref.watch(nationalAuctionsProvider);
    final selectedTown = ref.watch(selectedTownFilterProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    // Filter auctions by town and category
    final filteredAuctions = auctionState.auctions.where((a) {
      final matchesTown = selectedTown == null || a.townId == selectedTown.id;
      final matchesCategory = selectedCategory == null || a.categoryId == selectedCategory.id;
      return matchesTown && matchesCategory;
    }).toList();

    // Check if any filters are active
    final hasActiveFilters = selectedTown != null || selectedCategory != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () => ref.read(nationalAuctionsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // Minimal Header - Search box with filter
            SliverToBoxAdapter(child: _MinimalSearchHeader(
              onSearchTap: () => context.push('/search/national'),
              onFilterTap: _showFilterSheet,
              hasActiveFilters: hasActiveFilters,
            )),
            
            // Category Quick Filter Chips
            SliverToBoxAdapter(child: _CategoryQuickFilter()),
            
            // Active filters indicator (show if town is selected from filter)
            if (selectedTown != null)
              SliverToBoxAdapter(child: _ActiveFiltersBar(
                town: selectedTown,
                category: null,
                onClearAll: () {
                  ref.read(selectedTownFilterProvider.notifier).state = null;
                },
              )),
            
            // Ending Soon Section - Horizontal scroll with consistent card size
            SliverToBoxAdapter(child: _buildSectionHeader(
              context, 
              'Ending Soon',
              icon: Icons.timer_outlined,
              onSeeAll: () => context.push('/auctions/filtered?title=Ending Soon&filter=ending_soon'),
            )),
            SliverToBoxAdapter(child: _EndingSoonRow(auctions: filteredAuctions.take(10).toList())),
            
            // All Auctions Grid Header
            SliverToBoxAdapter(child: _buildSectionHeader(
              context,
              selectedTown != null ? selectedTown.name : 'All Auctions',
              icon: selectedTown != null ? Icons.location_on_outlined : Icons.grid_view_rounded,
              subtitle: '${filteredAuctions.length} items',
              onSeeAll: () => context.push('/auctions/filtered?title=All Nationwide&filter=fresh'),
            )),
            
            // Auction Grid
            if (auctionState.isLoading && auctionState.auctions.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (filteredAuctions.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState(selectedTown, selectedCategory))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _AuctionCard(
                      auction: filteredAuctions[index],
                      // Show featured badge for auctions marked as featured OR first 3 items
                      showFeaturedBadge: filteredAuctions[index].isFeatured || index < 3,
                    ),
                    childCount: filteredAuctions.length,
                  ),
                ),
              ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {IconData? icon, String? subtitle, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.textPrimaryLight),
                const SizedBox(width: 8),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                ],
              ),
            ],
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text('See All', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Town? town, Category? category) {
    String message = 'No auctions found';
    if (town != null && category != null) {
      message = 'No ${category.name} in ${town.name}';
    } else if (town != null) {
      message = 'No auctions in ${town.name}';
    } else if (category != null) {
      message = 'No ${category.name} auctions';
    }
    
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ref.read(selectedTownFilterProvider.notifier).state = null;
              ref.read(selectedCategoryProvider.notifier).state = null;
            },
            child: Text('Clear Filters', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

/// Minimal Search Header - Clean, corporate style
class _MinimalSearchHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  const _MinimalSearchHeader({
    required this.onSearchTap,
    required this.onFilterTap,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Search Box
              Expanded(
                child: GestureDetector(
                  onTap: onSearchTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 12),
                        Text('Search auctions...', 
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter Button
              GestureDetector(
                onTap: onFilterTap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: hasActiveFilters ? AppColors.textPrimaryLight : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: hasActiveFilters ? Colors.transparent : AppColors.borderLight),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.tune_rounded, size: 20, 
                        color: hasActiveFilters ? Colors.white : AppColors.textSecondaryLight),
                      if (hasActiveFilters)
                        Positioned(
                          top: -4, right: -4,
                          child: Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Town Dropdown Filter
class _TownDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final townsAsync = ref.watch(townsProvider);
    final selectedTown = ref.watch(selectedTownFilterProvider);

    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: townsAsync.when(
        data: (towns) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Town?>(
              value: selectedTown,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondaryLight),
              hint: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 8),
                  Text('All Towns', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimaryLight)),
                ],
              ),
              selectedItemBuilder: (context) => [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('All Towns', style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimaryLight)),
                  ],
                ),
                ...towns.map((t) => Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(t.name, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w500)),
                  ],
                )),
              ],
              items: [
                DropdownMenuItem<Town?>(
                  value: null,
                  child: Text('All Towns', style: AppTypography.bodyMedium),
                ),
                ...towns.map((t) => DropdownMenuItem<Town?>(
                  value: t,
                  child: Text(t.name, style: AppTypography.bodyMedium),
                )),
              ],
              onChanged: (town) => ref.read(selectedTownFilterProvider.notifier).state = town,
            ),
          ),
        ),
        loading: () => const SizedBox(height: 48),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Category Quick Filter Chips
class _CategoryQuickFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: categoriesAsync.when(
        data: (categories) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CategoryChip(
                label: 'All',
                isSelected: selectedCategory == null,
                onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
              ),
              ...categories.map((c) => _CategoryChip(
                label: c.name,
                isSelected: selectedCategory?.id == c.id,
                onTap: () => ref.read(selectedCategoryProvider.notifier).state = c,
              )),
            ],
          ),
        ),
        loading: () => const SizedBox(height: 36),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderLight),
        ),
        child: Text(label, style: AppTypography.labelMedium.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimaryLight,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        )),
      ),
    );
  }
}

/// Active Filters Bar
class _ActiveFiltersBar extends StatelessWidget {
  final Town? town;
  final Category? category;
  final VoidCallback onClearAll;

  const _ActiveFiltersBar({
    this.town,
    this.category,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surfaceLight,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (town != null) _FilterChip(label: town!.name, icon: Icons.location_city_rounded),
                  if (category != null) _FilterChip(label: category!.name, icon: Icons.category_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClearAll,
            child: Text('Clear', style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FilterChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textPrimaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Ending Soon Row - Horizontal scroll with consistent card size
class _EndingSoonRow extends StatelessWidget {
  final List<Auction> auctions;
  const _EndingSoonRow({required this.auctions});

  @override
  Widget build(BuildContext context) {
    if (auctions.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('No auctions ending soon', 
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: auctions.length,
        itemBuilder: (_, i) => _EndingSoonCard(auction: auctions[i]),
      ),
    );
  }
}

/// Ending Soon Card - Matches All Nationwide card design
class _EndingSoonCard extends StatelessWidget {
  final Auction auction;
  const _EndingSoonCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${auction.id}'),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
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

/// Auction Card for Grid - Matches All Nationwide card design
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



/// Filter Bottom Sheet
class _FilterBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final townsAsync = ref.watch(townsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedTown = ref.watch(selectedTownFilterProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () {
                    ref.read(selectedTownFilterProvider.notifier).state = null;
                    ref.read(selectedCategoryProvider.notifier).state = null;
                  },
                  child: Text('Reset', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Town Filter
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                townsAsync.when(
                  data: (towns) => Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _FilterOption(label: 'All', isSelected: selectedTown == null,
                        onTap: () => ref.read(selectedTownFilterProvider.notifier).state = null),
                      ...towns.map((t) => _FilterOption(label: t.name, isSelected: selectedTown?.id == t.id,
                        onTap: () => ref.read(selectedTownFilterProvider.notifier).state = t)),
                    ],
                  ),
                  loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const Text('Failed to load'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // Category Filter
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  data: (categories) => Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _FilterOption(label: 'All', isSelected: selectedCategory == null,
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = null),
                      ...categories.map((c) => _FilterOption(label: c.name, isSelected: selectedCategory?.id == c.id,
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = c)),
                    ],
                  ),
                  loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  error: (_, __) => const Text('Failed to load'),
                ),
              ],
            ),
          ),
          // Apply Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Apply Filters', style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppColors.borderLight),
        ),
        child: Text(label, style: AppTypography.labelMedium.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimaryLight,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        )),
      ),
    );
  }
}
