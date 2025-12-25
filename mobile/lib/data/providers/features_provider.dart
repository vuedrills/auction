import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/features.dart';
import '../repositories/features_repository.dart';

// =============================================================================
// AUTO-BID PROVIDERS
// =============================================================================

/// Get user's auto-bids
final myAutoBidsProvider = FutureProvider<List<AutoBid>>((ref) async {
  final repository = ref.read(featuresRepositoryProvider);
  return repository.getMyAutoBids();
});

/// Set auto-bid state notifier
class AutoBidNotifier extends StateNotifier<AsyncValue<AutoBidResponse?>> {
  final FeaturesRepository _repository;
  
  AutoBidNotifier(this._repository) : super(const AsyncValue.data(null));
  
  Future<AutoBidResponse> setAutoBid(String auctionId, double maxAmount) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.setAutoBid(auctionId, maxAmount);
      state = AsyncValue.data(response);
      return response;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
  
  Future<void> cancelAutoBid(String auctionId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelAutoBid(auctionId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final autoBidNotifierProvider = StateNotifierProvider<AutoBidNotifier, AsyncValue<AutoBidResponse?>>((ref) {
  return AutoBidNotifier(ref.read(featuresRepositoryProvider));
});

// =============================================================================
// SAVED SEARCHES PROVIDERS
// =============================================================================

/// Get user's saved searches
final savedSearchesProvider = FutureProvider<List<SavedSearch>>((ref) async {
  final repository = ref.read(featuresRepositoryProvider);
  return repository.getMySavedSearches();
});

/// Saved search management
class SavedSearchNotifier extends StateNotifier<AsyncValue<List<SavedSearch>>> {
  final FeaturesRepository _repository;
  final Ref _ref;
  
  SavedSearchNotifier(this._repository, this._ref) : super(const AsyncValue.data([]));
  
  Future<void> loadSearches() async {
    state = const AsyncValue.loading();
    try {
      final searches = await _repository.getMySavedSearches();
      state = AsyncValue.data(searches);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<String> createSearch({
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
  }) async {
    final id = await _repository.createSavedSearch(
      name: name,
      searchQuery: searchQuery,
      categoryId: categoryId,
      townId: townId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      keywords: keywords,
      condition: condition,
      notifyNewListings: notifyNewListings,
      notifyPriceDrops: notifyPriceDrops,
    );
    _ref.invalidate(savedSearchesProvider);
    return id;
  }
  
  Future<void> deleteSearch(String searchId) async {
    await _repository.deleteSavedSearch(searchId);
    _ref.invalidate(savedSearchesProvider);
  }
}

final savedSearchNotifierProvider = StateNotifierProvider<SavedSearchNotifier, AsyncValue<List<SavedSearch>>>((ref) {
  return SavedSearchNotifier(ref.read(featuresRepositoryProvider), ref);
});

// =============================================================================
// PROMOTION PROVIDERS
// =============================================================================

/// Get promotion pricing
final promotionPricingProvider = FutureProvider.family<List<PromotionPricing>, String?>((ref, townId) async {
  final repository = ref.read(featuresRepositoryProvider);
  return repository.getPromotionPricing(townId: townId);
});

/// Promote auction notifier
class PromotionNotifier extends StateNotifier<AsyncValue<PromotedAuction?>> {
  final FeaturesRepository _repository;
  
  PromotionNotifier(this._repository) : super(const AsyncValue.data(null));
  
  Future<PromotedAuction> promoteAuction(String auctionId, String pricingId) async {
    state = const AsyncValue.loading();
    try {
      final promotion = await _repository.promoteAuction(auctionId, pricingId);
      state = AsyncValue.data(promotion);
      return promotion;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final promotionNotifierProvider = StateNotifierProvider<PromotionNotifier, AsyncValue<PromotedAuction?>>((ref) {
  return PromotionNotifier(ref.read(featuresRepositoryProvider));
});

// =============================================================================
// REPUTATION PROVIDERS
// =============================================================================

/// Get user reputation
final userReputationProvider = FutureProvider.family<UserReputation, String>((ref, userId) async {
  final repository = ref.read(featuresRepositoryProvider);
  return repository.getUserReputation(userId);
});

/// Get user ratings
final userRatingsProvider = FutureProvider.family<({List<UserRating> ratings, double average, int totalRatings}), String>((ref, userId) async {
  final repository = ref.read(featuresRepositoryProvider);
  return repository.getUserRatings(userId);
});

/// Rate user notifier
class RatingNotifier extends StateNotifier<AsyncValue<void>> {
  final FeaturesRepository _repository;
  final Ref _ref;
  
  RatingNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));
  
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
    state = const AsyncValue.loading();
    try {
      final id = await _repository.rateUser(
        userId: userId,
        auctionId: auctionId,
        rating: rating,
        communicationRating: communicationRating,
        accuracyRating: accuracyRating,
        speedRating: speedRating,
        review: review,
        wouldRecommend: wouldRecommend,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(userRatingsProvider(userId));
      _ref.invalidate(userReputationProvider(userId));
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final ratingNotifierProvider = StateNotifierProvider<RatingNotifier, AsyncValue<void>>((ref) {
  return RatingNotifier(ref.read(featuresRepositoryProvider), ref);
});

// =============================================================================
// TOWN COMMUNITY PROVIDERS
// =============================================================================

/// Get town leaderboard
final townLeaderboardProvider = FutureProvider.family<TownLeaderboard, ({String townId, String type, String period})>((ref, params) async {
  final repository = ref.read(featuresRepositoryProvider);
  return repository.getTownLeaderboard(
    params.townId,
    type: params.type,
    period: params.period,
  );
});

/// Get town stats
final townStatsProvider = FutureProvider.family<TownStats, String>((ref, townId) async {
  final repository = ref.read(featuresRepositoryProvider);
  return repository.getTownStats(townId);
});

/// Get top sellers in town
final topSellersInTownProvider = FutureProvider.family<List<UserReputation>, String>((ref, townId) async {
  final repository = ref.read(featuresRepositoryProvider);
  return repository.getTopSellersInTown(townId);
});
