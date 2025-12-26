import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../core/network/dio_client.dart';
import '../../data/data.dart';

/// ID Verification Screen
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  String? _idDocumentUrl;
  String? _selfieUrl;
  bool _isUploadingId = false;
  bool _isUploadingSelfie = false;
  bool _isSubmitting = false;
  int _currentStep = 0;

  Future<void> _uploadIdDocument(ImageSource source) async {
    setState(() => _isUploadingId = true);
    try {
      final storageService = ref.read(supabaseStorageProvider);
      final url = await storageService.pickAndUploadImage(
        folder: 'verification/id_documents',
        source: source,
      );
      if (url != null) {
        setState(() {
          _idDocumentUrl = url;
          _currentStep = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingId = false);
    }
  }

  Future<void> _uploadSelfie(ImageSource source) async {
    setState(() => _isUploadingSelfie = true);
    try {
      final storageService = ref.read(supabaseStorageProvider);
      final url = await storageService.pickAndUploadImage(
        folder: 'verification/selfies',
        source: source,
      );
      if (url != null) {
        setState(() {
          _selfieUrl = url;
          _currentStep = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingSelfie = false);
    }
  }

  void _showSelfieSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Take a Selfie', style: AppTypography.titleLarge),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: Text('Take Photo', style: AppTypography.titleSmall),
                subtitle: Text('Use camera for selfie', style: AppTypography.bodySmall),
                onTap: () {
                  Navigator.pop(context);
                  _uploadSelfie(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: Text('Choose from Gallery', style: AppTypography.titleSmall),
                subtitle: Text('Select existing photo', style: AppTypography.bodySmall),
                onTap: () {
                  Navigator.pop(context);
                  _uploadSelfie(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitVerification() async {
    if (_idDocumentUrl == null || _selfieUrl == null) return;
    
    setState(() => _isSubmitting = true);
    try {
      final client = ref.read(dioClientProvider);
      await client.post('/users/me/verification', data: {
        'id_document_url': _idDocumentUrl,
        'selfie_url': _selfieUrl,
      });
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                ),
                const SizedBox(height: 16),
                Text('Verification Submitted!', style: AppTypography.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'We\'ll review your documents and notify you within 24-48 hours.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: Text('OK', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showImageSourceDialog(Function(ImageSource) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Upload ID Document', style: AppTypography.titleLarge),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: Text('Take Photo', style: AppTypography.titleSmall),
                subtitle: Text('Capture your ID with camera', style: AppTypography.bodySmall),
                onTap: () {
                  Navigator.pop(context);
                  onSelected(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: Text('Choose from Gallery', style: AppTypography.titleSmall),
                subtitle: Text('Select existing photo', style: AppTypography.bodySmall),
                onTap: () {
                  Navigator.pop(context);
                  onSelected(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Verify Your Identity', style: AppTypography.titleLarge),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'ID', Icons.badge),
                Expanded(child: Container(height: 2, color: _currentStep >= 1 ? AppColors.primary : Colors.grey.shade300)),
                _buildStepIndicator(1, 'Selfie', Icons.face),
                Expanded(child: Container(height: 2, color: _currentStep >= 2 ? AppColors.primary : Colors.grey.shade300)),
                _buildStepIndicator(2, 'Review', Icons.check_circle),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: ID Document
                  _buildSectionCard(
                    title: '1. Upload National ID',
                    subtitle: 'Take a clear photo of your national ID card or passport',
                    icon: Icons.badge,
                    isActive: _currentStep == 0,
                    isCompleted: _idDocumentUrl != null,
                    child: _idDocumentUrl != null
                        ? _buildImagePreview(_idDocumentUrl!, () => setState(() {
                            _idDocumentUrl = null;
                            _currentStep = 0;
                          }))
                        : _buildUploadButton(
                            isLoading: _isUploadingId,
                            onTap: () => _showImageSourceDialog(_uploadIdDocument),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Step 2: Selfie
                  _buildSectionCard(
                    title: '2. Take a Selfie',
                    subtitle: 'We\'ll match this with your ID photo',
                    icon: Icons.face,
                    isActive: _currentStep == 1,
                    isCompleted: _selfieUrl != null,
                    isLocked: _idDocumentUrl == null,
                    child: _selfieUrl != null
                        ? _buildImagePreview(_selfieUrl!, () => setState(() {
                            _selfieUrl = null;
                            _currentStep = 1;
                          }))
                        : _buildUploadButton(
                            isLoading: _isUploadingSelfie,
                            onTap: _idDocumentUrl != null ? _showSelfieSourceDialog : null,
                            label: 'Upload Selfie',
                            icon: Icons.face,
                          ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Terms
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your documents are encrypted and stored securely. We only use them to verify your identity.',
                            style: AppTypography.bodySmall.copyWith(color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Submit button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_idDocumentUrl != null && _selfieUrl != null && !_isSubmitting)
                      ? _submitVerification
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Submit for Verification', style: AppTypography.labelLarge),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.labelSmall.copyWith(
          color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
        )),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    bool isActive = false,
    bool isCompleted = false,
    bool isLocked = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.success
              : isActive
                  ? AppColors.primary
                  : Colors.grey.shade200,
          width: isActive || isCompleted ? 2 : 1,
        ),
      ),
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle : icon,
                      color: isCompleted ? AppColors.success : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.titleSmall),
                        Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton({
    required bool isLoading,
    VoidCallback? onTap,
    String label = 'Upload Photo',
    IconData icon = Icons.upload_file,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 40, color: onTap != null ? AppColors.primary : Colors.grey),
                    const SizedBox(height: 8),
                    Text(label, style: AppTypography.labelMedium.copyWith(
                      color: onTap != null ? AppColors.primary : Colors.grey,
                    )),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String url, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: url,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 150,
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 18, color: AppColors.error),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text('Uploaded', style: AppTypography.labelSmall.copyWith(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
