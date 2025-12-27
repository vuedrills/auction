import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_text_field.dart';

class StoreExploreScreen extends ConsumerStatefulWidget {
  const StoreExploreScreen({super.key});

  @override
  ConsumerState<StoreExploreScreen> createState() => _StoreExploreScreenState();
}

class _StoreExploreScreenState extends ConsumerState<StoreExploreScreen> {
  String? _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We'll create a new provider call for this screen with filters
    // For simplicity, we assume storeRepository stores method handles it
    
    // Watch categories
    final categoriesAsync = ref.watch(storeCategoriesProvider);
    
    // Watch stores with simple search/filter logic
    // Ideally we'd have a specific provider with filter state, but for now accessing repo directly via FutureProvider.family or similar
    // Let's us a simple stateful approach where we trigger fetch on change
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('All Stores'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppTextField(
                  hintText: 'Search stores...',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),
                
                // Categories
                SizedBox(
                  height: 40,
                  child: categoriesAsync.when(
                    data: (categories) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isSelected = _selectedCategory == null;
                          return ChoiceChip(
                            label: const Text('All'),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCategory = null),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          );
                        }
                        final category = categories[index - 1];
                        final isSelected = _selectedCategory == category.id;
                        return ChoiceChip(
                          label: Text(category.displayName),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = category.id),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        );
                      },
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
          
          // Store List
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                 // Creating a dynamic provider call here might be tricky if we want to debounce search
                 // But let's defer to repository
                 final storesFuture = ref.watch(storeRepositoryProvider).getStores(
                   query: _searchController.text.isNotEmpty ? _searchController.text : null,
                   categoryId: _selectedCategory,
                   limit: 50,
                 );
                 
                 return FutureBuilder<PaginatedResponse<Store>>(
                   future: storesFuture,
                   builder: (context, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: CircularProgressIndicator());
                     }
                     if (snapshot.hasError) {
                       return Center(child: Text('Error: ${snapshot.error}'));
                     }
                     
                     final stores = snapshot.data?.items ?? [];
                     
                     if (stores.isEmpty) {
                       return const Center(child: Text('No stores found'));
                     }
                     
                     return ListView.builder(
                       padding: const EdgeInsets.all(16),
                       itemCount: stores.length,
                       itemBuilder: (context, index) {
                          final store = stores[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () => context.push('/store/${store.slug}'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Logo
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: Colors.grey[200]!),
                                         image: store.logoUrl != null
                                           ? DecorationImage(image: NetworkImage(store.logoUrl!), fit: BoxFit.cover)
                                           : null,
                                      ),
                                      child: store.logoUrl == null
                                          ? const Icon(Icons.store, color: Colors.grey)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(store.storeName, style: AppTypography.titleMedium),
                                          if (store.tagline != null)
                                             Text(store.tagline!, style: AppTypography.bodySmall, maxLines: 1),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                              const SizedBox(width: 2),
                                              Text(store.townName ?? 'Unknown', style: AppTypography.labelSmall),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.inventory_2, size: 12, color: Colors.grey),
                                               const SizedBox(width: 2),
                                              Text('${store.totalProducts} items', style: AppTypography.labelSmall),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                       },
                     );
                   },
                 );
              },
            ),
          ),
        ],
      ),
    );
  }
}
