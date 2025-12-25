import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// Filtered Auctions Screen - Shows auctions filtered by type (ending soon, fresh, etc.)
class FilteredAuctionsScreen extends ConsumerWidget {
  final String title;
  final String filterType; // 'ending_soon', 'fresh', 'featured'
  final String? townId;
  final String? categoryId;
  final String? suburbId;

  const FilteredAuctionsScreen({
    super.key,
    required this.title,
    required this.filterType,
    this.townId,
    this.categoryId,
    this.suburbId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use ending soon provider for ending soon filter
    final auctionsAsync = filterType == 'ending_soon'
        ? ref.watch(endingSoonProvider(townId))
        : ref.watch(myTownAuctionsProvider).auctions.isEmpty
            ? const AsyncValue<List<Auction>>.loading()
            : AsyncValue.data(ref.watch(myTownAuctionsProvider).auctions);
    
    // Watch filter state
    final selectedSuburb = ref.watch(selectedSuburbProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: AppTypography.headlineSmall),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Suburb Dropdown
          if (townId != null) _SuburbDropdownFilter(townId: townId!),
          
          // Category Chips
          const _CategoryChipsFilter(),
          
          // Auction Grid
          Expanded(
            child: auctionsAsync.when(
              data: (auctions) {
                // Apply filters (reactive)
                var filteredAuctions = auctions.where((a) {
                  final matchesSuburb = selectedSuburb == null || a.suburbId == selectedSuburb.id;
                  final matchesCategory = selectedCategory == null || a.categoryId == selectedCategory.id;
                  return matchesSuburb && matchesCategory;
                }).toList();
                
                if (filteredAuctions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyMessage(selectedSuburb, selectedCategory),
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredAuctions.length,
                  itemBuilder: (context, index) => _AuctionGridCard(auction: filteredAuctions[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getEmptyMessage(Suburb? suburb, Category? category) {
    if (suburb != null && category != null) {
      return 'No ${category.name} in ${suburb.name}';
    } else if (suburb != null) {
      return 'No auctions in ${suburb.name}';
    } else if (category != null) {
      return 'No ${category.name} auctions';
    }
    return 'No auctions found';
  }
}

/// Suburb Dropdown Filter
class _SuburbDropdownFilter extends ConsumerWidget {
  final String townId;
  const _SuburbDropdownFilter({required this.townId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suburbsAsync = ref.watch(suburbsProvider(townId));
    final selectedSuburb = ref.watch(selectedSuburbProvider);

    return suburbsAsync.when(
      data: (suburbs) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<Suburb?>(
                value: selectedSuburb,
                hint: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('All Suburbs', style: AppTypography.labelSmall),
                  ],
                ),
                underline: const SizedBox(),
                isDense: true,
                icon: Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondaryLight),
                style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimaryLight),
                items: [
                  DropdownMenuItem<Suburb?>(value: null, child: Text('All Suburbs')),
                  ...suburbs.map((s) => DropdownMenuItem<Suburb?>(
                    value: s,
                    child: Text(s.name),
                  )),
                ],
                onChanged: (s) => ref.read(selectedSuburbProvider.notifier).state = s,
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Category Chips Filter
class _CategoryChipsFilter extends ConsumerWidget {
  const _CategoryChipsFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return categoriesAsync.when(
      data: (categories) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // "All" chip
            _FilterChip(
              name: 'All',
              icon: Icons.grid_view_rounded,
              isSelected: selectedCategory == null,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
            ),
            ...categories.map((c) => _FilterChip(
              name: c.name,
              icon: _getCategoryIcon(c.icon),
              isSelected: selectedCategory?.id == c.id,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = c,
            )),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'phone_iphone': return Icons.phone_iphone;
      case 'directions_car': return Icons.directions_car;
      case 'checkroom': return Icons.checkroom;
      case 'chair': return Icons.chair;
      case 'build': return Icons.build;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'auto_stories': return Icons.auto_stories;
      case 'toys': return Icons.toys;
      case 'kitchen': return Icons.kitchen;
      case 'music_note': return Icons.music_note;
      case 'diamond': return Icons.diamond;
      default: return Icons.category;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({required this.name, required this.icon, required this.isSelected, required this.onTap});

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Text(name, style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              )),
            ],
          ),
        ),
      ),
    );
  }
}


class _AuctionGridCard extends StatelessWidget {
  final Auction auction;
  const _AuctionGridCard({required this.auction});

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
                        Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        Text('${auction.totalBids} bids', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
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
