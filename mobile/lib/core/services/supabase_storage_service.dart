import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import 'image_compression_service.dart';

/// Supabase storage service provider
final supabaseStorageProvider = Provider<SupabaseStorageService>((ref) {
  final compressionService = ref.watch(imageCompressionProvider);
  return SupabaseStorageService(compressionService: compressionService);
});

/// Upload progress callback
typedef UploadProgressCallback = void Function(int current, int total, double progress);

/// Result of an upload operation
class UploadResult {
  final String url;
  final int originalSizeBytes;
  final int uploadedSizeBytes;
  final Duration uploadDuration;

  const UploadResult({
    required this.url,
    required this.originalSizeBytes,
    required this.uploadedSizeBytes,
    required this.uploadDuration,
  });

  double get compressionRatio => uploadedSizeBytes / originalSizeBytes;
  int get savedBytes => originalSizeBytes - uploadedSizeBytes;
  double get savingsPercent => (1 - compressionRatio) * 100;
}

/// Service for uploading and managing images in Supabase Storage
/// Now includes automatic image compression for optimal upload sizes
class SupabaseStorageService {
  final Dio _dio = Dio();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final ImageCompressionService _compressionService;

  SupabaseStorageService({required ImageCompressionService compressionService})
      : _compressionService = compressionService;

  /// Pick and upload a single image with automatic compression
  Future<String?> pickAndUploadImage({
    required String folder,
    ImageSource source = ImageSource.gallery,
    ImageCompressionConfig compressionConfig = ImageCompressionConfig.auction,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null;

      return await uploadFile(
        File(image.path),
        folder,
        compressionConfig: compressionConfig,
      );
    } catch (e) {
      print('Error picking/uploading image: $e');
      return null;
    }
  }

  /// Pick multiple images and upload them with compression
  Future<List<String>> pickAndUploadMultipleImages({
    required String folder,
    int maxImages = 10,
    ImageCompressionConfig compressionConfig = ImageCompressionConfig.auction,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty) return [];

      final limitedImages = images.take(maxImages).toList();
      return await uploadMultipleFiles(
        limitedImages.map((x) => File(x.path)).toList(),
        folder,
        compressionConfig: compressionConfig,
        onProgress: onProgress,
      );
    } catch (e) {
      print('Error picking/uploading images: $e');
      return [];
    }
  }

  /// Upload a file to Supabase Storage with automatic compression
  Future<String?> uploadFile(
    File file,
    String folder, {
    ImageCompressionConfig compressionConfig = ImageCompressionConfig.auction,
    bool compress = true,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      final originalSize = await file.length();

      // Validate image
      final validationError = _compressionService.validateImage(file);
      if (validationError != null) {
        print('❌ Validation failed: $validationError');
        return null;
      }

      File fileToUpload = file;

      // Compress if enabled and image is large enough to benefit
      if (compress && originalSize > 100 * 1024) {
        // Only compress if > 100KB
        print('📷 Compressing image (original: ${_formatBytes(originalSize)})...');

        final result =
            await _compressionService.compressImage(file, config: compressionConfig);
        if (result != null) {
          fileToUpload = result.file;
          print(
              '✅ Compressed: ${_formatBytes(result.originalSizeBytes)} → ${_formatBytes(result.compressedSizeBytes)} (saved ${result.savingsPercent.toStringAsFixed(1)}%)');
        }
      }

      final bytes = await fileToUpload.readAsBytes();
      final ext = 'jpg'; // Always use jpg for consistency after compression
      final filename = '${_uuid.v4()}.$ext';
      final path = '$folder/$filename';

      final contentType = 'image/jpeg';

      print(
          '📤 Uploading ${_formatBytes(bytes.length)} to ${SupabaseConfig.bucket}/$path');

      final response = await _dio.post(
        '${SupabaseConfig.storageUrl}/object/${SupabaseConfig.bucket}/$path',
        data: Stream.fromIterable([bytes]),
        options: Options(
          validateStatus: (status) => true,
          headers: {
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
            'apikey': SupabaseConfig.anonKey,
            'Content-Type': contentType,
            'Content-Length': bytes.length.toString(),
            'x-upsert': 'true',
          },
        ),
      );

      stopwatch.stop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final url = SupabaseConfig.getPublicUrl(path);
        print(
            '✅ Upload successful in ${stopwatch.elapsedMilliseconds}ms: $url');
        return url;
      }

      print('❌ Upload failed: ${response.statusCode} - ${response.data}');
      return null;
    } catch (e) {
      print('❌ Error in uploadFile: $e');
      return null;
    }
  }

  /// Upload multiple files with compression and progress tracking
  Future<List<String>> uploadMultipleFiles(
    List<File> files,
    String folder, {
    ImageCompressionConfig compressionConfig = ImageCompressionConfig.auction,
    UploadProgressCallback? onProgress,
  }) async {
    final urls = <String>[];
    int totalOriginalSize = 0;
    int totalUploadedSize = 0;

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final originalSize = await file.length();
      totalOriginalSize += originalSize;

      onProgress?.call(i, files.length, i / files.length);

      final url = await uploadFile(
        file,
        folder,
        compressionConfig: compressionConfig,
      );

      if (url != null) {
        urls.add(url);
        // Estimate uploaded size based on compression config
        totalUploadedSize +=
            (originalSize * 0.15).round(); // Rough estimate: 15% of original
      }

      onProgress?.call(i + 1, files.length, (i + 1) / files.length);
    }

    if (urls.isNotEmpty) {
      print(
          '📊 Total upload stats: ${_formatBytes(totalOriginalSize)} → ~${_formatBytes(totalUploadedSize)} '
          '(estimated ${((1 - totalUploadedSize / totalOriginalSize) * 100).toStringAsFixed(1)}% saved)');
    }

    return urls;
  }

  /// Upload bytes directly (no compression)
  Future<String?> uploadBytes(
      Uint8List bytes, String filename, String folder) async {
    try {
      final ext = filename.split('.').last.toLowerCase();
      final path = '$folder/${_uuid.v4()}.$ext';
      final contentType = _getContentType(ext);

      final response = await _dio.post(
        '${SupabaseConfig.storageUrl}/object/${SupabaseConfig.bucket}/$path',
        data: bytes,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
            'Content-Type': contentType,
            'x-upsert': 'true',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SupabaseConfig.getPublicUrl(path);
      }

      return null;
    } catch (e) {
      print('Error uploading bytes: $e');
      return null;
    }
  }

  /// Delete a file from storage
  Future<bool> deleteFile(String path) async {
    try {
      final response = await _dio.delete(
        '${SupabaseConfig.storageUrl}/object/${SupabaseConfig.bucket}/$path',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Get content type from file extension
  String _getContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
