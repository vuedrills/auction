/// Category model
class Category {
  final String id;
  final String name;
  final String? icon;
  final String? description;
  final String? parentId;
  final int sortOrder;
  final bool isActive;
  final int activeAuctions;
  final List<Category>? children;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
    this.activeAuctions = 0,
    this.children,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      parentId: json['parent_id'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      activeAuctions: json['active_auctions'] as int? ?? 0,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => Category.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_active': isActive,
      'active_auctions': activeAuctions,
    };
  }
}

/// Category slot model (for town-first logic)
class CategorySlot {
  final String? id;
  final String categoryId;
  final String townId;
  final int maxActiveAuctions;
  final int auctionDurationHours;
  final int currentActive;
  final bool hasAvailableSlot;
  final int waitingCount;

  CategorySlot({
    this.id,
    required this.categoryId,
    required this.townId,
    this.maxActiveAuctions = 10,
    this.auctionDurationHours = 168,
    this.currentActive = 0,
    this.hasAvailableSlot = true,
    this.waitingCount = 0,
  });

  factory CategorySlot.fromJson(Map<String, dynamic> json) {
    return CategorySlot(
      id: json['id'] as String?,
      categoryId: json['category_id'] as String,
      townId: json['town_id'] as String,
      maxActiveAuctions: json['max_active_auctions'] as int? ?? 10,
      auctionDurationHours: json['auction_duration_hours'] as int? ?? 168,
      currentActive: json['current_active'] as int? ?? 0,
      hasAvailableSlot: json['has_available_slot'] as bool? ?? true,
      waitingCount: json['waiting_count'] as int? ?? 0,
    );
  }
}
