import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/storage_service.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioClientProvider), ref.read(storageServiceProvider));
});

/// Google Sign-In instance
final _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
);

/// Authentication repository
class AuthRepository {
  final DioClient _client;
  final StorageService _storage;
  
  AuthRepository(this._client, this._storage);
  
  /// Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    final response = await _client.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    final authResponse = AuthResponse.fromJson(response.data);
    await _storage.saveToken(authResponse.token);
    return authResponse;
  }
  
  /// Login with Google
  /// Returns AuthResponse on success, throws exception with 'new_user' if home town needed
  Future<AuthResponse> loginWithGoogle({String? homeTownId, String? homeSuburbId}) async {
    // Trigger Google Sign-In flow
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In cancelled');
    }
    
    // Get the ID token
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    
    if (idToken == null) {
      throw Exception('Failed to get Google ID token');
    }
    
    // Send to backend
    final response = await _client.post('/auth/google', data: {
      'id_token': idToken,
      if (homeTownId != null) 'home_town_id': homeTownId,
      if (homeSuburbId != null) 'home_suburb_id': homeSuburbId,
    });
    
    final authResponse = AuthResponse.fromJson(response.data);
    await _storage.saveToken(authResponse.token);
    return authResponse;
  }
  
  /// Sign out from Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }
  
  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String? phone,
    required String homeTownId,
    String? homeSuburbId,
  }) async {
    final response = await _client.post('/auth/register', data: {
      'email': email,
      'username': username,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'home_town_id': homeTownId,
      'home_suburb_id': homeSuburbId,
    });
    
    final authResponse = AuthResponse.fromJson(response.data);
    await _storage.saveToken(authResponse.token);
    return authResponse;
  }
  
  /// Refresh token
  Future<String> refreshToken() async {
    final response = await _client.post('/auth/refresh');
    final newToken = response.data['token'] as String;
    await _storage.saveToken(newToken);
    return newToken;
  }
  
  /// Logout
  Future<void> logout() async {
    await _storage.clearAll();
  }
  
  /// Get current user
  Future<User> getCurrentUser() async {
    final response = await _client.get('/users/me');
    return User.fromJson(response.data);
  }
  
  /// Update profile
  Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final response = await _client.put('/users/me', data: {
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });
    return User.fromJson(response.data);
  }
  
  /// Change home town
  Future<User> changeHomeTown(String townId, String? suburbId) async {
    final response = await _client.put('/users/me/town', data: {
      'home_town_id': townId,
      'home_suburb_id': suburbId,
    });
    return User.fromJson(response.data);
  }
  
  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null;
  }
  
  /// Forgot password
  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', data: {'email': email});
  }
  
  /// Request verification email
  Future<void> sendVerificationEmail() async {
    await _client.post('/auth/send-verification');
  }
  
  /// Verify email
  Future<void> verifyEmail(String code) async {
    await _client.post('/auth/verify-email', data: {'code': code});
  }

  /// Get user by ID
  Future<User> getUser(String userId) async {
    final response = await _client.get('/users/$userId');
    return User.fromJson(response.data);
  }
}

/// User profile provider (for viewing other users)
final userProfileProvider = FutureProvider.family<User, String>((ref, userId) async {
  final repository = ref.read(authRepositoryProvider);
  return repository.getUser(userId);
});

