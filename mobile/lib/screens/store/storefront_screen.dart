import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_button.dart';

class StorefrontScreen extends ConsumerStatefulWidget {
  final String slug;

  const StorefrontScreen({super.key, required this.slug});

  @override
  ConsumerState<StorefrontScreen> createState() => _StorefrontScreenState();
}

class _StorefrontScreenState extends ConsumerState<StorefrontScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeBySlugProvider(widget.slug));

    return Scaffold(
      backgroundColor: Colors.grey[50], // Slightly off-white background
      body: storeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (store) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(storeBySlugProvider(widget.slug));
            ref.invalidate(storeProductsProvider(StoreProductsParams(slug: widget.slug)));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: CustomScrollView(
            slivers: [
              // 1. Immersive Store Header (Cover + Info Combined)
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Layer 1: Cover Image
                      store.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: store.coverUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),

                      // Layer 2: Gradient Overlay (for text readability)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter, // Fades out upwards
                            colors: [
                              Colors.black.withOpacity(0.9),
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 0.8],
                          ),
                        ),
                      ),

                      // Layer 3: Store Info Content
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Logo
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: store.logoUrl != null
                                      ? CachedNetworkImage(imageUrl: store.logoUrl!, fit: BoxFit.cover)
                                      : const Icon(Icons.store, color: AppColors.primary, size: 30),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Name & Products
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            store.storeName,
                                            style: AppTypography.headlineSmall.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withOpacity(0.5),
                                                  offset: const Offset(0, 2),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (store.isVerified) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check, color: Colors.white, size: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${store.totalProducts} Products',
                                            style: AppTypography.bodySmall.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (store.createdAt != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'Since ${store.createdAt!.year}',
                                            style: AppTypography.labelSmall.copyWith(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Rating Only
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star, color: Colors.amber, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Pinned Tabs (Products, About)
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minHeight: 50,
                  maxHeight: 50,
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: _SquareTab(
                            label: 'Products',
                            isSelected: _selectedTabIndex == 0,
                            onTap: () => setState(() => _selectedTabIndex = 0),
                          ),
                        ),
                        Expanded(
                          child: _SquareTab(
                            label: 'About',
                            isSelected: _selectedTabIndex == 1,
                            onTap: () => setState(() => _selectedTabIndex = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Content Body
              if (_selectedTabIndex == 0) ...[
                // Owner actions (if applicable)
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final myStore = ref.watch(myStoreProvider).valueOrNull;
                      if (myStore?.id != store.id) return const SizedBox.shrink();
                      
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/store/manage/products'),
                                icon: const Icon(Icons.add_shopping_cart, size: 18),
                                label: const Text('Add Product'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/store/edit', extra: store),
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Edit Store'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Products Grid
                Consumer(
                  builder: (context, ref, _) {
                    final productsAsync = ref.watch(storeProductsProvider(StoreProductsParams(slug: widget.slug)));
                    
                    return productsAsync.when(
                      data: (response) {
                        if (response.items.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text('No products found', style: AppTypography.bodyMedium),
                                ],
                              ),
                            ),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          sliver: AnimationLimiter(
                            child: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.70,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => AnimationConfiguration.staggeredGrid(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  columnCount: 2,
                                  child: ScaleAnimation(
                                    child: FadeInAnimation(
                                      child: _ProductCard(product: response.items[index]),
                                    ),
                                  ),
                                ),
                                childCount: response.items.length,
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
                    );
                  },
                ),
              ] else if (_selectedTabIndex == 1) ...[
                // About Tab
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About Us', style: AppTypography.titleMedium),
                          const SizedBox(height: 12),
                          Text(store.about ?? 'No description available', style: AppTypography.bodyMedium),
                          const SizedBox(height: 24),
                          
                          if (store.address != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(child: Text(store.address!, style: AppTypography.bodyMedium)),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (store.phone != null) ...[
                            InkWell(
                              onTap: () => launchUrl(Uri.parse('tel:${store.phone}')),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 20, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Text(store.phone!, style: AppTypography.bodyMedium.copyWith(color: AppColors.primary)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          if (store.whatsapp != null) ...[
                            InkWell(
                              onTap: () => launchUrl(Uri.parse('https://wa.me/${store.whatsapp}')),
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.green),
                                  const SizedBox(width: 12),
                                  Text('Chat on WhatsApp', style: AppTypography.bodyMedium.copyWith(color: Colors.green)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}



class _SquareTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SquareTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        color: isSelected ? AppColors.primary : Colors.white,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: product.primaryImage != null 
                      ? CachedNetworkImage(
                          imageUrl: product.primaryImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: constraints.maxHeight * 0.65,
                          placeholder: (_, __) => Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
                        )
                      : Container(
                          width: double.infinity,
                          height: constraints.maxHeight * 0.65,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.shopping_bag, color: Colors.grey),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(0)}',
                              style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, size: 16, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyHeaderDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
