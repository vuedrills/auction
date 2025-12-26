import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auction.dart';
import '../models/bid.dart';
import '../repositories/auction_repository.dart';
import 'auth_provider.dart';

/// Auction list state
class AuctionListState {
  final List<Auction> auctions;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;
  
  const AuctionListState({
    this.auctions = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });
  
  AuctionListState copyWith({
    List<Auction>? auctions,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return AuctionListState(
      auctions: auctions ?? this.auctions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

/// My Town auctions provider
class MyTownAuctionsNotifier extends StateNotifier<AuctionListState> {
  final AuctionRepository _repository;
  
  MyTownAuctionsNotifier(this._repository) : super(const AuctionListState());
  
  Future<void> loadAuctions({bool refresh = false}) async {
    if (state.isLoading) return;
    
    final newPage = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _repository.getMyTownAuctions(page: newPage);
      state = AuctionListState(
        auctions: refresh ? response.auctions : [...state.auctions, ...response.auctions],
        isLoading: false,
        hasMore: response.page < response.totalPages,
        page: newPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> refresh() => loadAuctions(refresh: true);
}

final myTownAuctionsProvider = StateNotifierProvider<MyTownAuctionsNotifier, AuctionListState>((ref) {
  ref.watch(currentUserProvider); // Reset when user changes
  return MyTownAuctionsNotifier(ref.read(auctionRepositoryProvider));
});

/// Ending soon auctions provider
final endingSoonProvider = FutureProvider.family<List<Auction>, String?>((ref, townId) async {
  final repository = ref.read(auctionRepositoryProvider);
  final response = await repository.getEndingSoon(townId: townId, limit: 10);
  return response.auctions;
});

/// National auctions provider
class NationalAuctionsNotifier extends StateNotifier<AuctionListState> {
  final AuctionRepository _repository;
  
  NationalAuctionsNotifier(this._repository) : super(const AuctionListState());
  
  Future<void> loadAuctions({bool refresh = false}) async {
    if (state.isLoading) return;
    
    final newPage = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _repository.getNationalAuctions(page: newPage);
      state = AuctionListState(
        auctions: refresh ? response.auctions : [...state.auctions, ...response.auctions],
        isLoading: false,
        hasMore: response.page < response.totalPages,
        page: newPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> refresh() => loadAuctions(refresh: true);
}

final nationalAuctionsProvider = StateNotifierProvider<NationalAuctionsNotifier, AuctionListState>((ref) {
  return NationalAuctionsNotifier(ref.read(auctionRepositoryProvider));
});

/// Single auction detail provider
final auctionDetailProvider = FutureProvider.family<Auction, String>((ref, id) async {
  final repository = ref.read(auctionRepositoryProvider);
  return repository.getAuction(id);
});

/// Bid history provider
final bidHistoryProvider = FutureProvider.family<List<Bid>, String>((ref, auctionId) async {
  final repository = ref.read(auctionRepositoryProvider);
  return repository.getBidHistory(auctionId);
});

/// My auctions provider
class MyAuctionsNotifier extends StateNotifier<AuctionListState> {
  final AuctionRepository _repository;
  String? _statusFilter;
  
  MyAuctionsNotifier(this._repository) : super(const AuctionListState());
  
  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadAuctions(refresh: true);
  }
  
  Future<void> loadAuctions({bool refresh = false}) async {
    if (state.isLoading) return;
    
    final newPage = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _repository.getMyAuctions(
        status: _statusFilter,
        page: newPage,
      );
      state = AuctionListState(
        auctions: refresh ? response.auctions : [...state.auctions, ...response.auctions],
        isLoading: false,
        hasMore: response.page < response.totalPages,
        page: newPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> refresh() => loadAuctions(refresh: true);
}

final myAuctionsProvider = StateNotifierProvider<MyAuctionsNotifier, AuctionListState>((ref) {
  ref.watch(currentUserProvider); // Reset/re-create when user changes
  return MyAuctionsNotifier(ref.read(auctionRepositoryProvider));
});

/// My bids provider
final myBidsProvider = FutureProvider<List<Bid>>((ref) async {
  ref.watch(currentUserProvider); // Refresh when user changes
  final repository = ref.read(auctionRepositoryProvider);
  return repository.getMyBids();
});

/// Won auctions provider
final wonAuctionsProvider = FutureProvider<AuctionListResponse>((ref) async {
  ref.watch(currentUserProvider); // Refresh when user changes
  final repository = ref.read(auctionRepositoryProvider);
  return repository.getWonAuctions();
});

/// Watchlist provider
class WatchlistNotifier extends StateNotifier<AuctionListState> {
  final AuctionRepository _repository;
  
  WatchlistNotifier(this._repository) : super(const AuctionListState());
  
  Future<void> loadWatchlist({bool refresh = false}) async {
    if (state.isLoading) return;
    
    final newPage = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _repository.getWatchlist(page: newPage);
      state = AuctionListState(
        auctions: refresh ? response.auctions : [...state.auctions, ...response.auctions],
        isLoading: false,
        hasMore: response.page < response.totalPages,
        page: newPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> addToWatchlist(String auctionId) async {
    await _repository.addToWatchlist(auctionId);
    loadWatchlist(refresh: true);
  }
  
  Future<void> removeFromWatchlist(String auctionId) async {
    await _repository.removeFromWatchlist(auctionId);
    state = state.copyWith(
      auctions: state.auctions.where((a) => a.id != auctionId).toList(),
    );
  }
  
  Future<void> refresh() => loadWatchlist(refresh: true);
}

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, AuctionListState>((ref) {
  ref.watch(currentUserProvider); // Reset/re-create when user changes
  return WatchlistNotifier(ref.read(auctionRepositoryProvider));
});

/// Search auctions provider
class SearchAuctionsNotifier extends StateNotifier<AuctionListState> {
  final AuctionRepository _repository;
  String _query = '';
  String? _townId;
  String? _categoryId;
  bool _national = false;
  
  SearchAuctionsNotifier(this._repository) : super(const AuctionListState());
  
  void setQuery(String query) {
    _query = query;
    if (query.length >= 2) {
      search(refresh: true);
    }
  }
  
  void setFilters({String? townId, String? categoryId, bool? national}) {
    _townId = townId ?? _townId;
    _categoryId = categoryId ?? _categoryId;
    _national = national ?? _national;
    if (_query.isNotEmpty) search(refresh: true);
  }
  
  Future<void> search({bool refresh = false}) async {
    if (state.isLoading || _query.isEmpty) return;
    
    final newPage = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _repository.searchAuctions(
        _query,
        townId: _townId,
        categoryId: _categoryId,
        national: _national,
        page: newPage,
      );
      state = AuctionListState(
        auctions: refresh ? response.auctions : [...state.auctions, ...response.auctions],
        isLoading: false,
        hasMore: response.page < response.totalPages,
        page: newPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  void clear() {
    _query = '';
    state = const AuctionListState();
  }
}

final searchAuctionsProvider = StateNotifierProvider<SearchAuctionsNotifier, AuctionListState>((ref) {
  return SearchAuctionsNotifier(ref.read(auctionRepositoryProvider));
});

/// Place bid provider
final placeBidProvider = FutureProvider.family<BidResponse, ({String auctionId, double amount})>((ref, params) async {
  final repository = ref.read(auctionRepositoryProvider);
  return repository.placeBid(params.auctionId, params.amount);
});

/// Category auctions provider
final categoryAuctionsProvider = FutureProvider.family<AuctionListResponse, ({String categoryId, String? townId})>((ref, params) async {
  final repository = ref.read(auctionRepositoryProvider);
  return repository.getAuctions(
    categoryId: params.categoryId,
    townId: params.townId,
  );
});

/// Suburb auctions provider
final suburbAuctionsProvider = FutureProvider.family<AuctionListResponse, String>((ref, suburbId) async {
  final repository = ref.read(auctionRepositoryProvider);
  return repository.getAuctions(suburbId: suburbId);
});

/// Town + Category auctions provider
final townCategoryAuctionsProvider = FutureProvider.family<AuctionListResponse, ({String townId, String categoryId})>((ref, params) async {
  final repository = ref.read(auctionRepositoryProvider);
  return repository.getAuctions(
    townId: params.townId,
    categoryId: params.categoryId,
  );
});

/// User's auctions provider (for viewing other user's listings)
final userAuctionsProvider = FutureProvider.family<AuctionListResponse, String>((ref, userId) async {
  final repository = ref.read(auctionRepositoryProvider);
  return repository.getAuctions(sellerId: userId);
});


