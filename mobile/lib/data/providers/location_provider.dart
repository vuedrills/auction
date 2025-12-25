import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../repositories/location_repository.dart';

/// Towns list provider
final townsProvider = FutureProvider<List<Town>>((ref) async {
  final repository = ref.read(townRepositoryProvider);
  return repository.getTowns();
});

/// Single town provider
final townProvider = FutureProvider.family<Town, String>((ref, id) async {
  final repository = ref.read(townRepositoryProvider);
  return repository.getTown(id);
});

/// Suburbs provider
final suburbsProvider = FutureProvider.family<List<Suburb>, String>((ref, townId) async {
  final repository = ref.read(townRepositoryProvider);
  return repository.getSuburbs(townId);
});

/// Town search provider
class TownSearchNotifier extends StateNotifier<List<Town>> {
  final TownRepository _repository;
  
  TownSearchNotifier(this._repository) : super([]);
  
  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = [];
      return;
    }
    try {
      state = await _repository.searchTowns(query);
    } catch (e) {
      state = [];
    }
  }
  
  void clear() {
    state = [];
  }
}

final townSearchProvider = StateNotifierProvider<TownSearchNotifier, List<Town>>((ref) {
  return TownSearchNotifier(ref.read(townRepositoryProvider));
});

/// Categories list provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.read(categoryRepositoryProvider);
  return repository.getCategories();
});

/// Single category provider
final categoryProvider = FutureProvider.family<Category, String>((ref, id) async {
  final repository = ref.read(categoryRepositoryProvider);
  return repository.getCategory(id);
});

/// Category slots provider
final categorySlotProvider = FutureProvider.family<CategorySlots, ({String categoryId, String townId})>((ref, params) async {
  final repository = ref.read(categoryRepositoryProvider);
  return repository.getSlotAvailability(params.categoryId, params.townId);
});

/// Waiting list provider
final waitingListProvider = FutureProvider<List<WaitingListPosition>>((ref) async {
  final repository = ref.read(categoryRepositoryProvider);
  return repository.getMyWaitingList();
});

/// Join waiting list
class WaitingListNotifier extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repository;
  
  WaitingListNotifier(this._repository) : super(const AsyncValue.data(null));
  
  Future<bool> join(String categoryId, String townId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.joinWaitingList(categoryId, townId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
  
  Future<bool> leave(String categoryId, String townId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.leaveWaitingList(categoryId, townId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final waitingListActionsProvider = StateNotifierProvider<WaitingListNotifier, AsyncValue<void>>((ref) {
  return WaitingListNotifier(ref.read(categoryRepositoryProvider));
});

/// Selected town provider (for filtering)
final selectedTownProvider = StateProvider<Town?>((ref) => null);

/// Selected suburb provider (for filtering)
final selectedSuburbProvider = StateProvider<Suburb?>((ref) => null);

/// Selected category provider (for filtering)
final selectedCategoryProvider = StateProvider<Category?>((ref) => null);
