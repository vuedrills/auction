import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/analytics_service.dart';
import '../models/store.dart';

/// Analytics service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AnalyticsService(dioClient);
});

/// Get store analytics provider
final storeAnalyticsProvider = FutureProvider.family<StoreAnalyticsResponse, String>((ref, storeId) async {
  final service = ref.watch(analyticsServiceProvider);
  return service.getStoreAnalytics(storeId);
});
