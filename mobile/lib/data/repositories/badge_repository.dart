import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge.dart';
import '../../core/network/dio_client.dart';

/// Badge repository provider
final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository(ref.read(dioClientProvider));
});

/// Badge repository
class BadgeRepository {
  final DioClient _client;
  
  BadgeRepository(this._client);
  
  /// Get all available badges
  Future<List<Badge>> getAllBadges() async {
    final response = await _client.get('/badges');
    final List<dynamic> data = response.data['badges'] ?? [];
    return data.map((json) => Badge.fromJson(json)).toList();
  }
  
  /// Get badges for a specific user
  Future<List<UserBadge>> getUserBadges(String userId) async {
    final response = await _client.get('/users/$userId/badges');
    final List<dynamic> data = response.data['badges'] ?? [];
    return data.map((json) => UserBadge.fromJson(json)).toList();
  }
  
  /// Get current user's badges
  Future<List<UserBadge>> getMyBadges() async {
    final response = await _client.get('/users/me/badges');
    final List<dynamic> data = response.data['badges'] ?? [];
    return data.map((json) => UserBadge.fromJson(json)).toList();
  }
  
  /// Get verification status
  Future<VerificationStatus> getVerificationStatus() async {
    final response = await _client.get('/users/me/verification-status');
    return VerificationStatus.fromJson(response.data);
  }
  
  /// Submit verification request
  Future<void> submitVerification({
    required String idDocumentUrl,
    required String selfieUrl,
  }) async {
    await _client.post('/users/me/verification', data: {
      'id_document_url': idDocumentUrl,
      'selfie_url': selfieUrl,
    });
  }
}

/// Badge providers
final allBadgesProvider = FutureProvider<List<Badge>>((ref) async {
  final repository = ref.read(badgeRepositoryProvider);
  return repository.getAllBadges();
});

final userBadgesProvider = FutureProvider.family<List<UserBadge>, String>((ref, userId) async {
  final repository = ref.read(badgeRepositoryProvider);
  return repository.getUserBadges(userId);
});

final myBadgesProvider = FutureProvider<List<UserBadge>>((ref) async {
  final repository = ref.read(badgeRepositoryProvider);
  return repository.getMyBadges();
});

final verificationStatusProvider = FutureProvider<VerificationStatus>((ref) async {
  final repository = ref.read(badgeRepositoryProvider);
  return repository.getVerificationStatus();
});
