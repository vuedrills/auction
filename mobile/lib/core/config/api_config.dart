/// API configuration for AirMass backend
class ApiConfig {
  /// Base URL for the API
  static const String baseUrl = 'http://localhost:8080/api';
  
  /// WebSocket URL
  static const String wsUrl = 'ws://localhost:8080/ws';
  
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
}
