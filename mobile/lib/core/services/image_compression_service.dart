import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

/// Image compression service provider
final imageCompressionProvider = Provider<ImageCompressionService>((ref) {
  return ImageCompressionService();
});

/// Configuration for image compression
class ImageCompressionConfig {
  /// Maximum width in pixels (maintains aspect ratio)
  final int maxWidth;
  
  /// Maximum height in pixels (maintains aspect ratio)
  final int maxHeight;
  
  /// JPEG quality (0-100, higher = better quality but larger file)
  final int quality;
  
  /// Target file size in bytes (will keep compressing until achieved)
  final int? targetSizeBytes;
  
  /// Output format
  final CompressFormat format;

  const ImageCompressionConfig({
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.quality = 80,
    this.targetSizeBytes,
    this.format = CompressFormat.jpeg,
  });

  /// Default config for auction images (optimized for mobile viewing)
  static const auction = ImageCompressionConfig(
    maxWidth: 1920,
    maxHeight: 1920,
    quality: 80,
    targetSizeBytes: 500 * 1024, // 500KB max
  );

  /// Thumbnail config (for list views and previews)
  static const thumbnail = ImageCompressionConfig(
    maxWidth: 400,
    maxHeight: 400,
    quality: 70,
    targetSizeBytes: 50 * 1024, // 50KB max
  );

  /// High quality config (for detail views)
  static const highQuality = ImageCompressionConfig(
    maxWidth: 2048,
    maxHeight: 2048,
    quality: 90,
    targetSizeBytes: 1024 * 1024, // 1MB max
  );
}

/// Result of image compression
class CompressionResult {
  /// The compressed file
  final File file;
  
  /// Original file size in bytes
  final int originalSizeBytes;
  
  /// Compressed file size in bytes
  final int compressedSizeBytes;
  
  /// Compression ratio (e.g., 0.1 means compressed to 10% of original)
  double get compressionRatio => compressedSizeBytes / originalSizeBytes;
  
  /// Savings in bytes
  int get savedBytes => originalSizeBytes - compressedSizeBytes;
  
  /// Savings percentage
  double get savingsPercent => (1 - compressionRatio) * 100;

  const CompressionResult({
    required this.file,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
  });

  @override
  String toString() {
    return 'CompressionResult('
        'original: ${_formatBytes(originalSizeBytes)}, '
        'compressed: ${_formatBytes(compressedSizeBytes)}, '
        'saved: ${savingsPercent.toStringAsFixed(1)}%)';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Service for compressing images before upload
class ImageCompressionService {
  /// Compress a single image file
  /// 
  /// Returns a [CompressionResult] with the compressed file and stats
  Future<CompressionResult?> compressImage(
    File file, {
    ImageCompressionConfig config = ImageCompressionConfig.auction,
  }) async {
    try {
      final originalBytes = await file.length();
      
      // Skip if already small enough
      if (config.targetSizeBytes != null && originalBytes <= config.targetSizeBytes!) {
        print('📷 Image already small enough (${_formatBytes(originalBytes)}), skipping compression');
        return CompressionResult(
          file: file,
          originalSizeBytes: originalBytes,
          compressedSizeBytes: originalBytes,
        );
      }

      // Get temp directory for output
      final tempDir = await path_provider.getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}',
      );
      
      // Replace extension with jpg for consistent output
      final outputPath = targetPath.replaceAll(RegExp(r'\.[^.]+$'), '.jpg');

      // First compression pass
      XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outputPath,
        minWidth: config.maxWidth,
        minHeight: config.maxHeight,
        quality: config.quality,
        format: config.format,
        keepExif: false, // Remove EXIF data to reduce size & protect privacy
      );

      if (result == null) {
        print('⚠️ Image compression failed for ${file.path}');
        return null;
      }

      // If target size specified, keep compressing until achieved
      if (config.targetSizeBytes != null) {
        var currentQuality = config.quality;
        var attempts = 0;
        const maxAttempts = 5;
        
        while (await result!.length() > config.targetSizeBytes! && 
               currentQuality > 20 && 
               attempts < maxAttempts) {
          attempts++;
          currentQuality = (currentQuality * 0.7).round(); // Reduce quality by 30%
          
          final recompressPath = outputPath.replaceAll('.jpg', '_q$currentQuality.jpg');
          result = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            recompressPath,
            minWidth: config.maxWidth,
            minHeight: config.maxHeight,
            quality: currentQuality,
            format: config.format,
            keepExif: false,
          );
          
          if (result == null) break;
          
          print('📷 Recompression attempt $attempts: quality=$currentQuality, size=${_formatBytes(await result.length())}');
        }
      }

      if (result == null) {
        return null;
      }

      final compressedBytes = await result.length();
      final compressedFile = File(result.path);

      final compressionResult = CompressionResult(
        file: compressedFile,
        originalSizeBytes: originalBytes,
        compressedSizeBytes: compressedBytes,
      );

      print('📷 Compression complete: $compressionResult');
      return compressionResult;
    } catch (e) {
      print('❌ Error compressing image: $e');
      return null;
    }
  }

  /// Compress multiple images
  /// 
  /// Returns a list of compression results. Failed compressions are excluded.
  Future<List<CompressionResult>> compressImages(
    List<File> files, {
    ImageCompressionConfig config = ImageCompressionConfig.auction,
    void Function(int current, int total, CompressionResult? result)? onProgress,
  }) async {
    final results = <CompressionResult>[];
    
    for (var i = 0; i < files.length; i++) {
      final result = await compressImage(files[i], config: config);
      if (result != null) {
        results.add(result);
      }
      onProgress?.call(i + 1, files.length, result);
    }
    
    return results;
  }

  /// Compress image from bytes
  Future<Uint8List?> compressBytes(
    Uint8List bytes, {
    ImageCompressionConfig config = ImageCompressionConfig.auction,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: config.maxWidth,
        minHeight: config.maxHeight,
        quality: config.quality,
        format: config.format,
        keepExif: false,
      );
      
      print('📷 Bytes compression: ${_formatBytes(bytes.length)} → ${_formatBytes(result.length)}');
      return result;
    } catch (e) {
      print('❌ Error compressing bytes: $e');
      return null;
    }
  }

  /// Validate image before upload
  /// 
  /// Returns error message if invalid, null if valid
  String? validateImage(File file, {int maxSizeBytes = 10 * 1024 * 1024}) {
    if (!file.existsSync()) {
      return 'Image file does not exist';
    }
    
    final size = file.lengthSync();
    if (size > maxSizeBytes) {
      return 'Image too large (${_formatBytes(size)}). Maximum size is ${_formatBytes(maxSizeBytes)}';
    }
    
    final ext = path.extension(file.path).toLowerCase();
    const validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif'];
    if (!validExtensions.contains(ext)) {
      return 'Invalid image format. Supported: JPG, PNG, GIF, WebP, HEIC';
    }
    
    return null;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
