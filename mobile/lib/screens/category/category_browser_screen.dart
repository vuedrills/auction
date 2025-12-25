import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// Category Browser Screen - Connected to Backend
class CategoryBrowserScreen extends ConsumerStatefulWidget {
  const CategoryBrowserScreen({super.key});

  @override
  ConsumerState<CategoryBrowserScreen> createState() => _CategoryBrowserScreenState();
}

class _CategoryBrowserScreenState extends ConsumerState<CategoryBrowserScreen> {
  bool _showNational = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.surfaceLight,
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            title: Text('Categories', style: AppTypography.titleLarge),
          ),
          
          // Location toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showNational = false),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: !_showNational ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            user?.homeTown?.name ?? 'My Town',
                            style: AppTypography.titleSmall.copyWith(
                              color: !_showNational ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showNational = true),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _showNational ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'National',
                            style: AppTypography.titleSmall.copyWith(
                              color: _showNational ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          
          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryLight),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          
          // Categories Grid
          categoriesAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (categories) {
              final filtered = _searchQuery.isEmpty
                  ? categories
                  : categories.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.category_outlined, size: 64, color: AppColors.textSecondaryLight),
                      const SizedBox(height: 16),
                      Text('No categories found', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight)),
                    ]),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _CategoryCard(
                      category: filtered[i],
                      townId: _showNational ? null : user?.homeTownId,
                      onTap: () => context.push('/category/${filtered[i].id}${_showNational ? '' : '?town=${user?.homeTownId}'}'),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final Category category;
  final String? townId;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    this.townId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get slot availability if townId is provided
    final slotsAsync = townId != null
        ? ref.watch(categorySlotProvider((categoryId: category.id, townId: townId!)))
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
            // Icon
            Center(
              child: category.icon != null
                  ? Text(category.icon!, style: const TextStyle(fontSize: 48))
                  : Icon(_getCategoryIcon(category.name), size: 48, color: Colors.grey.shade400),
            ),
            // Bottom info
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  if (slotsAsync != null)
                    slotsAsync.when(
                      data: (slots) => Row(children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: slots.availableSlots > 0 ? AppColors.success : AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          slots.availableSlots > 0 
                            ? '${slots.availableSlots} slots available'
                            : 'Full - ${slots.waitingCount} waiting',
                          style: AppTypography.labelSmall.copyWith(color: Colors.grey.shade300),
                        ),
                      ]),
                      loading: () => Text('Loading...', style: AppTypography.labelSmall.copyWith(color: Colors.grey.shade300)),
                      error: (_, __) => const SizedBox.shrink(),
                    )
                  else
                    Row(children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('Browse auctions', style: AppTypography.labelSmall.copyWith(color: Colors.grey.shade300)),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'electronics': return Icons.devices;
      case 'furniture': return Icons.chair;
      case 'vehicles': return Icons.directions_car;
      case 'fashion': return Icons.checkroom;
      case 'collectibles': return Icons.collections;
      case 'home & garden': return Icons.yard;
      case 'sports': return Icons.sports_soccer;
      case 'books': return Icons.menu_book;
      default: return Icons.category;
    }
  }
}
