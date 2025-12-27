import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_button.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We might need a provider for single product
    // For now, let's assume we can fetch it via a future provider I'll create
    final productAsync = ref.watch(productProvider(productId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (product) => CustomScrollView(
          slivers: [
            // Image Carousel (simplified for now)
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.black),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    PageView.builder(
                      itemCount: product.images.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: product.images[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${product.images.isNotEmpty ? 1 : 0}/${product.images.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Details
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            style: AppTypography.headlineSmall,
                          ),
                        ),
                        if (product.stockQuantity == 0)
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                             child: Text('Out of Stock', style: TextStyle(color: Colors.red[700], fontSize: 12)),
                           ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: AppTypography.headlineMedium.copyWith(color: AppColors.primary),
                    ),
                    if (product.pricingType == 'negotiable')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.handshake_outlined, size: 14, color: Colors.orange.shade700),
                            const SizedBox(width: 4),
                            Text('Negotiable', style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            )),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Seller Info Card
                    if (product.store != null)
                      InkWell(
                        onTap: () => context.push('/store/${product.store!.slug}'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: product.store!.logoUrl != null 
                                    ? NetworkImage(product.store!.logoUrl!) 
                                    : null,
                                child: product.store!.logoUrl == null ? const Icon(Icons.store) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(product.store!.storeName, style: AppTypography.titleSmall),
                                        if (product.store!.isVerified) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check, color: Colors.white, size: 10),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text('View Store', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    Text('Description', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      product.description ?? 'No description provided.',
                      style: AppTypography.bodyMedium,
                    ),
                    
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: productAsync.hasValue ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary: WhatsApp button (full width, prominent)
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'WhatsApp Seller',
                  icon: Icons.chat,
                  backgroundColor: const Color(0xFF25D366),
                  onPressed: () {
                    final store = productAsync.value!.store;
                    if (store?.whatsapp != null && store!.whatsapp!.isNotEmpty) {
                      final message = Uri.encodeComponent('Hi, is ${productAsync.value!.title} still available?');
                      launchUrl(Uri.parse('https://wa.me/${store.whatsapp}?text=$message'));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('WhatsApp not available. Try in-app chat.')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Secondary: In-App Chat (outline style)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final store = productAsync.value!.store;
                    if (store == null) return;
                    
                    // Start shop conversation
                    try {
                      final conversationId = await ref.read(shopChatRepositoryProvider).startConversation(
                        store.id,
                        productId: productId,
                        message: 'Hi, I\'m interested in ${productAsync.value!.title}',
                      );
                      if (context.mounted) {
                        context.push('/shop-chats/$conversationId', extra: {
                          'storeName': store.storeName,
                          'storeSlug': store.slug,
                          'productTitle': productAsync.value!.title,
                        });
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text('Chat In App'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ) : null,
    );
  }
}

// Simple provider for single product
final productProvider = FutureProvider.family<Product, String>((ref, id) async {
  return ref.watch(storeRepositoryProvider).getProduct(id);
});
