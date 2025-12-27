import 'package:flutter/material.dart';

/// Store category model
class StoreCategory {
  final String id;
  final String name;
  final String displayName;
  final String icon;
  final int sortOrder;
  final bool isActive;

  StoreCategory({
    required this.id,
    required this.name,
    required this.displayName,
    required this.icon,
    required this.sortOrder,
    required this.isActive,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) {
    return StoreCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      icon: json['icon'] ?? 'category',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  /// Get Flutter icon from icon name
  IconData get iconData {
    switch (icon) {
      case 'devices':
        return Icons.devices;
      case 'checkroom':
        return Icons.checkroom;
      case 'spa':
        return Icons.spa;
      case 'restaurant':
        return Icons.restaurant;
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'agriculture':
        return Icons.agriculture;
      case 'handyman':
        return Icons.handyman;
      case 'palette':
        return Icons.palette;
      case 'category':
        return Icons.category;
      default:
        return Icons.storefront;
    }
  }
}

/// Store model (seller storefront)
class Store {
  final String id;
  final String userId;
  final String storeName;
  final String slug;
  final String? tagline;
  final String? about;
  final String? logoUrl;
  final String? coverUrl;
  final String? categoryId;
  final String? whatsapp;
  final String? phone;
  final List<String> deliveryOptions;
  final int? deliveryRadiusKm;
  final Map<String, dynamic>? operatingHours;
  final String? townId;
  final String? suburbId;
  final bool isActive;
  final bool isVerified;
  final bool isFeatured;
  final int totalProducts;
  final int totalSales;
  final int followerCount;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? address;
  
  // Joined fields
  final StoreOwner? owner;
  final StoreCategory? category;
  final String? townName;
  final String? suburbName;
  final bool isFollowing;
  final bool isStale;

  Store({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.slug,
    this.tagline,
    this.about,
    this.logoUrl,
    this.coverUrl,
    this.categoryId,
    this.whatsapp,
    this.phone,
    this.deliveryOptions = const ['pickup'],
    this.deliveryRadiusKm,
    this.operatingHours,
    this.townId,
    this.suburbId,
    this.isActive = true,
    this.isVerified = false,
    this.isFeatured = false,
    this.totalProducts = 0,
    this.totalSales = 0,
    this.followerCount = 0,
    this.views = 0,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.owner,
    this.category,
    this.townName,
    this.suburbName,
    this.isFollowing = false,
    this.isStale = false,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      storeName: json['store_name'] ?? '',
      slug: json['slug'] ?? '',
      tagline: json['tagline'],
      about: json['about'],
      logoUrl: json['logo_url'],
      coverUrl: json['cover_url'],
      categoryId: json['category_id'],
      whatsapp: json['whatsapp'],
      phone: json['phone'],
      deliveryOptions: json['delivery_options'] != null
          ? List<String>.from(json['delivery_options'])
          : ['pickup'],
      deliveryRadiusKm: json['delivery_radius_km'],
      operatingHours: json['operating_hours'] != null
          ? Map<String, dynamic>.from(json['operating_hours'] is String
              ? {} : json['operating_hours'])
          : null,
      townId: json['town_id'],
      suburbId: json['suburb_id'],
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      totalProducts: json['total_products'] ?? 0,
      totalSales: json['total_sales'] ?? 0,
      followerCount: json['follower_count'] ?? 0,
      views: json['views'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      address: json['address'],
      owner: json['owner'] != null ? StoreOwner.fromJson(json['owner']) : null,
      category: json['category'] != null ? StoreCategory.fromJson(json['category']) : null,
      townName: json['town']?['name'],
      suburbName: json['suburb']?['name'],
      isFollowing: json['is_following'] ?? false,
      isStale: json['is_stale'] ?? false,
    );
  }

  /// Whether store supports local delivery
  bool get hasLocalDelivery => deliveryOptions.contains('local');
  
  /// Whether store ships nationwide
  bool get hasNationwideDelivery => deliveryOptions.contains('nationwide');
  
  /// Whether store offers pickup
  bool get hasPickup => deliveryOptions.contains('pickup');
}

/// Store owner info (minimal user data)
class StoreOwner {
  final String id;
  final String fullName;
  final String? avatarUrl;

  StoreOwner({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory StoreOwner.fromJson(Map<String, dynamic> json) {
    return StoreOwner(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

/// Product model (fixed-price items in store)
class Product {
  final String id;
  final String storeId;
  final String title;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final String pricingType; // fixed, negotiable, service
  final String? categoryId;
  final String condition; // new, used, refurbished
  final List<String> images;
  final int stockQuantity;
  final bool isAvailable;
  final bool isFeatured;
  final int views;
  final int enquiries;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastConfirmedAt;
  
  // Joined
  final Store? store;
  final String? categoryName;

  Product({
    required this.id,
    required this.storeId,
    required this.title,
    this.description,
    required this.price,
    this.compareAtPrice,
    this.pricingType = 'fixed',
    this.categoryId,
    this.condition = 'new',
    this.images = const [],
    this.stockQuantity = 1,
    this.isAvailable = true,
    this.isFeatured = false,
    this.views = 0,
    this.enquiries = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastConfirmedAt,
    this.store,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      storeId: json['store_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      compareAtPrice: json['compare_at_price']?.toDouble(),
      pricingType: json['pricing_type'] ?? 'fixed',
      categoryId: json['category_id'],
      condition: json['condition'] ?? 'new',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      stockQuantity: json['stock_quantity'] ?? 1,
      isAvailable: json['is_available'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      views: json['views'] ?? 0,
      enquiries: json['enquiries'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      lastConfirmedAt: json['last_confirmed_at'] != null 
          ? DateTime.tryParse(json['last_confirmed_at']) 
          : null,
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      categoryName: json['category']?['name'],
    );
  }

  /// Whether product is on sale
  bool get isOnSale => compareAtPrice != null && compareAtPrice! > price;
  
  /// Discount percentage
  int get discountPercent {
    if (!isOnSale) return 0;
    return (((compareAtPrice! - price) / compareAtPrice!) * 100).round();
  }

  /// Pricing label based on type
  String get pricingLabel {
    switch (pricingType) {
      case 'negotiable':
        return 'Negotiable';
      case 'service':
        return 'Service';
      default:
        return 'Fixed Price';
    }
  }

  /// First image or placeholder
  String? get primaryImage =>
      images.isNotEmpty ? images.first : null;
  
  /// Whether product is negotiable
  bool get isNegotiable => pricingType == 'negotiable';
  
  /// Getter for name (alias for title)
  String get name => title;
}

/// Request to create a store
class CreateStoreRequest {
  final String storeName;
  final String? tagline;
  final String? about;
  final String? logoUrl;
  final String? coverUrl;
  final String? categoryId;
  final String? whatsapp;
  final String? phone;
  final List<String>? deliveryOptions;
  final int? deliveryRadiusKm;
  final String? address;

  CreateStoreRequest({
    required this.storeName,
    this.tagline,
    this.about,
    this.logoUrl,
    this.coverUrl,
    this.categoryId,
    this.whatsapp,
    this.phone,
    this.deliveryOptions,
    this.deliveryRadiusKm,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'store_name': storeName,
    if (tagline != null) 'tagline': tagline,
    if (about != null) 'about': about,
    if (logoUrl != null) 'logo_url': logoUrl,
    if (coverUrl != null) 'cover_url': coverUrl,
    if (categoryId != null) 'category_id': categoryId,
    if (whatsapp != null) 'whatsapp': whatsapp,
    if (phone != null) 'phone': phone,
    if (deliveryOptions != null) 'delivery_options': deliveryOptions,
    if (deliveryRadiusKm != null) 'delivery_radius_km': deliveryRadiusKm,
    if (address != null) 'address': address,
  };
}

/// Request to create a product
class CreateProductRequest {
  final String title;
  final String? description;
  final double price;
  final double? compareAtPrice;
  final String? pricingType;
  final String? categoryId;
  final String? condition;
  final List<String>? images;
  final int? stockQuantity;

  CreateProductRequest({
    required this.title,
    this.description,
    required this.price,
    this.compareAtPrice,
    this.pricingType,
    this.categoryId,
    this.condition,
    this.images,
    this.stockQuantity,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null) 'description': description,
    'price': price,
    if (compareAtPrice != null) 'compare_at_price': compareAtPrice,
    if (pricingType != null) 'pricing_type': pricingType,
    if (categoryId != null) 'category_id': categoryId,
    if (condition != null) 'condition': condition,
    if (images != null) 'images': images,
    if (stockQuantity != null) 'stock_quantity': stockQuantity,
  };
}

/// Analytics data for a single day
class StoreAnalytics {
  final String id;
  final DateTime date;
  final int views;
  final int uniqueVisitors;
  final int productViews;
  final int enquiries;
  final int whatsappClicks;
  final int callClicks;
  final int followsGained;

  StoreAnalytics({
    required this.id,
    required this.date,
    required this.views,
    required this.uniqueVisitors,
    required this.productViews,
    required this.enquiries,
    required this.whatsappClicks,
    required this.callClicks,
    required this.followsGained,
  });

  factory StoreAnalytics.fromJson(Map<String, dynamic> json) {
    return StoreAnalytics(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      views: json['views'] ?? 0,
      uniqueVisitors: json['unique_visitors'] ?? 0,
      productViews: json['product_views'] ?? 0,
      enquiries: json['enquiries'] ?? 0,
      whatsappClicks: json['whatsapp_clicks'] ?? 0,
      callClicks: json['call_clicks'] ?? 0,
      followsGained: json['follows_gained'] ?? 0,
    );
  }
}

/// Dashboard response containing analytics data
class StoreAnalyticsResponse {
  final int totalViews;
  final int totalEnquiries;
  final int totalFollowers;
  final int totalProducts;
  final int viewsThisWeek;
  final int viewsThisMonth;
  final List<Product> topProducts;
  final List<StoreAnalytics> dailyStats;

  StoreAnalyticsResponse({
    required this.totalViews,
    required this.totalEnquiries,
    required this.totalFollowers,
    required this.totalProducts,
    required this.viewsThisWeek,
    required this.viewsThisMonth,
    this.topProducts = const [],
    this.dailyStats = const [],
  });

  factory StoreAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return StoreAnalyticsResponse(
      totalViews: json['total_views'] ?? 0,
      totalEnquiries: json['total_enquiries'] ?? 0,
      totalFollowers: json['total_followers'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      viewsThisWeek: json['views_this_week'] ?? 0,
      viewsThisMonth: json['views_this_month'] ?? 0,
      topProducts: json['top_products'] != null
          ? (json['top_products'] as List).map((e) => Product.fromJson(e)).toList()
          : [],
      dailyStats: json['daily_stats'] != null
          ? (json['daily_stats'] as List).map((e) => StoreAnalytics.fromJson(e)).toList()
          : [],
    );
  }
}

/// Stale Product (product needing attention)
class StaleProduct extends Product {
  final int daysStale;

  StaleProduct({
    required super.id,
    required super.storeId,
    required super.title,
    super.description,
    required super.price,
    super.compareAtPrice,
    super.pricingType,
    super.categoryId,
    super.condition,
    super.images,
    super.stockQuantity,
    super.isAvailable,
    super.isFeatured,
    super.views,
    super.enquiries,
    required super.createdAt,
    required super.updatedAt,
    super.lastConfirmedAt,
    super.store,
    super.categoryName,
    required this.daysStale,
  });

  factory StaleProduct.fromJson(Map<String, dynamic> json) {
    return StaleProduct(
      id: json['id'] ?? '',
      storeId: json['store_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      compareAtPrice: json['compare_at_price']?.toDouble(),
      pricingType: json['pricing_type'] ?? 'fixed',
      categoryId: json['category_id'],
      condition: json['condition'] ?? 'new',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      stockQuantity: json['stock_quantity'] ?? 1,
      isAvailable: json['is_available'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      views: json['views'] ?? 0,
      enquiries: json['enquiries'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      lastConfirmedAt: json['last_confirmed_at'] != null 
          ? DateTime.tryParse(json['last_confirmed_at']) 
          : null,
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
      categoryName: json['category']?['name'],
      daysStale: json['days_stale'] ?? 0,
    );
  }
}

