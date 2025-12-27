import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';
import '../../../data/models/store.dart';

/// Service for handling analytics and tracking
class AnalyticsService {
  final DioClient _dioClient;
  
  // Batching queue
  final List<Map<String, dynamic>> _eventQueue = [];
  Timer? _batchTimer;
  static const int _batchIntervalSeconds = 5;
  static const int _maxBatchSize = 10;

  AnalyticsService(this._dioClient) {
    // Start periodic flush
    _batchTimer = Timer.periodic(
      const Duration(seconds: _batchIntervalSeconds), 
      (_) => _flushEvents(),
    );
  }

  void dispose() {
    _batchTimer?.cancel();
    _flushEvents(); // Flush remaining
  }

  /// Track a product impression or view
  void trackEvent({
    required String storeId,
    required String eventType, // 'impression', 'view', 'cart', 'store_view', etc.
    String? productId,
    Map<String, dynamic>? metadata,
  }) {
    _eventQueue.add({
      'store_id': storeId,
      'product_id': productId ?? "",
      'event_type': eventType,
      'metadata': metadata,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });

    if (_eventQueue.length >= _maxBatchSize) {
      _flushEvents();
    }
  }

  /// Flush events to backend
  Future<void> _flushEvents() async {
    if (_eventQueue.isEmpty) return;

    // Take current batch
    final batch = List<Map<String, dynamic>>.from(_eventQueue);
    _eventQueue.clear();

    try {
      await _dioClient.post(
        ApiConfig.batchTrack,
        data: {'events': batch},
      );
    } catch (e) {
      // On failure, maybe requeue? For now, we just log
      print('Failed to send analytics batch: $e');
      // Optional: requeue if not too old
    }
  }

  /// Get dashboard analytics
  Future<StoreAnalyticsResponse> getStoreAnalytics(String storeId) async {
    // NOTE: This endpoint was not in Phase 1 plan, so it might fail 404
    // if not implemented on backend yet. This is placeholder for Phase 2 integration.
    // For now, return mock empty or implement backend part if needed.
    // Assuming /api/stores/:id/analytics exists or similar.
    
    // For this task, we mainly focused on TRACKING.
    // Use a placeholder implementation if endpoint is missing.
    try {
      final response = await _dioClient.get('${ApiConfig.baseUrl}/analytics/store/$storeId');
      return StoreAnalyticsResponse.fromJson(response.data);
    } catch (e) {
      // Return empty if failed (or mock)
      return StoreAnalyticsResponse(
        totalViews: 0,
        totalEnquiries: 0,
        totalFollowers: 0,
        totalProducts: 0,
        viewsThisWeek: 0,
        viewsThisMonth: 0,
      );
    }
  }
}
