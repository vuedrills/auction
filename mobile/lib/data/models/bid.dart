import 'user.dart';
import 'auction.dart';

/// Bid model
class Bid {
  final String id;
  final String auctionId;
  final String bidderId;
  final double amount;
  final bool isWinning;
  final bool isAutoBid;
  final double? maxAutoBid;
  final DateTime createdAt;
  final User? bidder;
  final Auction? auction;

  Bid({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.amount,
    this.isWinning = false,
    this.isAutoBid = false,
    this.maxAutoBid,
    required this.createdAt,
    this.bidder,
    this.auction,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'] as String? ?? '',
      auctionId: json['auction_id'] as String? ?? '',
      bidderId: json['bidder_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isWinning: json['is_winning'] as bool? ?? false,
      isAutoBid: json['is_auto_bid'] as bool? ?? false,
      maxAutoBid: json['max_auto_bid'] != null 
          ? (json['max_auto_bid'] as num).toDouble() 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      bidder: json['bidder'] != null 
          ? User.fromJson(json['bidder'] as Map<String, dynamic>) 
          : null,
      auction: json['auction'] != null 
          ? Auction.fromJson(json['auction'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'bidder_id': bidderId,
      'amount': amount,
      'is_winning': isWinning,
      'is_auto_bid': isAutoBid,
      'max_auto_bid': maxAutoBid,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Bid history response
class BidHistory {
  final List<Bid> bids;
  final int totalBids;
  final double highestBid;
  final double nextBidAmount; // The ONLY valid next bid
  final double nextIncrement; // The increment for next bid

  BidHistory({
    required this.bids,
    required this.totalBids,
    required this.highestBid,
    this.nextBidAmount = 0,
    this.nextIncrement = 0,
  });

  factory BidHistory.fromJson(Map<String, dynamic> json) {
    return BidHistory(
      bids: (json['bids'] as List?)
          ?.map((b) => Bid.fromJson(b as Map<String, dynamic>))
          .toList() ?? [],
      totalBids: json['total_bids'] as int? ?? 0,
      highestBid: (json['highest_bid'] as num?)?.toDouble() ?? 0,
      nextBidAmount: (json['next_bid_amount'] as num?)?.toDouble() ?? 0,
      nextIncrement: (json['next_increment'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Bid response
class BidResponse {
  final Bid? bid;
  final bool isHighBidder;
  final String message;
  final double? newPrice;
  final bool timeExtended;
  final DateTime? newEndTime;
  final double nextBidAmount; // The ONLY valid next bid
  final double nextIncrement; // The increment for next bid

  BidResponse({
    this.bid,
    required this.isHighBidder,
    required this.message,
    this.newPrice,
    required this.timeExtended,
    this.newEndTime,
    this.nextBidAmount = 0,
    this.nextIncrement = 0,
  });

  factory BidResponse.fromJson(Map<String, dynamic> json) {
    return BidResponse(
      bid: json['bid'] != null 
          ? Bid.fromJson(json['bid'] as Map<String, dynamic>) 
          : null,
      isHighBidder: json['is_high_bidder'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      newPrice: (json['new_price'] as num?)?.toDouble(),
      timeExtended: json['time_extended'] as bool? ?? false,
      newEndTime: json['new_end_time'] != null 
          ? DateTime.parse(json['new_end_time'] as String) 
          : null,
      nextBidAmount: (json['next_bid_amount'] as num?)?.toDouble() ?? 0,
      nextIncrement: (json['next_increment'] as num?)?.toDouble() ?? 0,
    );
  }
}

