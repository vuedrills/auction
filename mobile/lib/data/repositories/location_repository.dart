import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../../core/network/dio_client.dart';

/// Town repository provider
final townRepositoryProvider = Provider<TownRepository>((ref) {
  return TownRepository(ref.read(dioClientProvider));
});

/// Category repository provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.read(dioClientProvider));
});

/// Town/Location repository
class TownRepository {
  final DioClient _client;
  
  TownRepository(this._client);
  
  /// Get all towns
  Future<List<Town>> getTowns() async {
    final response = await _client.get('/towns');
    return (response.data['towns'] as List?)
        ?.map((t) => Town.fromJson(t as Map<String, dynamic>))
        .toList() ?? [];
  }
  
  /// Get town by ID with suburbs
  Future<Town> getTown(String id) async {
    final response = await _client.get('/towns/$id');
    return Town.fromJson(response.data);
  }
  
  /// Get suburbs for a town
  Future<List<Suburb>> getSuburbs(String townId) async {
    final response = await _client.get('/towns/$townId/suburbs');
    return (response.data['suburbs'] as List?)
        ?.map((s) => Suburb.fromJson(s as Map<String, dynamic>))
        .toList() ?? [];
  }
  
  /// Search towns
  Future<List<Town>> searchTowns(String query) async {
    final response = await _client.get('/towns', queryParameters: {'q': query});
    return (response.data['towns'] as List?)
        ?.map((t) => Town.fromJson(t as Map<String, dynamic>))
        .toList() ?? [];
  }
}

/// Category repository
class CategoryRepository {
  final DioClient _client;
  
  CategoryRepository(this._client);
  
  /// Get all categories
  Future<List<Category>> getCategories() async {
    final response = await _client.get('/categories');
    return (response.data['categories'] as List?)
        ?.map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList() ?? [];
  }
  
  /// Get category by ID
  Future<Category> getCategory(String id) async {
    final response = await _client.get('/categories/$id');
    return Category.fromJson(response.data);
  }
  
  /// Get slot availability for category in town
  Future<CategorySlots> getSlotAvailability(String categoryId, String townId) async {
    final response = await _client.get('/categories/$categoryId/slots/$townId');
    return CategorySlots.fromJson(response.data);
  }
  
  /// Join waiting list for category
  Future<void> joinWaitingList(String categoryId, String townId) async {
    await _client.post('/categories/$categoryId/waiting-list', data: {
      'town_id': townId,
    });
  }
  
  /// Leave waiting list
  Future<void> leaveWaitingList(String categoryId, String townId) async {
    await _client.delete('/categories/$categoryId/waiting-list/$townId');
  }
  
  /// Get user's waiting list positions
  Future<List<WaitingListPosition>> getMyWaitingList() async {
    final response = await _client.get('/users/me/waiting-list');
    return (response.data['positions'] as List?)
        ?.map((p) => WaitingListPosition.fromJson(p as Map<String, dynamic>))
        .toList() ?? [];
  }
}

/// Category slots info
class CategorySlots {
  final String categoryId;
  final String townId;
  final int maxSlots;
  final int usedSlots;
  final int availableSlots;
  final bool isFull;
  final int waitingCount;
  final int? userPosition;
  
  CategorySlots({
    required this.categoryId,
    required this.townId,
    required this.maxSlots,
    required this.usedSlots,
    required this.availableSlots,
    required this.isFull,
    required this.waitingCount,
    this.userPosition,
  });
  
  factory CategorySlots.fromJson(Map<String, dynamic> json) {
    return CategorySlots(
      categoryId: json['category_id'] as String,
      townId: json['town_id'] as String,
      maxSlots: json['max_slots'] as int? ?? 10,
      usedSlots: json['used_slots'] as int? ?? 0,
      availableSlots: json['available_slots'] as int? ?? 10,
      isFull: json['is_full'] as bool? ?? false,
      waitingCount: json['waiting_count'] as int? ?? 0,
      userPosition: json['user_position'] as int?,
    );
  }
}

/// Waiting list position
class WaitingListPosition {
  final String id;
  final String categoryId;
  final String categoryName;
  final String townId;
  final String townName;
  final int position;
  final DateTime joinedAt;
  
  WaitingListPosition({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.townId,
    required this.townName,
    required this.position,
    required this.joinedAt,
  });
  
  factory WaitingListPosition.fromJson(Map<String, dynamic> json) {
    return WaitingListPosition(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String? ?? '',
      townId: json['town_id'] as String,
      townName: json['town_name'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}
