import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// Search Results Screen - Connected to Backend
class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final _searchController = TextEditingController();
  bool _isNational = true;
  String _sortBy = 'relevance';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _performSearch();
  }

  void _performSearch() {
    final searchNotifier = ref.read(searchAuctionsProvider.notifier);
    searchNotifier.setQuery(_searchController.text);
    searchNotifier.setFilters(national: _isNational);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchAuctionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Search header
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.surfaceLight,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            title: TextField(
              controller: _searchController,
              onSubmitted: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Search auctions...',
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppColors.textSecondaryLight),
                  onPressed: _performSearch,
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.tune), onPressed: _showFilters),
            ],
          ),
          
          // Scope toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _isNational = false);
                              ref.read(searchAuctionsProvider.notifier).setFilters(national: false);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: !_isNational ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('My Town', style: AppTypography.labelMedium.copyWith(
                                  color: !_isNational ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                                )),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _isNational = true);
                              ref.read(searchAuctionsProvider.notifier).setFilters(national: true);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isNational ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('National', style: AppTypography.labelMedium.copyWith(
                                  color: _isNational ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                                )),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(children: [
                        Icon(Icons.sort, size: 18, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(_sortBy.capitalize(), style: AppTypography.labelMedium),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${searchState.auctions.length} results for "${_searchController.text}"',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
              ),
            ),
          ),
          
          // Category chips
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (categories) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _CategoryChip(
                      label: 'All',
                      isSelected: _selectedCategoryId == null,
                      onTap: () {
                        setState(() => _selectedCategoryId = null);
                        ref.read(searchAuctionsProvider.notifier).setFilters(categoryId: null);
                      },
                    ),
                    ...categories.map((c) => _CategoryChip(
                      label: c.name,
                      isSelected: _selectedCategoryId == c.id,
                      onTap: () {
                        setState(() => _selectedCategoryId = c.id);
                        ref.read(searchAuctionsProvider.notifier).setFilters(categoryId: c.id);
                      },
                    )),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 48),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          
          // Results
          if (searchState.isLoading && searchState.auctions.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (searchState.error != null && searchState.auctions.isEmpty)
            SliverFillRemaining(child: Center(child: Text('Error: ${searchState.error}')))
          else if (searchState.auctions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_off, size: 64, color: AppColors.textSecondaryLight),
                  const SizedBox(height: 16),
                  Text('No results found', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 8),
                  Text('Try a different search term', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                ]),
              ),
            )
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
                  (_, i) => _SearchResultCard(auction: searchState.auctions[i]),
                  childCount: searchState.auctions.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: AppTypography.headlineSmall),
            const SizedBox(height: 16),
            ...['Relevance', 'Price: Low', 'Price: High', 'Ending Soon', 'Most Bids'].map((s) => ListTile(
              title: Text(s),
              trailing: _sortBy == s.toLowerCase() ? Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _sortBy = s.toLowerCase());
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Filters', style: AppTypography.headlineMedium),
            const SizedBox(height: 24),
            Text('Price Range', style: AppTypography.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Min',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Max',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _performSearch();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Apply', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: isSelected ? Colors.white : AppColors.textPrimaryLight),
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Auction auction;
  const _SearchResultCard({required this.auction});

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
                        child: CachedNetworkImage(
                          imageUrl: auction.primaryImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Center(child: Icon(Icons.image, size: 40, color: Colors.grey.shade400)),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.favorite_border, size: 18, color: AppColors.textSecondaryLight),
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
                    Text(auction.town?.name ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                        Text(auction.timeRemaining ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
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

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
