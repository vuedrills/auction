import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// National Search Screen - Dedicated search with real-time results
class NationalSearchScreen extends ConsumerStatefulWidget {
  const NationalSearchScreen({super.key});

  @override
  ConsumerState<NationalSearchScreen> createState() => _NationalSearchScreenState();
}

class _NationalSearchScreenState extends ConsumerState<NationalSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auctionState = ref.watch(nationalAuctionsProvider);

    // Filter by search query
    final results = _searchQuery.isEmpty
        ? <Auction>[]
        : auctionState.auctions.where((a) {
            return a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (a.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: (q) => setState(() => _searchQuery = q),
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Search auctions...',
                          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondaryLight),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _searchQuery.isEmpty
          ? _buildEmptySearch()
          : results.isEmpty
              ? _buildNoResults()
              : _buildResults(results),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Search for auctions', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          Text('Find amazing deals from across Zimbabwe', 
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No results for "$_searchQuery"', 
            style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          Text('Try a different search term', 
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _buildResults(List<Auction> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${results.length} results for "$_searchQuery"', 
            style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: results.length,
            itemBuilder: (_, i) => _SearchResultCard(auction: results[i]),
          ),
        ),
      ],
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
                  // Town badge
                  if (auction.town != null)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 12, color: AppColors.primary),
                            const SizedBox(width: 2),
                            Text(auction.town!.name, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  if (auction.timeRemaining != null)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: auction.isEndingSoon ? AppColors.secondary : Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(auction.timeRemaining!, style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
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
