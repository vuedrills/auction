import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/websocket_service.dart';
import '../models/auction.dart';
import '../repositories/auction_repository.dart';
import 'auction_provider.dart';

/// WebSocket connection state provider
final wsConnectionStateProvider = StreamProvider<WsConnectionState>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  return wsService.connectionState;
});

/// Is WebSocket connected provider
final wsConnectedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(wsConnectionStateProvider);
  return connectionState.when(
    data: (state) => state == WsConnectionState.connected,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Real-time bid updates stream provider
final bidUpdatesProvider = StreamProvider<BidUpdate>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  return wsService.bidUpdates;
});

/// Outbid notifications stream provider
final outbidNotificationsProvider = StreamProvider<BidUpdate>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  return wsService.outbidNotifications;
});

/// Auction ending notifications stream provider
final auctionEndingProvider = StreamProvider<WsMessage>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  return wsService.auctionEnding;
});

/// Auction ended notifications stream provider
final auctionEndedProvider = StreamProvider<WsMessage>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  return wsService.auctionEnded;
});

/// WebSocket manager notifier - handles connection lifecycle
class WebSocketManager extends StateNotifier<WsConnectionState> {
  final WebSocketService _wsService;
  final Ref _ref;
  StreamSubscription? _bidSubscription;
  
  WebSocketManager(this._wsService, this._ref) : super(WsConnectionState.disconnected) {
    _initialize();
  }
  
  void _initialize() {
    // Listen to connection state
    _wsService.connectionState.listen((state) {
      this.state = state;
    });
    
    // Listen to bid updates and update auction state
    _bidSubscription = _wsService.bidUpdates.listen((bidUpdate) {
      _handleBidUpdate(bidUpdate);
    });
  }
  
  void _handleBidUpdate(BidUpdate update) {
    // Update the auction detail if it's cached
    // This will trigger a refresh of the UI
    _ref.invalidate(auctionDetailProvider(update.auctionId));
    _ref.invalidate(bidHistoryProvider(update.auctionId));
  }
  
  /// Connect to WebSocket
  Future<void> connect() async {
    await _wsService.connect();
  }
  
  /// Disconnect from WebSocket
  void disconnect() {
    _wsService.disconnect();
  }
  
  /// Subscribe to auction updates
  void subscribeToAuction(String auctionId) {
    if (_wsService.isConnected) {
      _wsService.subscribeToAuction(auctionId);
    }
  }
  
  /// Unsubscribe from auction updates
  void unsubscribeFromAuction(String auctionId) {
    if (_wsService.isConnected) {
      _wsService.unsubscribeFromAuction(auctionId);
    }
  }
  
  @override
  void dispose() {
    _bidSubscription?.cancel();
    super.dispose();
  }
}

final wsManagerProvider = StateNotifierProvider<WebSocketManager, WsConnectionState>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  return WebSocketManager(wsService, ref);
});

/// Live auction detail provider with WebSocket updates
/// This combines REST fetch with real-time WebSocket updates
class LiveAuctionNotifier extends StateNotifier<AsyncValue<Auction>> {
  final AuctionRepository _repository;
  final WebSocketService _wsService;
  final String auctionId;
  StreamSubscription? _bidSubscription;
  
  LiveAuctionNotifier(this._repository, this._wsService, this.auctionId) 
      : super(const AsyncValue.loading()) {
    _initialize();
  }
  
  void _initialize() {
    // Fetch initial auction data
    _fetchAuction();
    
    // Subscribe to WebSocket updates for this auction
    if (_wsService.isConnected) {
      _wsService.subscribeToAuction(auctionId);
    }
    
    // Listen for bid updates
    _bidSubscription = _wsService.bidUpdates
        .where((update) => update.auctionId == auctionId)
        .listen(_handleBidUpdate);
  }
  
  Future<void> _fetchAuction() async {
    state = const AsyncValue.loading();
    try {
      final auction = await _repository.getAuction(auctionId);
      state = AsyncValue.data(auction);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  void _handleBidUpdate(BidUpdate update) {
    state.whenData((auction) {
      // Update the auction with new bid data
      final updatedAuction = auction.copyWith(
        currentPrice: update.amount,
        totalBids: update.totalBids,
        timeRemaining: update.timeRemaining,
      );
      state = AsyncValue.data(updatedAuction);
    });
  }
  
  Future<void> refresh() async {
    await _fetchAuction();
  }
  
  @override
  void dispose() {
    _bidSubscription?.cancel();
    if (_wsService.isConnected) {
      _wsService.unsubscribeFromAuction(auctionId);
    }
    super.dispose();
  }
}

/// Provider for live auction with real-time updates
final liveAuctionProvider = StateNotifierProvider.family<LiveAuctionNotifier, AsyncValue<Auction>, String>((ref, auctionId) {
  final repository = ref.read(auctionRepositoryProvider);
  final wsService = ref.read(wsServiceProvider);
  return LiveAuctionNotifier(repository, wsService, auctionId);
});

/// Bid updates for a specific auction
final auctionBidUpdatesProvider = StreamProvider.family<BidUpdate, String>((ref, auctionId) {
  final wsService = ref.watch(wsServiceProvider);
  return wsService.bidUpdates.where((update) => update.auctionId == auctionId);
});

/// Outbid notifications for current user
class OutbidNotifier extends StateNotifier<List<BidUpdate>> {
  final WebSocketService _wsService;
  StreamSubscription? _subscription;
  
  OutbidNotifier(this._wsService) : super([]) {
    _subscription = _wsService.outbidNotifications.listen((update) {
      state = [...state, update];
    });
  }
  
  void clearNotification(String auctionId) {
    state = state.where((u) => u.auctionId != auctionId).toList();
  }
  
  void clearAll() {
    state = [];
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final outbidNotifierProvider = StateNotifierProvider<OutbidNotifier, List<BidUpdate>>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  return OutbidNotifier(wsService);
});
