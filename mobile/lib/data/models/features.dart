import 'user.dart';
import 'category.dart';

/// =============================================================================
/// AUTO-BID MODELS
/// =============================================================================

/// AutoBid represents an auto-bid configuration
class AutoBid {
  final String id;
  final String auctionId;
  final String userId;
  final double maxAmount;
  final double? currentBidAmount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deactivatedAt;
  final String? deactivationReason;
  
  // Extended
  final String? auctionTitle;
  final double? currentPrice;
  final double? startingPrice;
  final DateTime? endTime;

  AutoBid({
    required this.id,
    required this.auctionId,
    required this.userId,
    required this.maxAmount,
    this.currentBidAmount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deactivatedAt,
    this.deactivationReason,
    this.auctionTitle,
    this.currentPrice,
    this.startingPrice,
    this.endTime,
  });

  factory AutoBid.fromJson(Map<String, dynamic> json) {
    return AutoBid(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      userId: json['user_id'] as String,
      maxAmount: (json['max_amount'] as num).toDouble(),
      currentBidAmount: json['current_bid_amount'] != null
          ? (json['current_bid_amount'] as num).toDouble()
          : null,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deactivatedAt: json['deactivated_at'] != null
          ? DateTime.parse(json['deactivated_at'] as String)
          : null,
      deactivationReason: json['deactivation_reason'] as String?,
      auctionTitle: json['auction_title'] as String?,
      currentPrice: json['current_price'] != null
          ? (json['current_price'] as num).toDouble()
          : null,
      startingPrice: json['starting_price'] != null
          ? (json['starting_price'] as num).toDouble()
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
    );
  }
}

/// AutoBidResponse after setting auto-bid
class AutoBidResponse {
  final AutoBid? autoBid;
  final String message;
  final double currentBid;
  final double nextBid;
  final int bidsPlaced;
  final bool isHighBidder;

  AutoBidResponse({
    this.autoBid,
    required this.message,
    required this.currentBid,
    required this.nextBid,
    required this.bidsPlaced,
    required this.isHighBidder,
  });

  factory AutoBidResponse.fromJson(Map<String, dynamic> json) {
    return AutoBidResponse(
      autoBid: json['auto_bid'] != null
          ? AutoBid.fromJson(json['auto_bid'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String? ?? '',
      currentBid: (json['current_bid'] as num?)?.toDouble() ?? 0,
      nextBid: (json['next_bid'] as num?)?.toDouble() ?? 0,
      bidsPlaced: json['bids_placed'] as int? ?? 0,
      isHighBidder: json['is_high_bidder'] as bool? ?? false,
    );
  }
}

/// =============================================================================
/// SAVED SEARCH MODELS
/// =============================================================================

/// SavedSearch represents a user's saved search
class SavedSearch {
  final String id;
  final String userId;
  final String name;
  final String? searchQuery;
  final String? categoryId;
  final String? townId;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? keywords;
  final String? condition;
  final bool notifyNewListings;
  final bool notifyPriceDrops;
  final bool notifyEmail;
  final bool notifyPush;
  final int matchCount;
  final bool isActive;
  final DateTime? lastNotifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined
  final Category? category;
  final Town? town;

  SavedSearch({
    required this.id,
    required this.userId,
    required this.name,
    this.searchQuery,
    this.categoryId,
    this.townId,
    this.minPrice,
    this.maxPrice,
    this.keywords,
    this.condition,
    this.notifyNewListings = true,
    this.notifyPriceDrops = false,
    this.notifyEmail = true,
    this.notifyPush = true,
    this.matchCount = 0,
    this.isActive = true,
    this.lastNotifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.town,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Search',
      searchQuery: json['search_query'] as String?,
      categoryId: json['category_id'] as String?,
      townId: json['town_id'] as String?,
      minPrice: json['min_price'] != null ? (json['min_price'] as num).toDouble() : null,
      maxPrice: json['max_price'] != null ? (json['max_price'] as num).toDouble() : null,
      keywords: json['keywords'] != null ? List<String>.from(json['keywords'] as List) : null,
      condition: json['condition'] as String?,
      notifyNewListings: json['notify_new_listings'] as bool? ?? true,
      notifyPriceDrops: json['notify_price_drops'] as bool? ?? false,
      notifyEmail: json['notify_email'] as bool? ?? true,
      notifyPush: json['notify_push'] as bool? ?? true,
      matchCount: json['match_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      lastNotifiedAt: json['last_notified_at'] != null
          ? DateTime.parse(json['last_notified_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      town: json['town'] != null
          ? Town.fromJson(json['town'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// =============================================================================
/// PROMOTION MODELS
/// =============================================================================

/// PromotionPricing for available promotion options
class PromotionPricing {
  final String id;
  final String name;
  final String promotionType;
  final int durationHours;
  final double price;
  final double boostMultiplier;
  final String description;
  final bool isActive;
  final String? townId;

  PromotionPricing({
    required this.id,
    required this.name,
    required this.promotionType,
    required this.durationHours,
    required this.price,
    required this.boostMultiplier,
    required this.description,
    this.isActive = true,
    this.townId,
  });

  factory PromotionPricing.fromJson(Map<String, dynamic> json) {
    return PromotionPricing(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      promotionType: json['promotion_type'] as String? ?? 'featured',
      durationHours: json['duration_hours'] as int? ?? 24,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      boostMultiplier: (json['boost_multiplier'] as num?)?.toDouble() ?? 1.0,
      description: json['description'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      townId: json['town_id'] as String?,
    );
  }

  String get durationFormatted {
    if (durationHours < 24) return '$durationHours hours';
    if (durationHours == 24) return '1 day';
    if (durationHours < 168) return '${durationHours ~/ 24} days';
    if (durationHours == 168) return '1 week';
    return '${durationHours ~/ 168} weeks';
  }
}

/// PromotedAuction representing active promotion
class PromotedAuction {
  final String id;
  final String auctionId;
  final String userId;
  final String promotionType;
  final String? townId;
  final DateTime startsAt;
  final DateTime endsAt;
  final double amountPaid;
  final bool isActive;
  final int impressions;
  final int clicks;
  final double boostMultiplier;
  final String paymentStatus;
  final DateTime createdAt;

  PromotedAuction({
    required this.id,
    required this.auctionId,
    required this.userId,
    required this.promotionType,
    this.townId,
    required this.startsAt,
    required this.endsAt,
    required this.amountPaid,
    this.isActive = true,
    this.impressions = 0,
    this.clicks = 0,
    this.boostMultiplier = 1.0,
    this.paymentStatus = 'pending',
    required this.createdAt,
  });

  factory PromotedAuction.fromJson(Map<String, dynamic> json) {
    return PromotedAuction(
      id: json['id'] as String,
      auctionId: json['auction_id'] as String,
      userId: json['user_id'] as String,
      promotionType: json['promotion_type'] as String? ?? 'featured',
      townId: json['town_id'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      impressions: json['impressions'] as int? ?? 0,
      clicks: json['clicks'] as int? ?? 0,
      boostMultiplier: (json['boost_multiplier'] as num?)?.toDouble() ?? 1.0,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isExpired => DateTime.now().isAfter(endsAt);
  Duration get timeRemaining => endsAt.difference(DateTime.now());
}

/// =============================================================================
/// USER REPUTATION MODELS
/// =============================================================================

/// UserReputation with detailed trust info
class UserReputation {
  final String userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final double rating;
  final int ratingCount;
  final int completedAuctions;
  final String badgeLevel; // none, bronze, silver, gold
  final bool isTrustedSeller;
  final bool isVerified;
  final bool isFastResponder;
  final double completionRate;
  final int totalTransactions;
  final int successfulTransactions;
  final DateTime memberSince;
  final List<String> badges;

  UserReputation({
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.rating = 0,
    this.ratingCount = 0,
    this.completedAuctions = 0,
    this.badgeLevel = 'none',
    this.isTrustedSeller = false,
    this.isVerified = false,
    this.isFastResponder = false,
    this.completionRate = 100,
    this.totalTransactions = 0,
    this.successfulTransactions = 0,
    required this.memberSince,
    this.badges = const [],
  });

  factory UserReputation.fromJson(Map<String, dynamic> json) {
    return UserReputation(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      completedAuctions: json['completed_auctions'] as int? ?? 0,
      badgeLevel: json['badge_level'] as String? ?? 'none',
      isTrustedSeller: json['is_trusted_seller'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isFastResponder: json['is_fast_responder'] as bool? ?? false,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 100,
      totalTransactions: json['total_transactions'] as int? ?? 0,
      successfulTransactions: json['successful_transactions'] as int? ?? 0,
      memberSince: json['member_since'] != null
          ? DateTime.parse(json['member_since'] as String)
          : DateTime.now(),
      badges: json['badges'] != null
          ? List<String>.from(json['badges'] as List)
          : [],
    );
  }

  String get ratingDisplay => rating.toStringAsFixed(1);
  bool get isTopSeller => rating >= 4.5 && completedAuctions >= 10;
  
  String get badgeEmoji {
    switch (badgeLevel) {
      case 'gold': return '🥇';
      case 'silver': return '🥈';
      case 'bronze': return '🥉';
      default: return '';
    }
  }
}

/// UserRating represents a review
class UserRating {
  final String id;
  final String raterId;
  final String ratedUserId;
  final String? auctionId;
  final int rating;
  final int? communicationRating;
  final int? accuracyRating;
  final int? speedRating;
  final String? review;
  final String role; // buyer, seller
  final bool wouldRecommend;
  final DateTime createdAt;
  final User? rater;

  UserRating({
    required this.id,
    required this.raterId,
    required this.ratedUserId,
    this.auctionId,
    required this.rating,
    this.communicationRating,
    this.accuracyRating,
    this.speedRating,
    this.review,
    required this.role,
    this.wouldRecommend = true,
    required this.createdAt,
    this.rater,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      id: json['id'] as String,
      raterId: json['rater_id'] as String? ?? '',
      ratedUserId: json['rated_user_id'] as String? ?? '',
      auctionId: json['auction_id'] as String?,
      rating: json['rating'] as int? ?? 5,
      communicationRating: json['communication_rating'] as int?,
      accuracyRating: json['accuracy_rating'] as int?,
      speedRating: json['speed_rating'] as int?,
      review: json['review'] as String?,
      role: json['role'] as String? ?? 'buyer',
      wouldRecommend: json['would_recommend'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      rater: json['rater'] != null
          ? User.fromJson(json['rater'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// =============================================================================
/// TOWN LEADERBOARD MODELS
/// =============================================================================

/// LeaderboardEntry for town rankings
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String badgeLevel;
  final double score;
  final int metricValue;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.badgeLevel = 'none',
    required this.score,
    required this.metricValue,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      badgeLevel: json['badge_level'] as String? ?? 'none',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      metricValue: json['metric_value'] as int? ?? 0,
    );
  }

  String get badgeEmoji {
    switch (badgeLevel) {
      case 'gold': return '🥇';
      case 'silver': return '🥈';
      case 'bronze': return '🥉';
      default: return '';
    }
  }
}

/// TownLeaderboard with all entries
class TownLeaderboard {
  final String townId;
  final String townName;
  final String leaderboardType;
  final String period;
  final List<LeaderboardEntry> entries;
  final DateTime calculatedAt;

  TownLeaderboard({
    required this.townId,
    required this.townName,
    required this.leaderboardType,
    required this.period,
    required this.entries,
    required this.calculatedAt,
  });

  factory TownLeaderboard.fromJson(Map<String, dynamic> json) {
    return TownLeaderboard(
      townId: json['town_id'] as String,
      townName: json['town_name'] as String? ?? '',
      leaderboardType: json['leaderboard_type'] as String? ?? 'top_sellers',
      period: json['period'] as String? ?? 'monthly',
      entries: (json['entries'] as List?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      calculatedAt: json['calculated_at'] != null
          ? DateTime.parse(json['calculated_at'] as String)
          : DateTime.now(),
    );
  }
}

/// TownStats aggregated statistics
class TownStats {
  final String townId;
  final String townName;
  final int activeAuctions;
  final int totalAuctions;
  final int totalUsers;
  final int activeSellers;
  final double totalSalesValue;
  final double avgAuctionPrice;
  final String? topCategoryId;
  final Category? topCategory;
  final DateTime calculatedAt;

  TownStats({
    required this.townId,
    required this.townName,
    this.activeAuctions = 0,
    this.totalAuctions = 0,
    this.totalUsers = 0,
    this.activeSellers = 0,
    this.totalSalesValue = 0,
    this.avgAuctionPrice = 0,
    this.topCategoryId,
    this.topCategory,
    required this.calculatedAt,
  });

  factory TownStats.fromJson(Map<String, dynamic> json) {
    return TownStats(
      townId: json['town_id'] as String,
      townName: json['town_name'] as String? ?? '',
      activeAuctions: json['active_auctions'] as int? ?? 0,
      totalAuctions: json['total_auctions'] as int? ?? 0,
      totalUsers: json['total_users'] as int? ?? 0,
      activeSellers: json['active_sellers'] as int? ?? 0,
      totalSalesValue: (json['total_sales_value'] as num?)?.toDouble() ?? 0,
      avgAuctionPrice: (json['avg_auction_price'] as num?)?.toDouble() ?? 0,
      topCategoryId: json['top_category_id'] as String?,
      topCategory: json['top_category'] != null
          ? Category.fromJson(json['top_category'] as Map<String, dynamic>)
          : null,
      calculatedAt: json['calculated_at'] != null
          ? DateTime.parse(json['calculated_at'] as String)
          : DateTime.now(),
    );
  }
}
