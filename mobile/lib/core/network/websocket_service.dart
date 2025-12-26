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
  static const auctionWon = 'auction:won';
  static const auctionSold = 'auction:sold';
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
      print('[WS] Already connected or connecting. State: $_state');
      return;
    }
    
    _setState(WsConnectionState.connecting);
    print('[WS] Connecting...');
    
    try {
      final token = await _storage.getToken();
      
      // Construct URL with token if available, but handle null case gracefully for logging
      // Note: Backend likely requires token for authentication
      final url = '${ApiConfig.wsUrl}${token != null ? "?token=$token" : ""}';
      print('[WS] Connecting to: ${ApiConfig.wsUrl} (Token present: ${token != null})');
      
      final uri = Uri.parse(url);
      
      _channel = WebSocketChannel.connect(uri);
      print('[WS] Channel created');
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
      
      _setState(WsConnectionState.connected);
      print('[WS] Connection established successfully');
      _reconnectAttempts = 0;
      
      // Start ping timer
      _startPingTimer();
      
      // Resubscribe to any active auctions
      _resubscribeToAuctions();
      
    } catch (e) {
      print('[WS] Connection exception: $e');
      _setState(WsConnectionState.error);
      _scheduleReconnect();
    }
  }
  
  /// Disconnect from WebSocket
  void disconnect() {
    print('[WS] Disconnecting manually');
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscribedAuctions.clear();
    _setState(WsConnectionState.disconnected);
  }
  
  /// Subscribe to auction updates
  void subscribeToAuction(String auctionId) {
    if (_subscribedAuctions.contains(auctionId)) {
        print('[WS] Already subscribed to auction: $auctionId');
        // If connected, ensure server knows (idempotent)
        if (isConnected) {
            _send(WsMessage(
                type: WsMessageType.subscribe,
                auctionId: auctionId,
            ));
        }
        return;
    }

    print('[WS] Subscribing to auction: $auctionId');
    _subscribedAuctions.add(auctionId);
    if (isConnected) {
        _send(WsMessage(
            type: WsMessageType.subscribe,
            auctionId: auctionId,
        ));
    } else {
        print('[WS] Queueing subscription for reconnection: $auctionId');
    }
  }
  
  /// Unsubscribe from auction updates
  void unsubscribeFromAuction(String auctionId) {
    print('[WS] Unsubscribing from auction: $auctionId');
    _subscribedAuctions.remove(auctionId);
    if (isConnected) {
        _send(WsMessage(
            type: WsMessageType.unsubscribe,
            auctionId: auctionId,
        ));
    }
  }
  
  /// Send a ping to keep connection alive
  void ping() {
    // print('[WS] Sending PING');
    _send(WsMessage(type: WsMessageType.ping));
  }
  
  void _send(WsMessage message) {
    if (_channel != null && _state == WsConnectionState.connected) {
      final jsonStr = jsonEncode(message.toJson());
      // print('[WS] Sending: $jsonStr');
      _channel!.sink.add(jsonStr);
    } else {
        print('[WS] Dropped message (not connected): ${message.type}');
    }
  }
  
  void _handleMessage(dynamic data) {
    final rawData = data.toString();
    print('[WS] Received raw: $rawData'); // Uncommented for debugging
    
    // Handle potentially multiple concatenated JSON messages (e.g. "}{")
    // This happens if the backend writes multiple messages quickly
    final List<String> messages = [];
    
    // Heuristic: If we can decode it fully, it's one message.
    // If not, try to split.
    try {
      jsonDecode(rawData);
      messages.add(rawData);
    } catch (_) {
      // Failed to decode as one object. Try to split.
      // We look for "}{" or "}\n{" pattern.
      // A simple regex split might break internal strings, but it's a good first attempt 
      // for this specific backend protocol.
      // Ideally, the backend should delimit frames, but we must be robust.
      
      // Regex matches } followed by optional whitespace/newlines followed by {
      // We use a lookbehind/lookahead equivalent by replacing the boundary first
      final processed = rawData.replaceAllMapped(
        RegExp(r'\}\s*\{'), 
        (match) => '}|${match.group(0)!.substring(1)}' // "}|{" or "}|\n{"
      );
      
      // Now split by the pipe we inserted (assuming pipe is safe, or use a rare char)
      // Actually, let's just split by the regex directly if we handle the braces correctly.
      
      // safer approach: Just use the regex to find indices?
      // Let's use a simpler approach: Split by `}\n{` or `}{` and reconstruct.
      
      final parts = rawData.split(RegExp(r'(?<=\})\s*(?=\{)'));
      messages.addAll(parts);
    }

    for (final jsonStr in messages) {
      if (jsonStr.trim().isEmpty) continue;
      
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final message = WsMessage.fromJson(json);
        
        print('[WS] Parsed message: ${message.type}');
        _rawMessageController.add(message);
        
        switch (message.type) {
          case WsMessageType.bidNew:
          print('[WS] New Bid received! notifying listeners.');
          if (message.data != null) {
            // Backend sends auction_id in wrapper, but model expects it in data
            final data = Map<String, dynamic>.from(message.data!);
            if (data['auction_id'] == null && message.auctionId != null) {
              data['auction_id'] = message.auctionId;
            }
            
            try {
              final bidUpdate = BidUpdate.fromJson(data);
              _bidUpdateController.add(bidUpdate);
            } catch (e) {
               print('[WS] Error parsing bid update: $e');
            }
          }
          break;
          
        case WsMessageType.bidOutbid:
          print('[WS] Outbid notification received!');
          if (message.data != null) {
            final data = Map<String, dynamic>.from(message.data!);
            if (data['auction_id'] == null && message.auctionId != null) {
              data['auction_id'] = message.auctionId;
            }
            
            try {
              final bidUpdate = BidUpdate.fromJson(data);
              _outbidController.add(bidUpdate);
            } catch (e) {
               print('[WS] Error parsing outbid: $e');
            }
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
          case WsMessageType.auctionWon:
          case WsMessageType.auctionSold:
            _notificationController.add(message);
            break;
            
          case WsMessageType.messageNew:
            print('[WS] New Chat Message received!');
            _messageController.add(message);
            break;
            
          case WsMessageType.pong:
            // Connection is alive, no action needed
            break;
            
          case WsMessageType.error:
            print('[WS] Error from server: ${message.data}');
            break;
        }
      } catch (e) {
        print('[WS] Error parsing message chunk: $e');
        print('[WS] Chunk content: $jsonStr');
      }
    }
  }
  
  void _handleError(dynamic error) {
    print('[WS] Socket Error: $error');
    _setState(WsConnectionState.error);
    _scheduleReconnect();
  }
  
  void _handleDisconnect() {
    print('[WS] Socket Disconnected');
    _setState(WsConnectionState.disconnected);
    _pingTimer?.cancel();
    _scheduleReconnect();
  }
  
  void _setState(WsConnectionState newState) {
    if (_state != newState) {
        print('[WS] State change: $_state -> $newState');
        _state = newState;
        _connectionStateController.add(newState);
    }
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => ping());
  }
  
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('[WS] Max reconnect attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    final delay = reconnectDelay * (_reconnectAttempts + 1);
    print('[WS] Scheduling reconnect in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');
    
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }
  
  void _resubscribeToAuctions() {
    if (_subscribedAuctions.isNotEmpty) {
        print('[WS] Resubscribing to ${_subscribedAuctions.length} auctions');
        for (final auctionId in _subscribedAuctions) {
            _send(WsMessage(
                type: WsMessageType.subscribe,
                auctionId: auctionId,
            ));
        }
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
