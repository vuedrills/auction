import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Secure and regular storage service
class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _homeTownIdKey = 'home_town_id';
  
  // Secure Storage Methods (for sensitive data)
  
  /// Save auth token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }
  
  /// Get auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  
  /// Delete auth token
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
  
  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: _userIdKey, value: userId);
  }
  
  /// Get user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }
  
  /// Clear all secure storage
  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }
  
  // Shared Preferences Methods (for non-sensitive data)
  
  /// Get SharedPreferences instance
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();
  
  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }
  
  /// Set onboarding complete
  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_onboardingCompleteKey, value);
  }
  
  /// Save home town ID
  Future<void> saveHomeTownId(String townId) async {
    final prefs = await _prefs;
    await prefs.setString(_homeTownIdKey, townId);
  }
  
  /// Get home town ID
  Future<String?> getHomeTownId() async {
    final prefs = await _prefs;
    return prefs.getString(_homeTownIdKey);
  }
  
  /// Clear all storage (logout)
  Future<void> clearAll() async {
    await clearSecureStorage();
    final prefs = await _prefs;
    await prefs.clear();
  }
}
