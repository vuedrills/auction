import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';

/// Supabase storage service provider
final supabaseStorageProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService();
});

/// Service for uploading and managing images in Supabase Storage
class SupabaseStorageService {
  final Dio _dio = Dio();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Pick and upload a single image
  Future<String?> pickAndUploadImage({
    required String folder,
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
      
      if (image == null) return null;
      
      return await uploadFile(File(image.path), folder);
    } catch (e) {
      print('Error picking/uploading image: $e');
      return null;
    }
  }

  /// Pick multiple images and upload them
  Future<List<String>> pickAndUploadMultipleImages({
    required String folder,
    int maxImages = 10,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 85,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
      
      if (images.isEmpty) return [];
      
      final limitedImages = images.take(maxImages).toList();
      final List<String> urls = [];
      
      for (final image in limitedImages) {
        final url = await uploadFile(File(image.path), folder);
        if (url != null) urls.add(url);
      }
      
      return urls;
    } catch (e) {
      print('Error picking/uploading images: $e');
      return [];
    }
  }

  /// Upload a file to Supabase Storage
  Future<String?> uploadFile(File file, String folder) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final filename = '${_uuid.v4()}.$ext';
      final path = '$folder/$filename';
      
      final contentType = _getContentType(ext);
      
      final response = await _dio.post(
        '${SupabaseConfig.storageUrl}/object/${SupabaseConfig.bucket}/$path',
        data: bytes,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
            'apikey': SupabaseConfig.anonKey,
            'Content-Type': contentType,
            'x-upsert': 'true',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SupabaseConfig.getPublicUrl(path);
      }
      
      print('Upload failed with status: ${response.statusCode}, body: ${response.data}');
      return null;
    } catch (e) {
      if (e is DioException) {
        print('DioError uploading file: ${e.message}, response: ${e.response?.data}');
      } else {
        print('Error uploading file: $e');
      }
      return null;
    }
  }

  /// Upload bytes directly
  Future<String?> uploadBytes(Uint8List bytes, String filename, String folder) async {
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
}
