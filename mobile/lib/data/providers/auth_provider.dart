import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/push_notification_service.dart';

// Auth repository and store repository imports for invalidation
import '../repositories/store_repository.dart';
import 'auction_provider.dart';
import '../../core/network/websocket_service.dart';

/// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });
  
  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final StorageService _storage;
  final Ref _ref;
  
  AuthNotifier(this._repository, this._storage, this._ref) : super(const AuthState());
  
  /// Initialize - check if user is logged in
  Future<void> initialize() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final isLoggedIn = await _repository.isLoggedIn();
      if (isLoggedIn) {
        final user = await _repository.getCurrentUser();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
  
  /// Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
      
      // Register FCM token now that user is authenticated
      _ref.read(pushNotificationServiceProvider).registerTokenIfNeeded();
      
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      return false;
    }
  }
  
  /// Register
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String? phone,
    required String homeTownId,
    String? homeSuburbId,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.register(
        email: email,
        username: username,
        password: password,
        fullName: fullName,
        phone: phone,
        homeTownId: homeTownId,
        homeSuburbId: homeSuburbId,
      );
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
      
      // Register FCM token now that user is authenticated
      _ref.read(pushNotificationServiceProvider).registerTokenIfNeeded();
      
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: e.toString());
      return false;
    }
  }
  
  /// Sign in with Google
  /// Returns: 'success' on success, 'new_user' if home town selection needed, 'error' on failure
  Future<String> signInWithGoogle({String? homeTownId, String? homeSuburbId}) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _repository.loginWithGoogle(
        homeTownId: homeTownId,
        homeSuburbId: homeSuburbId,
      );
      state = AuthState(status: AuthStatus.authenticated, user: response.user);
      
      // Register FCM token now that user is authenticated
      _ref.read(pushNotificationServiceProvider).registerTokenIfNeeded();
      
      return 'success';
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('new_user') || errorMsg.contains('Home town is required')) {
        state = state.copyWith(status: AuthStatus.unauthenticated, error: 'new_user');
        return 'new_user';
      }
      if (errorMsg.contains('cancelled')) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return 'cancelled';
      }
      state = AuthState(status: AuthStatus.error, error: errorMsg);
      return 'error';
    }
  }
  
  /// Logout
  Future<void> logout() async {
    print('DEBUG: AuthNotifier.logout started');
    state = state.copyWith(status: AuthStatus.loading);
    try {
      // Disconnect websocket first while we still have the old token access if needed
      print('DEBUG: Disconnecting WebSocket');
      _ref.read(wsServiceProvider).disconnect();
      
      print('DEBUG: Calling repository.logout');
      await _repository.logout();
      
      // Also sign out from Google if signed in
      await _repository.signOutGoogle();
      
      print('DEBUG: Setting state to unauthenticated');
      state = const AuthState(status: AuthStatus.unauthenticated);
      print('DEBUG: AuthNotifier.logout completed');
    } catch (e, stack) {
      print('DEBUG: AuthNotifier.logout FAILED: $e');
      print(stack);
      state = state.copyWith(status: AuthStatus.authenticated, error: e.toString());
      rethrow;
    }
  }


  
  /// Update profile
  Future<bool> updateProfile({String? fullName, String? phone, String? avatarUrl}) async {
    try {
      final user = await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Change home town
  Future<bool> changeHomeTown(String townId, String? suburbId) async {
    try {
      final user = await _repository.changeHomeTown(townId, suburbId);
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    try {
      await _repository.forgotPassword(email);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(storageServiceProvider),
    ref,
  );
});

/// Current user provider (convenience)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});
