import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_button.dart';

class StorefrontScreen extends ConsumerWidget {
  final String slug;

  const StorefrontScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(storeBySlugProvider(slug));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: storeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (store) => CustomScrollView(
          slivers: [
            // Store Header
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (store.coverUrl != null)
                      CachedNetworkImage(
                        imageUrl: store.coverUrl!,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(color: AppColors.primary),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(store.storeName),
                centerTitle: false,
              ),
              actions: [
                IconButton(
                  icon: Icon(store.isFollowing ? Icons.favorite : Icons.favorite_border),
                  color: Colors.white,
                  onPressed: () {
                    // TODO: Implement follow
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),

            // Store Info & Actions
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Logo
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: store.logoUrl != null
                                ? CachedNetworkImage(imageUrl: store.logoUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.store, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(store.tagline ?? 'No tagline', style: AppTypography.bodyMedium),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(store.townName ?? 'Location Unknown', style: AppTypography.labelSmall),
                                  if (store.isVerified) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.verified, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 2),
                                    Text('Verified', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'WhatsApp',
                            icon: Icons.chat,
                            backgroundColor: const Color(0xFF25D366),
                            onPressed: () {
                              if (store.whatsapp != null) {
                                launchUrl(Uri.parse('https://wa.me/${store.whatsapp}'));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (store.phone != null) {
                                launchUrl(Uri.parse('tel:${store.phone}'));
                              }
                            },
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Products Header
            SliverPinnedHeader(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.grey[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Products (${store.totalProducts})', style: AppTypography.titleMedium),
                    const Icon(Icons.filter_list),
                  ],
                ),
              ),
            ),

            // Products Grid
            Consumer(
              builder: (context, ref, _) {
                final productsAsync = ref.watch(storeProductsProvider(StoreProductsParams(slug: slug)));
                
                return productsAsync.when(
                  data: (response) {
                    if (response.items.isEmpty) {
                      return SliverToBoxAdapter(
                        child:  Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text('No products yet', style: AppTypography.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = response.items[index];
                            return _ProductCard(product: product);
                          },
                          childCount: response.items.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: LinearProgressIndicator()),
                  error: (e, _) => SliverToBoxAdapter(child: Text('Error loading products: $e')),
                );
              },
            ),
          ],
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
      onTap: () {
        // Navigate to detail
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: product.primaryImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: AppTypography.titleSmall.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
