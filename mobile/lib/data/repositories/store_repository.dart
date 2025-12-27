import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

import '../../core/network/dio_client.dart';
import '../data.dart';
import '../models/store.dart';
import '../providers/auth_provider.dart';

/// Repository for handling store and product related operations
class StoreRepository {
  final DioClient _client;

  StoreRepository(this._client);

  // ============ STORE DISCOVERY ============

  /// Get list of stores with filters
  Future<PaginatedResponse<Store>> getStores({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? townId,
    bool featured = false,
    String? query,
  }) async {
    try {
      final response = await _client.get(
        '/stores',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (categoryId != null) 'category': categoryId,
          if (townId != null) 'town': townId,
          if (featured) 'featured': 'true',
          if (query != null) 'q': query,
        },
      );

      final List<dynamic> storesJson = response.data['stores'] ?? [];
      final stores = storesJson.map((json) => Store.fromJson(json)).toList();
      
      return PaginatedResponse(
        items: stores,
        totalCount: response.data['total_count'] ?? 0,
        page: response.data['page'] ?? page,
        limit: response.data['limit'] ?? limit,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get store categories
  Future<List<StoreCategory>> getCategories() async {
    try {
      final response = await _client.get('/stores/categories');
      final List<dynamic> list = response.data['categories'] ?? [];
      return list.map((json) => StoreCategory.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get featured stores
  Future<List<Store>> getFeaturedStores() async {
    try {
      final response = await _client.get('/stores/featured');
      final List<dynamic> list = response.data['stores'] ?? [];
      return list.map((json) => Store.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get stores in user's town
  Future<List<Store>> getNearbyStores() async {
    try {
      final response = await _client.get('/stores/nearby');
      final List<dynamic> list = response.data['stores'] ?? [];
      return list.map((json) => Store.fromJson(json)).toList();
    } catch (e) {
      // Return empty if no town set or error
      return []; 
    }
  }

  /// Get store by slug
  Future<Store> getStoreBySlug(String slug) async {
    try {
      final response = await _client.get('/stores/$slug');
      return Store.fromJson(response.data['store']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============ PRODUCTS ============

  /// Get store products
  Future<PaginatedResponse<Product>> getStoreProducts(String slug, {
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? pricingType,
    String? sort,
  }) async {
    try {
      final response = await _client.get(
        '/stores/$slug/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (categoryId != null) 'category': categoryId,
          if (pricingType != null) 'type': pricingType,
          if (sort != null) 'sort': sort,
        },
      );

      final List<dynamic> jsonList = response.data['products'] ?? [];
      final products = jsonList.map((json) => Product.fromJson(json)).toList();

      return PaginatedResponse(
        items: products,
        totalCount: response.data['total_count'] ?? 0,
        page: response.data['page'] ?? page,
        limit: response.data['limit'] ?? limit,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Search products globally
  Future<PaginatedResponse<Product>> searchProducts(String query, {
    int page = 1,
    String? townId,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final response = await _client.get(
        '/products/search',
        queryParameters: {
          'q': query,
          'page': page,
          if (townId != null) 'town': townId,
          if (categoryId != null) 'category': categoryId,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
        },
      );

      final List<dynamic> jsonList = response.data['products'] ?? [];
      final products = jsonList.map((json) => Product.fromJson(json)).toList();

      return PaginatedResponse(
        items: products,
        totalCount: response.data['total_count'] ?? 0,
        page: response.data['page'] ?? 1,
        limit: response.data['limit'] ?? 20,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Delete my store
  Future<void> deleteStore() async {
    try {
      await _client.delete('/stores/me');
    } catch (e) {
      rethrow;
    }
  }

  /// Get single product
  Future<Product> getProduct(String id) async {
    try {
      final response = await _client.get('/products/$id');
      return Product.fromJson(response.data['product']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============ STORE MANAGEMENT ============

  /// Create a new store
  Future<Store> createStore(CreateStoreRequest request) async {
    try {
      final response = await _client.post(
        '/stores',
        data: request.toJson(),
      );
      return Store.fromJson(response.data['store']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get my store
  Future<Store?> getMyStore() async {
    try {
      final response = await _client.get('/stores/me');
      return Store.fromJson(response.data['store']);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    }
  }

  /// Update my store
  Future<Store> updateMyStore(Map<String, dynamic> data) async {
    try {
      final response = await _client.put('/stores/me', data: data);
      return Store.fromJson(response.data['store']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create product
  Future<Product> createProduct(CreateProductRequest request) async {
    try {
      final response = await _client.post(
        '/stores/me/products',
        data: request.toJson(),
      );
      return Product.fromJson(response.data['product']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get my products
  Future<List<Product>> getMyProducts() async {
    try {
      final response = await _client.get('/stores/me/products');
      final List<dynamic> list = response.data['products'] ?? [];
      return list.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update product
  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await _client.put('/products/$id', data: data);
      return Product.fromJson(response.data['product']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    try {
      await _client.delete('/products/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============ FOLLOW ============

  Future<void> followStore(String storeId) async {
    try {
      await _client.post('/stores/$storeId/follow', data: {});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unfollowStore(String storeId) async {
    try {
      await _client.delete('/stores/$storeId/follow');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Store>> getFollowingStores() async {
    try {
      final response = await _client.get('/users/me/following-stores');
      final List<dynamic> list = response.data['stores'] ?? [];
      return list.map((json) => Store.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Track store analytics event
  Future<void> trackEvent(String storeId, String eventType) async {
    try {
      await _client.post(
        '/stores/$storeId/track',
        data: {'event_type': eventType},
      );
    } catch (e) {
      // Fail silently for analytics
      print('Failed to track event: $e');
    }
  }

  /// Get stale products that need attention (>30 days without confirmation)
  Future<List<StaleProduct>> getStaleProducts() async {
    try {
      final response = await _client.get('/products/stale');
      final List<dynamic> list = response.data['products'] ?? [];
      return list.map((json) => StaleProduct.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Confirm a product is still available (refreshes last_confirmed_at)
  Future<void> confirmProduct(String productId) async {
    try {
      await _client.post('/products/$productId/confirm', data: {});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      return Exception(e.response?.data['error'] ?? 'Network error occurred');
    }
    return Exception('An unexpected error occurred: $e');
  }
}

// ============ PROVIDERS ============

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(ref.watch(dioClientProvider));
});

// Categories provider
final storeCategoriesProvider = FutureProvider<List<StoreCategory>>((ref) async {
  return ref.watch(storeRepositoryProvider).getCategories();
});

// Featured stores provider
final featuredStoresProvider = FutureProvider<List<Store>>((ref) async {
  return ref.watch(storeRepositoryProvider).getFeaturedStores();
});

// Nearby stores provider
final nearbyStoresProvider = FutureProvider<List<Store>>((ref) async {
  return ref.watch(storeRepositoryProvider).getNearbyStores();
});

// Get store by slug provider
final storeBySlugProvider = FutureProvider.family<Store, String>((ref, slug) async {
  return ref.watch(storeRepositoryProvider).getStoreBySlug(slug);
});

// Store products provider
final storeProductsProvider = FutureProvider.family<PaginatedResponse<Product>, StoreProductsParams>((ref, params) async {
  return ref.watch(storeRepositoryProvider).getStoreProducts(
    params.slug,
    page: params.page,
    limit: params.limit,
    categoryId: params.categoryId,
    pricingType: params.pricingType,
    sort: params.sort,
  );
});

// My store provider
final myStoreProvider = FutureProvider<Store?>((ref) async {
  ref.watch(currentUserProvider); // Refresh when user changes
  return ref.watch(storeRepositoryProvider).getMyStore();
});

// My products provider
final myProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(currentUserProvider); // Refresh when user changes
  return ref.watch(storeRepositoryProvider).getMyProducts();
});

// Stale products provider (products needing attention)
final staleProductsProvider = FutureProvider<List<StaleProduct>>((ref) async {
  ref.watch(currentUserProvider); // Refresh when user changes
  return ref.watch(storeRepositoryProvider).getStaleProducts();
});

class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int limit;

  PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.limit,
  });
}

class StoreProductsParams extends Equatable {
  final String slug;
  final int page;
  final int limit;
  final String? categoryId;
  final String? pricingType;
  final String? sort;

  const StoreProductsParams({
    required this.slug,
    this.page = 1,
    this.limit = 20,
    this.categoryId,
    this.pricingType,
    this.sort,
  });

  @override
  List<Object?> get props => [slug, page, limit, categoryId, pricingType, sort];
}

// ============ PRODUCTS STATE MANAGEMENT ============

class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final StoreRepository _repository;

  ProductsNotifier(this._repository) : super(ProductsState());

  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        page: refresh ? 1 : state.page,
      );

      // Get all products via search with empty query
      final result = await _repository.searchProducts(
        '',
        page: refresh ? 1 : state.page,
      );

      final newProducts = refresh ? result.items : [...state.products, ...result.items];

      state = state.copyWith(
        products: newProducts,
        isLoading: false,
        page: refresh ? 2 : state.page + 1,
        hasMore: result.items.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadProducts(refresh: true);
}

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier(ref.watch(storeRepositoryProvider));
});

