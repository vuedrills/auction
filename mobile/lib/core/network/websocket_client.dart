import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

/// WebSocket client provider
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return WebSocketClient(storageService);
});

/// WebSocket message types
enum WSMessageType {
  subscribe,
  unsubscribe,
  ping,
  pong,
  bidNew,
  bidOutbid,
  auctionEnding,
  auctionEnded,
  auctionUpdate,
  notificationNew,
  messageNew,
  error,
}

/// WebSocket message
class WSMessage {
  final WSMessageType type;
  final String? auctionId;
  final String? userId;
  final Map<String, dynamic>? data;

  WSMessage({
    required this.type,
    this.auctionId,
    this.userId,
    this.data,
  });

  factory WSMessage.fromJson(Map<String, dynamic> json) {
    return WSMessage(
      type: _parseType(json['type'] as String?),
      auctionId: json['auction_id'] as String?,
      userId: json['user_id'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': _typeToString(type),
      if (auctionId != null) 'auction_id': auctionId,
      if (userId != null) 'user_id': userId,
      if (data != null) 'data': data,
    };
  }

  static WSMessageType _parseType(String? type) {
    switch (type) {
      case 'bid:new':
        return WSMessageType.bidNew;
      case 'bid:outbid':
        return WSMessageType.bidOutbid;
      case 'auction:ending':
        return WSMessageType.auctionEnding;
      case 'auction:ended':
        return WSMessageType.auctionEnded;
      case 'auction:update':
        return WSMessageType.auctionUpdate;
      case 'notification:new':
        return WSMessageType.notificationNew;
      case 'message:new':
        return WSMessageType.messageNew;
      case 'pong':
        return WSMessageType.pong;
      case 'error':
        return WSMessageType.error;
      default:
        return WSMessageType.ping;
    }
  }

  static String _typeToString(WSMessageType type) {
    switch (type) {
      case WSMessageType.subscribe:
        return 'subscribe';
      case WSMessageType.unsubscribe:
        return 'unsubscribe';
      case WSMessageType.ping:
        return 'ping';
      default:
        return type.name;
    }
  }
}

/// WebSocket client for real-time updates
class WebSocketClient {
  final StorageService _storageService;
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  final _messageController = StreamController<WSMessage>.broadcast();
  Stream<WSMessage> get messages => _messageController.stream;

  bool get isConnected => _isConnected;

  WebSocketClient(this._storageService);

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await _storageService.getToken();
      final uri = Uri.parse('${ApiConfig.wsUrl}${token != null ? '?token=$token' : ''}');
      
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _reconnectAttempts = 0;

      // Listen for messages
      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final message = WSMessage.fromJson(json);
            _messageController.add(message);
          } catch (e) {
            print('WebSocket parse error: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('WebSocket closed');
          _handleDisconnect();
        },
      );

      // Start ping timer
      _startPingTimer();
    } catch (e) {
      print('WebSocket connection error: $e');
      _handleDisconnect();
    }
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  /// Subscribe to auction updates
  void subscribeToAuction(String auctionId) {
    _send(WSMessage(
      type: WSMessageType.subscribe,
      auctionId: auctionId,
    ));
  }

  /// Unsubscribe from auction updates
  void unsubscribeFromAuction(String auctionId) {
    _send(WSMessage(
      type: WSMessageType.unsubscribe,
      auctionId: auctionId,
    ));
  }

  void _send(WSMessage message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message.toJson()));
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _send(WSMessage(type: WSMessageType.ping));
    });
  }

  void _handleDisconnect() {
    _isConnected = false;
    _pingTimer?.cancel();

    // Attempt reconnection
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: _reconnectAttempts * 2);
      print('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
      
      _reconnectTimer = Timer(delay, () {
        connect();
      });
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
