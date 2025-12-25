import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// National Auctions Home Screen - Connected to Backend
class NationalAuctionsScreen extends ConsumerStatefulWidget {
  const NationalAuctionsScreen({super.key});

  @override
  ConsumerState<NationalAuctionsScreen> createState() => _NationalAuctionsScreenState();
}

class _NationalAuctionsScreenState extends ConsumerState<NationalAuctionsScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nationalAuctionsProvider.notifier).loadAuctions(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auctionState = ref.watch(nationalAuctionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final townsAsync = ref.watch(townsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () => ref.read(nationalAuctionsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(context)),
            // Search
            SliverToBoxAdapter(child: _buildSearch()),
            // Featured section
            SliverToBoxAdapter(child: _buildSectionHeader('Featured Nationwide', Icons.star_rounded)),
            SliverToBoxAdapter(child: _buildFeaturedCarousel(auctionState.auctions)),
            // Categories
            SliverToBoxAdapter(child: _buildSectionHeader('Trending Categories', Icons.trending_up)),
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (categories) => _buildCategoryChips(categories),
                loading: () => const SizedBox(height: 48),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            // Auctions by town
            SliverToBoxAdapter(child: _buildSectionHeader('Auctions by Town', Icons.location_city)),
            townsAsync.when(
              data: (towns) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildTownSection(towns[i], auctionState.auctions),
                  childCount: towns.take(5).length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SliverToBoxAdapter(child: Center(child: Text('Failed to load towns'))),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(color: AppColors.surfaceLight),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.public_rounded, color: AppColors.info, size: 18),
                  const SizedBox(width: 4),
                  Text('NATIONAL VIEW', style: AppTypography.labelSmall.copyWith(color: AppColors.info, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Row(children: [
                    Text('Switch to Town', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 18),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Explore Zimbabwe', style: AppTypography.displaySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textSecondaryLight),
              const SizedBox(width: 12),
              Text('Search all auctions...', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
              const Spacer(),
              Icon(Icons.tune, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.headlineSmall),
          ]),
          Text('See All', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel(List<Auction> auctions) {
    // Show first 5 auctions as featured
    final featured = auctions.take(5).toList();
    if (featured.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('No featured auctions', style: AppTypography.bodyMedium)),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: featured.length,
        itemBuilder: (_, i) {
          final auction = featured[i];
          return GestureDetector(
            onTap: () => context.push('/auction/${auction.id}'),
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.secondary.withValues(alpha: 0.8)]),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (auction.primaryImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: auction.primaryImage!,
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.3),
                        colorBlendMode: BlendMode.darken,
                      ),
                    ),
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text('FEATURED', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                        ),
                        const SizedBox(height: 8),
                        Text(auction.title, style: AppTypography.headlineMedium.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Current bid: \$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips(List<Category> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategoryId == category.id;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategoryId = isSelected ? null : category.id);
              if (!isSelected) {
                context.push('/category/${category.id}');
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPrimaryLight : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderLight),
              ),
              child: Row(
                children: [
                  if (category.icon != null) ...[
                    Text(category.icon!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                  ],
                  Text(category.name, style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTownSection(Town town, List<Auction> allAuctions) {
    // Filter auctions by town
    final townAuctions = allAuctions.where((a) => a.townId == town.id).take(4).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/town/${town.id}'),
            child: Row(children: [
              Icon(Icons.location_on, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(town.name, style: AppTypography.titleMedium),
              const Spacer(),
              Text('${townAuctions.length} auctions', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
              Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondaryLight),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: townAuctions.isEmpty
              ? Center(child: Text('No auctions in ${town.name}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: townAuctions.length,
                  itemBuilder: (_, i) {
                    final auction = townAuctions[i];
                    return GestureDetector(
                      onTap: () => context.push('/auction/${auction.id}'),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          Expanded(
                            child: auction.primaryImage != null
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: CachedNetworkImage(
                                    imageUrl: auction.primaryImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Center(child: Icon(Icons.image, color: Colors.grey.shade400)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(auction.title, style: AppTypography.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
