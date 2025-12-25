import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../../core/network/dio_client.dart';

/// Auction repository provider
final auctionRepositoryProvider = Provider<AuctionRepository>((ref) {
  return AuctionRepository(ref.read(dioClientProvider));
});

/// Auction repository
class AuctionRepository {
  final DioClient _client;
  
  AuctionRepository(this._client);
  
  /// Get auctions with filters
  Future<AuctionListResponse> getAuctions({
    String? townId,
    String? suburbId,
    String? categoryId,
    String? sellerId,
    String? status,
    String? query,
    int page = 1,
    int limit = 20,
    String? sortBy,
    bool? national,
  }) async {
    final response = await _client.get('/auctions', queryParameters: {
      if (townId != null) 'town_id': townId,
      if (suburbId != null) 'suburb_id': suburbId,
      if (categoryId != null) 'category_id': categoryId,
      if (sellerId != null) 'seller_id': sellerId,
      if (status != null) 'status': status,
      if (query != null) 'q': query,
      'page': page,
      'limit': limit,
      if (sortBy != null) 'sort_by': sortBy,
      if (national != null) 'national': national,
    });
    
    return AuctionListResponse.fromJson(response.data);
  }
  
  /// Get auctions in user's town
  Future<AuctionListResponse> getMyTownAuctions({int page = 1, int limit = 20}) async {
    final response = await _client.get('/auctions/my-town', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return AuctionListResponse.fromJson(response.data);
  }
  
  /// Get national auctions
  Future<AuctionListResponse> getNationalAuctions({int page = 1, int limit = 20}) async {
    final response = await _client.get('/auctions/national', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return AuctionListResponse.fromJson(response.data);
  }
  
  /// Get ending soon auctions
  Future<AuctionListResponse> getEndingSoon({String? townId, int limit = 10}) async {
    final response = await _client.get('/auctions', queryParameters: {
      'status': 'ending_soon',
      if (townId != null) 'town_id': townId,
      'limit': limit,
      'sort_by': 'ending_soon',
    });
    return AuctionListResponse.fromJson(response.data);
  }
  
  /// Get auction by ID
  Future<Auction> getAuction(String id) async {
    final response = await _client.get('/auctions/$id');
    return Auction.fromJson(response.data);
  }
  
  /// Create auction
  Future<Auction> createAuction({
    required String title,
    String? description,
    required double startingPrice,
    double? reservePrice,
    double bidIncrement = 5.0,
    required String categoryId,
    required String townId,
    String? suburbId,
    required String condition,
    required List<String> images,
    String? pickupLocation,
    bool shippingAvailable = false,
    bool allowOffers = false,
  }) async {
    final response = await _client.post('/auctions', data: {
      'title': title,
      'description': description,
      'starting_price': startingPrice,
      'reserve_price': reservePrice,
      'bid_increment': bidIncrement,
      'category_id': categoryId,
      'town_id': townId,
      'suburb_id': suburbId,
      'condition': condition,
      'images': images,
      'pickup_location': pickupLocation,
      'shipping_available': shippingAvailable,
      'allow_offers': allowOffers,
    });
    
    return Auction.fromJson(response.data);
  }
  
  /// Update auction
  Future<Auction> updateAuction(String id, Map<String, dynamic> data) async {
    final response = await _client.put('/auctions/$id', data: data);
    return Auction.fromJson(response.data);
  }
  
  /// Cancel auction
  Future<void> cancelAuction(String id) async {
    await _client.delete('/auctions/$id');
  }
  
  /// Get bid history for auction
  Future<List<Bid>> getBidHistory(String auctionId) async {
    final response = await _client.get('/auctions/$auctionId/bids');
    return (response.data['bids'] as List?)
        ?.map((b) => Bid.fromJson(b as Map<String, dynamic>))
        .toList() ?? [];
  }
  
  /// Place bid - returns BidResponse with next bid info
  Future<BidResponse> placeBid(String auctionId, double amount) async {
    final response = await _client.post('/auctions/$auctionId/bids', data: {
      'amount': amount,
    });
    return BidResponse.fromJson(response.data);
  }
  
  /// Get user's auctions
  Future<AuctionListResponse> getMyAuctions({String? status, int page = 1, int limit = 20}) async {
    final response = await _client.get('/users/me/auctions', queryParameters: {
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    });
    return AuctionListResponse.fromJson(response.data);
  }
  
  /// Get user's bids
  Future<List<Bid>> getMyBids({int page = 1, int limit = 20}) async {
    final response = await _client.get('/users/me/bids', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return (response.data['bids'] as List?)
        ?.map((b) => Bid.fromJson(b as Map<String, dynamic>))
        .toList() ?? [];
  }
  
  /// Get won auctions
  Future<AuctionListResponse> getWonAuctions({int page = 1, int limit = 20}) async {
    final response = await _client.get('/users/me/won', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return AuctionListResponse.fromJson(response.data);
  }
  
  /// Add to watchlist
  Future<void> addToWatchlist(String auctionId) async {
    await _client.post('/users/me/watchlist/$auctionId');
  }
  
  /// Remove from watchlist
  Future<void> removeFromWatchlist(String auctionId) async {
    await _client.delete('/users/me/watchlist/$auctionId');
  }
  
  /// Get watchlist
  Future<AuctionListResponse> getWatchlist({int page = 1, int limit = 20}) async {
    final response = await _client.get('/users/me/watchlist', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return AuctionListResponse.fromJson(response.data);
  }
  
  /// Search auctions
  Future<AuctionListResponse> searchAuctions(String query, {
    String? townId,
    String? categoryId,
    bool national = false,
    int page = 1,
    int limit = 20,
  }) async {
    return getAuctions(
      query: query,
      townId: townId,
      categoryId: categoryId,
      national: national,
      page: page,
      limit: limit,
    );
  }
}
