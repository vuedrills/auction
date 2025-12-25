import 'user.dart';
import 'category.dart';

/// Auction status enum
enum AuctionStatus {
  draft,
  pending,
  active,
  endingSoon,
  ended,
  sold,
  cancelled,
}

extension AuctionStatusX on AuctionStatus {
  String get value {
    switch (this) {
      case AuctionStatus.endingSoon:
        return 'ending_soon';
      default:
        return name;
    }
  }

  static AuctionStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return AuctionStatus.draft;
      case 'pending':
        return AuctionStatus.pending;
      case 'active':
        return AuctionStatus.active;
      case 'ending_soon':
        return AuctionStatus.endingSoon;
      case 'ended':
        return AuctionStatus.ended;
      case 'sold':
        return AuctionStatus.sold;
      case 'cancelled':
        return AuctionStatus.cancelled;
      default:
        return AuctionStatus.active;
    }
  }
}

/// Auction model
class Auction {
  final String id;
  final String title;
  final String? description;
  final double startingPrice;
  final double? currentPrice;
  final double? reservePrice;
  final double bidIncrement;
  final String sellerId;
  final String? winnerId;
  final String categoryId;
  final String townId;
  final String? suburbId;
  final AuctionStatus status;
  final String condition;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? originalEndTime;
  final int antiSnipeMinutes;
  final int totalBids;
  final int views;
  final List<String> images;
  final bool isFeatured;
  final bool allowOffers;
  final String? pickupLocation;
  final bool shippingAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final User? seller;
  final User? winner;
  final Category? category;
  final Town? town;
  final Suburb? suburb;

  // Computed fields
  final String? timeRemaining;
  final bool isEndingSoon;
  final double minNextBid;
  final bool userIsHighBidder;
  final bool userHasBid;
  final List<String> tags; // hot auction tags: trending, bidding_war, ending_soon, featured

  Auction({
    required this.id,
    required this.title,
    this.description,
    required this.startingPrice,
    this.currentPrice,
    this.reservePrice,
    required this.bidIncrement,
    required this.sellerId,
    this.winnerId,
    required this.categoryId,
    required this.townId,
    this.suburbId,
    required this.status,
    required this.condition,
    this.startTime,
    this.endTime,
    this.originalEndTime,
    this.antiSnipeMinutes = 5,
    this.totalBids = 0,
    this.views = 0,
    required this.images,
    this.isFeatured = false,
    this.allowOffers = false,
    this.pickupLocation,
    this.shippingAvailable = false,
    required this.createdAt,
    required this.updatedAt,
    this.seller,
    this.winner,
    this.category,
    this.town,
    this.suburb,
    this.timeRemaining,
    this.isEndingSoon = false,
    this.minNextBid = 0,
    this.userIsHighBidder = false,
    this.userHasBid = false,
    this.tags = const [],
  });

  /// Get display price (current or starting)
  double get displayPrice => currentPrice ?? startingPrice;

  /// Get first image URL
  String? get primaryImage => images.isNotEmpty ? images.first : null;

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startingPrice: (json['starting_price'] as num).toDouble(),
      currentPrice: json['current_price'] != null 
          ? (json['current_price'] as num).toDouble() 
          : null,
      reservePrice: json['reserve_price'] != null 
          ? (json['reserve_price'] as num).toDouble() 
          : null,
      bidIncrement: (json['bid_increment'] as num?)?.toDouble() ?? 1.0,
      sellerId: json['seller_id'] as String,
      winnerId: json['winner_id'] as String?,
      categoryId: json['category_id'] as String,
      townId: json['town_id'] as String,
      suburbId: json['suburb_id'] as String?,
      status: AuctionStatusX.fromString(json['status'] as String? ?? 'active'),
      condition: json['condition'] as String? ?? 'used',
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time'] as String) 
          : null,
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time'] as String) 
          : null,
      originalEndTime: json['original_end_time'] != null 
          ? DateTime.parse(json['original_end_time'] as String) 
          : null,
      antiSnipeMinutes: json['anti_snipe_minutes'] as int? ?? 5,
      totalBids: json['total_bids'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      images: json['images'] != null 
          ? List<String>.from(json['images'] as List) 
          : [],
      isFeatured: json['is_featured'] as bool? ?? false,
      allowOffers: json['allow_offers'] as bool? ?? false,
      pickupLocation: json['pickup_location'] as String?,
      shippingAvailable: json['shipping_available'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      seller: json['seller'] != null 
          ? User.fromJson(json['seller'] as Map<String, dynamic>) 
          : null,
      winner: json['winner'] != null 
          ? User.fromJson(json['winner'] as Map<String, dynamic>) 
          : null,
      category: json['category'] != null 
          ? Category.fromJson(json['category'] as Map<String, dynamic>) 
          : null,
      town: json['town'] != null 
          ? Town.fromJson(json['town'] as Map<String, dynamic>) 
          : null,
      suburb: json['suburb'] != null 
          ? Suburb.fromJson(json['suburb'] as Map<String, dynamic>) 
          : null,
      timeRemaining: json['time_remaining'] as String?,
      isEndingSoon: json['is_ending_soon'] as bool? ?? false,
      minNextBid: (json['min_next_bid'] as num?)?.toDouble() ?? 0,
      userIsHighBidder: json['user_is_high_bidder'] as bool? ?? false,
      userHasBid: json['user_has_bid'] as bool? ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'starting_price': startingPrice,
      'current_price': currentPrice,
      'reserve_price': reservePrice,
      'bid_increment': bidIncrement,
      'seller_id': sellerId,
      'winner_id': winnerId,
      'category_id': categoryId,
      'town_id': townId,
      'suburb_id': suburbId,
      'status': status.value,
      'condition': condition,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'original_end_time': originalEndTime?.toIso8601String(),
      'anti_snipe_minutes': antiSnipeMinutes,
      'total_bids': totalBids,
      'views': views,
      'images': images,
      'is_featured': isFeatured,
      'allow_offers': allowOffers,
      'pickup_location': pickupLocation,
      'shipping_available': shippingAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Auction copyWith({
    double? currentPrice,
    int? totalBids,
    DateTime? endTime,
    String? timeRemaining,
    bool? isEndingSoon,
    double? minNextBid,
    bool? userIsHighBidder,
    bool? userHasBid,
  }) {
    return Auction(
      id: id,
      title: title,
      description: description,
      startingPrice: startingPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      reservePrice: reservePrice,
      bidIncrement: bidIncrement,
      sellerId: sellerId,
      winnerId: winnerId,
      categoryId: categoryId,
      townId: townId,
      suburbId: suburbId,
      status: status,
      condition: condition,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      originalEndTime: originalEndTime,
      antiSnipeMinutes: antiSnipeMinutes,
      totalBids: totalBids ?? this.totalBids,
      views: views,
      images: images,
      isFeatured: isFeatured,
      allowOffers: allowOffers,
      pickupLocation: pickupLocation,
      shippingAvailable: shippingAvailable,
      createdAt: createdAt,
      updatedAt: updatedAt,
      seller: seller,
      winner: winner,
      category: category,
      town: town,
      suburb: suburb,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isEndingSoon: isEndingSoon ?? this.isEndingSoon,
      minNextBid: minNextBid ?? this.minNextBid,
      userIsHighBidder: userIsHighBidder ?? this.userIsHighBidder,
      userHasBid: userHasBid ?? this.userHasBid,
    );
  }
}

/// Auction list response
class AuctionListResponse {
  final List<Auction> auctions;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  AuctionListResponse({
    required this.auctions,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AuctionListResponse.fromJson(Map<String, dynamic> json) {
    return AuctionListResponse(
      auctions: (json['auctions'] as List?)
          ?.map((a) => Auction.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}
