import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/store/featured_stores_list.dart';

/// Shops Tab Screen - Dedicated tab for browsing stores and products
class ShopsTabScreen extends ConsumerStatefulWidget {
  const ShopsTabScreen({super.key});

  @override
  ConsumerState<ShopsTabScreen> createState() => _ShopsTabScreenState();
}

class _ShopsTabScreenState extends ConsumerState<ShopsTabScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsProvider.notifier).loadProducts(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final user = ref.watch(currentUserProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedTown = ref.watch(shopsTownFilterProvider);

    // Filter products by category and town
    final filteredProducts = productsState.products.where((p) {
      final matchesCategory = selectedCategory == null || p.categoryId == selectedCategory.id;
      final matchesTown = selectedTown == null || p.store?.townId == selectedTown.id;
      return matchesCategory && matchesTown;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () => ref.read(productsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // Header with search
            SliverToBoxAdapter(child: _ShopsHeader(
              onSearchTap: () => context.push('/stores'),
            )),

            // Town filter
            SliverToBoxAdapter(child: _TownFilter()),

            // Category chips
            const SliverToBoxAdapter(child: _CategoryChips()),

            // Featured Stores Section
            SliverToBoxAdapter(child: _buildSectionHeader(
              context, 'Featured Stores', Icons.star_rounded,
              onSeeAll: () => context.push('/stores'),
            )),
            const SliverToBoxAdapter(child: FeaturedStoresList()),

            // Products Near You
            SliverToBoxAdapter(child: _buildSectionHeader(
              context,
              selectedTown != null ? 'Products in ${selectedTown.name}' : 'Products Near You',
              Icons.shopping_bag_rounded,
              subtitle: '${filteredProducts.length} items',
            )),

            // Products Grid
            if (productsState.isLoading && productsState.products.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (filteredProducts.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
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
                    (context, index) => _ProductCard(product: filteredProducts[index]),
                    childCount: filteredProducts.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {String? subtitle, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: AppColors.secondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headlineSmall),
                if (subtitle != null)
                  Text(subtitle, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ]),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text('See All', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No products found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}

/// Shops Town Filter Provider
final shopsTownFilterProvider = StateProvider<Town?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.homeTown; // Default to user's home town
});

/// Shops Header
class _ShopsHeader extends StatelessWidget {
  final VoidCallback onSearchTap;
  const _ShopsHeader({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('SHOPS', style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Browse Stores & Products', style: AppTypography.displaySmall),
              const SizedBox(height: 12),
              // Search bar
              GestureDetector(
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
                      Text('Search stores & products...', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
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

/// Town Filter for Shops
class _TownFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final townsAsync = ref.watch(townsProvider);
    final selectedTown = ref.watch(shopsTownFilterProvider);

    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: townsAsync.when(
        data: (towns) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TownChip(
                label: 'All Zimbabwe',
                icon: Icons.public_rounded,
                isSelected: selectedTown == null,
                onTap: () => ref.read(shopsTownFilterProvider.notifier).state = null,
              ),
              ...towns.map((t) => _TownChip(
                label: t.name,
                icon: Icons.location_on_rounded,
                isSelected: selectedTown?.id == t.id,
                onTap: () => ref.read(shopsTownFilterProvider.notifier).state = t,
              )),
            ],
          ),
        ),
        loading: () => const SizedBox(height: 40),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _TownChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _TownChip({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimaryLight : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondaryLight),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.labelMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
}

/// Category Chips
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

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

/// Product Card
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
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
                    child: product.primaryImage != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: product.primaryImage!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(child: Icon(Icons.image, color: Colors.grey.shade400)),
                              errorWidget: (_, __, ___) => Center(child: Icon(Icons.broken_image, color: Colors.grey.shade400)),
                            ),
                          )
                        : Center(child: Icon(Icons.shopping_bag_rounded, size: 40, color: Colors.grey.shade400)),
                  ),
                  // Negotiable badge
                  if (product.isNegotiable)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('NEGOTIABLE', style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9)),
                      ),
                    ),
                  // Store verified badge
                  if (product.store?.isVerified == true)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.verified, size: 12, color: Colors.white),
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
                    Text(product.name, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(product.store?.storeName ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text('\$${product.price.toStringAsFixed(0)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
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
