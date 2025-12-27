import 'dart:io';

/// API configuration for AirMass backend
class ApiConfig {
  /// Get the correct host based on platform
  static String get _host {
    // Android emulators use 10.0.2.2 to reach the host machine's localhost
    if (Platform.isAndroid) {
      return '10.0.2.2';
    }
    // iOS simulators and others use localhost
    return 'localhost';
  }

  /// Base URL for the API
  static String get baseUrl => 'http://$_host:8080/api';
  
  /// WebSocket URL
  static String get wsUrl => 'ws://$_host:8080/ws';
  
  /// Connection timeout in seconds
  static const int connectTimeout = 30;
  
  /// Receive timeout in seconds  
  static const int receiveTimeout = 30;
  
  /// API Endpoints
  static const String auth = '/auth';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  
  static const String users = '/users';
  static const String me = '/users/me';
  static const String updateTown = '/users/me/town';
  
  static const String towns = '/towns';
  static const String suburbs = '/suburbs';
  
  static const String categories = '/categories';
  
  static const String auctions = '/auctions';
  static const String myTownAuctions = '/auctions/my-town';
  static const String nationalAuctions = '/auctions/national';
  
  static const String notifications = '/notifications';
  static const String conversations = '/conversations';
  
  static const String products = '/products';
  static const String staleProducts = '/products/stale';
  static String confirmProduct(String id) => '/products/$id/confirm';
  
  static const String analytics = '/analytics';
  static const String batchTrack = '$analytics/events/batch';
}
