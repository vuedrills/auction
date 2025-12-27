import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/models/store.dart';
import '../../data/providers/analytics_provider.dart';
import '../../data/repositories/store_repository.dart';
import 'package:go_router/go_router.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  final String storeId;

  const AnalyticsDashboardScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(storeAnalyticsProvider(storeId));
    final staleAsync = ref.watch(staleProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Analytics'),
      ),
      body: analyticsAsync.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(storeAnalyticsProvider(storeId));
            ref.invalidate(staleProductsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(data),
                const SizedBox(height: 24),
                // Needs Attention Section
                staleAsync.when(
                  data: (staleProducts) => staleProducts.isNotEmpty
                      ? _NeedsAttentionSection(staleProducts: staleProducts)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Conversion Funnel',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildFunnelChart(data),
                const SizedBox(height: 24),
                Text(
                  'Top Products',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildTopProductsList(data),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load analytics', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(storeAnalyticsProvider(storeId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(StoreAnalyticsResponse data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Total Views',
                value: data.totalViews.toString(),
                icon: Icons.visibility,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPICard(
                title: 'Enquiries',
                value: data.totalEnquiries.toString(),
                icon: Icons.chat,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KPICard(
                title: 'Products',
                value: data.totalProducts.toString(),
                icon: Icons.inventory_2,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPICard(
                title: 'Followers',
                value: data.totalFollowers.toString(),
                icon: Icons.people,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFunnelChart(StoreAnalyticsResponse data) {
    // Mock funnel data based on totals if breakdown missing
    final impressions = (data.totalViews * 2.5).round(); // Fake impressions if not tracked yet
    final views = data.totalViews;
    final enquiries = data.totalEnquiries;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _FunnelBar(label: 'Impressions', value: impressions, color: Colors.blue[300]!, maxValue: impressions),
            const SizedBox(height: 12),
            _FunnelBar(label: 'Store Views', value: views, color: Colors.blue[500]!, maxValue: impressions),
            const SizedBox(height: 12),
            _FunnelBar(label: 'Enquiries', value: enquiries, color: Colors.blue[700]!, maxValue: impressions),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList(StoreAnalyticsResponse data) {
    if (data.topProducts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No product data available yet.')),
        ),
      );
    }
    
    return Column(
      children: data.topProducts.map((product) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                image: product.primaryImage != null
                    ? DecorationImage(
                        image: NetworkImage(product.primaryImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.primaryImage == null
                  ? const Icon(Icons.image, color: Colors.grey)
                  : null,
            ),
            title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('\$${product.price}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.views} views',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${product.enquiries} chats',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.headlineMedium),
          ],
        ),
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final int maxValue;

  const _FunnelBar({
    required this.label,
    required this.value,
    required this.color,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = maxValue > 0 ? value / maxValue : 0;
    if (percentage > 1) percentage = 1;
    
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            value.toString(), 
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Section for products that need attention (stale products)
class _NeedsAttentionSection extends ConsumerWidget {
  final List<StaleProduct> staleProducts;

  const _NeedsAttentionSection({required this.staleProducts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(
              'Needs Attention',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${staleProducts.length}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'These products haven\'t been confirmed in over 30 days. Confirm they\'re still available to keep them visible.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 12),
        ...staleProducts.map((product) => _StaleProductCard(
          key: ValueKey(product.id),
          product: product,
        )),
      ],
    );
  }
}

class _StaleProductCard extends ConsumerStatefulWidget {
  final StaleProduct product;

  const _StaleProductCard({super.key, required this.product});

  @override
  ConsumerState<_StaleProductCard> createState() => _StaleProductCardState();
}

class _StaleProductCardState extends ConsumerState<_StaleProductCard> {
  bool _isLoading = false;
  bool _confirmed = false;
  late bool _isInStock;

  @override
  void initState() {
    super.initState();
    _isInStock = widget.product.isAvailable;
  }

  Future<void> _confirmProduct() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(storeRepositoryProvider).confirmProduct(widget.product.id);
      setState(() {
        _confirmed = true;
        _isLoading = false;
      });
      ref.invalidate(staleProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.title} confirmed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleStock(bool value) async {
    final previousValue = _isInStock;
    setState(() => _isInStock = value);
    
    try {
      await ref.read(storeRepositoryProvider).updateProduct(
        widget.product.id,
        {'is_available': value},
      );
      ref.invalidate(myProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
              ? '${widget.product.title} marked as in stock' 
              : '${widget.product.title} marked as out of stock'),
            backgroundColor: value ? Colors.green : Colors.grey,
          ),
        );
      }
      // If marked out of stock, remove from list after a delay
      if (!value) {
        await Future.delayed(const Duration(milliseconds: 500));
        ref.invalidate(staleProductsProvider);
      }
    } catch (e) {
      setState(() => _isInStock = previousValue); // Revert on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmed) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      color: Colors.orange.shade50,
      child: InkWell(
        onTap: () async {
          // Navigate to edit screen with the product
          // We need to map StaleProduct to Product for the route
          final product = Product(
            id: widget.product.id,
            storeId: widget.product.storeId,
            title: widget.product.title,
            description: widget.product.description,
            price: widget.product.price,
            pricingType: widget.product.pricingType,
            categoryId: widget.product.categoryId,
            condition: widget.product.condition,
            images: widget.product.images,
            stockQuantity: widget.product.stockQuantity,
            isAvailable: widget.product.isAvailable,
            isFeatured: widget.product.isFeatured,
            views: widget.product.views,
            enquiries: widget.product.enquiries,
            createdAt: widget.product.createdAt,
            updatedAt: widget.product.updatedAt,
            lastConfirmedAt: widget.product.lastConfirmedAt,
            store: null, // Not needed for edit
          );
          
          await context.push('/product/${product.id}/edit', extra: product);
          // Refresh list after returning from edit
          ref.invalidate(staleProductsProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: widget.product.primaryImage != null
                      ? DecorationImage(
                          image: NetworkImage(widget.product.primaryImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.product.primaryImage == null
                    ? const Icon(Icons.image, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.product.daysStale} days since update',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(Icons.chevron_right, color: Colors.orange.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
