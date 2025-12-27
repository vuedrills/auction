import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

class FeaturedStoresList extends ConsumerWidget {
  const FeaturedStoresList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(featuredStoresProvider);

    return storesAsync.when(
      data: (stores) {
        if (stores.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return _StoreCard(store: store);
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(), // Don't show anything while loading to avoid layout shift or show shimmer
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Store store;

  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/store/${store.slug}'),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[100]!),
                image: store.logoUrl != null
                    ? DecorationImage(image: NetworkImage(store.logoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: store.logoUrl == null
                  ? const Icon(Icons.store, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                store.storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.titleSmall,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              store.townName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

