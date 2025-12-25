import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

/// WebSocket message types (matching backend)
class WsMessageType {
  // Client -> Server
  static const subscribe = 'subscribe';
  static const unsubscribe = 'unsubscribe';
  static const ping = 'ping';
  
  // Server -> Client
  static const bidNew = 'bid:new';
  static const bidOutbid = 'bid:outbid';
  static const auctionEnding = 'auction:ending';
  static const auctionEnded = 'auction:ended';
  static const auctionUpdate = 'auction:update';
  static const notificationNew = 'notification:new';
  static const messageNew = 'message:new';
  static const error = 'error';
  static const pong = 'pong';
}

/// WebSocket message model
class WsMessage {
  final String type;
  final String? auctionId;
  final String? userId;
  final Map<String, dynamic>? data;
  
  WsMessage({
    required this.type,
    this.auctionId,
    this.userId,
    this.data,
  });
  
  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      type: json['type'] as String,
      auctionId: json['auction_id'] as String?,
      userId: json['user_id'] as String?,
      data: json['data'] != null 
        ? (json['data'] is String 
            ? jsonDecode(json['data'] as String) as Map<String, dynamic>?
            : json['data'] as Map<String, dynamic>?)
        : null,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'type': type,
    if (auctionId != null) 'auction_id': auctionId,
    if (userId != null) 'user_id': userId,
    if (data != null) 'data': data,
  };
}

/// Bid update from WebSocket
class BidUpdate {
  final String auctionId;
  final String bidId;
  final String bidderId;
  final String? bidderName;
  final double amount;
  final int totalBids;
  final String? timeRemaining;
  final DateTime createdAt;
  
  BidUpdate({
    required this.auctionId,
    required this.bidId,
    required this.bidderId,
    this.bidderName,
    required this.amount,
    required this.totalBids,
    this.timeRemaining,
    required this.createdAt,
  });
  
  factory BidUpdate.fromJson(Map<String, dynamic> json) {
    return BidUpdate(
      auctionId: json['auction_id'] as String,
      bidId: json['bid_id'] as String? ?? json['id'] as String,
      bidderId: json['bidder_id'] as String,
      bidderName: json['bidder_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      totalBids: json['total_bids'] as int? ?? 0,
      timeRemaining: json['time_remaining'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// WebSocket connection state
enum WsConnectionState { disconnected, connecting, connected, error }

/// WebSocket service provider
final wsServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref.read(storageServiceProvider));
});

/// WebSocket Service for real-time updates
class WebSocketService {
  final StorageService _storage;
  WebSocketChannel? _channel;
  WsConnectionState _state = WsConnectionState.disconnected;
  
  // Stream controllers for different event types
  final _bidUpdateController = StreamController<BidUpdate>.broadcast();
  final _outbidController = StreamController<BidUpdate>.broadcast();
  final _auctionEndingController = StreamController<WsMessage>.broadcast();
  final _auctionEndedController = StreamController<WsMessage>.broadcast();
  final _auctionUpdateController = StreamController<WsMessage>.broadcast();
  final _notificationController = StreamController<WsMessage>.broadcast();
  final _messageController = StreamController<WsMessage>.broadcast();
  final _connectionStateController = StreamController<WsConnectionState>.broadcast();
  final _rawMessageController = StreamController<WsMessage>.broadcast();
  
  // Subscribed auction IDs
  final Set<String> _subscribedAuctions = {};
  
  // Reconnection settings
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const maxReconnectAttempts = 5;
  static const reconnectDelay = Duration(seconds: 3);
  
  // Ping/pong for keepalive
  Timer? _pingTimer;
  static const pingInterval = Duration(seconds: 30);
  
  WebSocketService(this._storage);
  
  // Streams
  Stream<BidUpdate> get bidUpdates => _bidUpdateController.stream;
  Stream<BidUpdate> get outbidNotifications => _outbidController.stream;
  Stream<WsMessage> get auctionEnding => _auctionEndingController.stream;
  Stream<WsMessage> get auctionEnded => _auctionEndedController.stream;
  Stream<WsMessage> get auctionUpdates => _auctionUpdateController.stream;
  Stream<WsMessage> get notifications => _notificationController.stream;
  Stream<WsMessage> get messages => _messageController.stream;
  Stream<WsConnectionState> get connectionState => _connectionStateController.stream;
  Stream<WsMessage> get rawMessages => _rawMessageController.stream;
  
  WsConnectionState get state => _state;
  bool get isConnected => _state == WsConnectionState.connected;
  
  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_state == WsConnectionState.connecting || _state == WsConnectionState.connected) {
      return;
    }
    
    _setState(WsConnectionState.connecting);
    
    try {
      final token = await _storage.getToken();
      final wsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/ws${token != null ? "?token=$token" : ""}');
      
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
      
      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;
      
      // Start ping timer
      _startPingTimer();
      
      // Resubscribe to any active auctions
      _resubscribeToAuctions();
      
    } catch (e) {
      _setState(WsConnectionState.error);
      _scheduleReconnect();
    }
  }
  
  /// Disconnect from WebSocket
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscribedAuctions.clear();
    _setState(WsConnectionState.disconnected);
  }
  
  /// Subscribe to auction updates
  void subscribeToAuction(String auctionId) {
    _subscribedAuctions.add(auctionId);
    _send(WsMessage(
      type: WsMessageType.subscribe,
      auctionId: auctionId,
    ));
  }
  
  /// Unsubscribe from auction updates
  void unsubscribeFromAuction(String auctionId) {
    _subscribedAuctions.remove(auctionId);
    _send(WsMessage(
      type: WsMessageType.unsubscribe,
      auctionId: auctionId,
    ));
  }
  
  /// Send a ping to keep connection alive
  void ping() {
    _send(WsMessage(type: WsMessageType.ping));
  }
  
  void _send(WsMessage message) {
    if (_channel != null && _state == WsConnectionState.connected) {
      _channel!.sink.add(jsonEncode(message.toJson()));
    }
  }
  
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WsMessage.fromJson(json);
      
      _rawMessageController.add(message);
      
      switch (message.type) {
        case WsMessageType.bidNew:
          if (message.data != null) {
            final bidUpdate = BidUpdate.fromJson(message.data!);
            _bidUpdateController.add(bidUpdate);
          }
          break;
          
        case WsMessageType.bidOutbid:
          if (message.data != null) {
            final bidUpdate = BidUpdate.fromJson(message.data!);
            _outbidController.add(bidUpdate);
          }
          break;
          
        case WsMessageType.auctionEnding:
          _auctionEndingController.add(message);
          break;
          
        case WsMessageType.auctionEnded:
          _auctionEndedController.add(message);
          break;
          
        case WsMessageType.auctionUpdate:
          _auctionUpdateController.add(message);
          break;
          
        case WsMessageType.notificationNew:
          _notificationController.add(message);
          break;
          
        case WsMessageType.messageNew:
          _messageController.add(message);
          break;
          
        case WsMessageType.pong:
          // Connection is alive, no action needed
          break;
          
        case WsMessageType.error:
          // Handle error message from server
          break;
      }
    } catch (e) {
      // Failed to parse message
    }
  }
  
  void _handleError(dynamic error) {
    _setState(WsConnectionState.error);
    _scheduleReconnect();
  }
  
  void _handleDisconnect() {
    _setState(WsConnectionState.disconnected);
    _pingTimer?.cancel();
    _scheduleReconnect();
  }
  
  void _setState(WsConnectionState newState) {
    _state = newState;
    _connectionStateController.add(newState);
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => ping());
  }
  
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      connect();
    });
  }
  
  void _resubscribeToAuctions() {
    for (final auctionId in _subscribedAuctions) {
      _send(WsMessage(
        type: WsMessageType.subscribe,
        auctionId: auctionId,
      ));
    }
  }
  
  /// Dispose all resources
  void dispose() {
    disconnect();
    _bidUpdateController.close();
    _outbidController.close();
    _auctionEndingController.close();
    _auctionEndedController.close();
    _auctionUpdateController.close();
    _notificationController.close();
    _messageController.close();
    _connectionStateController.close();
    _rawMessageController.close();
  }
}
