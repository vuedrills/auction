import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/features.dart';
import '../../core/network/dio_client.dart';

/// Repository for advanced features: auto-bid, saved searches, promotions, etc.
class FeaturesRepository {
  final DioClient _client;

  FeaturesRepository(this._client);

  // ==========================================================================
  // AUTO-BID
  // ==========================================================================

  /// Set auto-bid for an auction
  Future<AutoBidResponse> setAutoBid(String auctionId, double maxAmount) async {
    final response = await _client.post('/auctions/$auctionId/auto-bid', data: {
      'max_amount': maxAmount,
    });
    return AutoBidResponse.fromJson(response.data);
  }

  /// Cancel auto-bid for an auction
  Future<void> cancelAutoBid(String auctionId) async {
    await _client.delete('/auctions/$auctionId/auto-bid');
  }

  /// Get all user's auto-bids
  Future<List<AutoBid>> getMyAutoBids() async {
    final response = await _client.get('/auto-bids');
    return (response.data['auto_bids'] as List?)
            ?.map((ab) => AutoBid.fromJson(ab as Map<String, dynamic>))
            .toList() ??
        [];
  }

  // ==========================================================================
  // SAVED SEARCHES
  // ==========================================================================

  /// Create a saved search
  Future<String> createSavedSearch({
    required String name,
    String? searchQuery,
    String? categoryId,
    String? townId,
    double? minPrice,
    double? maxPrice,
    List<String>? keywords,
    String? condition,
    bool notifyNewListings = true,
    bool notifyPriceDrops = false,
    bool notifyEmail = true,
    bool notifyPush = true,
  }) async {
    final response = await _client.post('/saved-searches', data: {
      'name': name,
      if (searchQuery != null) 'search_query': searchQuery,
      if (categoryId != null) 'category_id': categoryId,
      if (townId != null) 'town_id': townId,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (keywords != null) 'keywords': keywords,
      if (condition != null) 'condition': condition,
      'notify_new_listings': notifyNewListings,
      'notify_price_drops': notifyPriceDrops,
      'notify_email': notifyEmail,
      'notify_push': notifyPush,
    });
    return response.data['id'] as String;
  }

  /// Get all user's saved searches
  Future<List<SavedSearch>> getMySavedSearches() async {
    final response = await _client.get('/saved-searches');
    return (response.data['saved_searches'] as List?)
            ?.map((s) => SavedSearch.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
  }

  /// Delete a saved search
  Future<void> deleteSavedSearch(String searchId) async {
    await _client.delete('/saved-searches/$searchId');
  }

  // ==========================================================================
  // PROMOTIONS
  // ==========================================================================

  /// Get available promotion pricing
  Future<List<PromotionPricing>> getPromotionPricing({String? townId}) async {
    final response = await _client.get('/promotions/pricing', queryParameters: {
      if (townId != null) 'town_id': townId,
    });
    return (response.data['pricing'] as List?)
            ?.map((p) => PromotionPricing.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];
  }

  /// Promote an auction
  Future<PromotedAuction> promoteAuction(String auctionId, String pricingId) async {
    final response = await _client.post('/auctions/$auctionId/promote', data: {
      'pricing_id': pricingId,
    });
    return PromotedAuction.fromJson(response.data['promotion'] as Map<String, dynamic>);
  }

  // ==========================================================================
  // USER REPUTATION & RATINGS
  // ==========================================================================

  /// Get user reputation details
  Future<UserReputation> getUserReputation(String userId) async {
    final response = await _client.get('/users/$userId/reputation');
    return UserReputation.fromJson(response.data);
  }

  /// Get user ratings
  Future<({List<UserRating> ratings, double average, int totalRatings})> getUserRatings(String userId) async {
    final response = await _client.get('/users/$userId/ratings');
    return (
      ratings: (response.data['ratings'] as List?)
              ?.map((r) => UserRating.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      average: (response.data['average'] as num?)?.toDouble() ?? 0,
      totalRatings: response.data['total_ratings'] as int? ?? 0,
    );
  }

  /// Rate a user
  Future<String> rateUser({
    required String userId,
    String? auctionId,
    required int rating,
    int? communicationRating,
    int? accuracyRating,
    int? speedRating,
    String? review,
    bool wouldRecommend = true,
  }) async {
    final response = await _client.post(
      '/users/$userId/ratings',
      queryParameters: {
        if (auctionId != null) 'auction_id': auctionId,
      },
      data: {
        'rating': rating,
        if (communicationRating != null) 'communication_rating': communicationRating,
        if (accuracyRating != null) 'accuracy_rating': accuracyRating,
        if (speedRating != null) 'speed_rating': speedRating,
        if (review != null) 'review': review,
        'would_recommend': wouldRecommend,
      },
    );
    return response.data['id'] as String;
  }

  // ==========================================================================
  // TOWN COMMUNITY
  // ==========================================================================

  /// Get town leaderboard
  Future<TownLeaderboard> getTownLeaderboard(
    String townId, {
    String type = 'top_sellers',
    String period = 'monthly',
  }) async {
    final response = await _client.get('/towns/$townId/leaderboard', queryParameters: {
      'type': type,
      'period': period,
    });
    return TownLeaderboard.fromJson(response.data);
  }

  /// Get town stats
  Future<TownStats> getTownStats(String townId) async {
    final response = await _client.get('/towns/$townId/stats');
    return TownStats.fromJson(response.data);
  }

  /// Get top sellers in town
  Future<List<UserReputation>> getTopSellersInTown(String townId) async {
    final response = await _client.get('/towns/$townId/top-sellers');
    return (response.data['top_sellers'] as List?)
            ?.map((s) => UserReputation.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
  }
}

/// Provider for FeaturesRepository
final featuresRepositoryProvider = Provider<FeaturesRepository>((ref) {
  final client = ref.read(dioClientProvider);
  return FeaturesRepository(client);
});
