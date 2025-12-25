import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/app_button.dart';

/// Create Auction Screen - Connected to Backend
class CreateAuctionScreen extends ConsumerStatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  ConsumerState<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  int _currentStep = 0;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _reservePriceController = TextEditingController();
  final _bidIncrementController = TextEditingController(text: '5.00');
  final _pickupLocationController = TextEditingController();
  
  Category? _selectedCategory;
  String _selectedCondition = 'good';
  bool _shippingAvailable = false;
  bool _allowOffers = false;
  
  final List<File> _localImages = [];
  final List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  bool _isPublishing = false;

  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startingPriceController.dispose();
    _reservePriceController.dispose();
    _bidIncrementController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(limit: 10 - _localImages.length);
    if (images.isNotEmpty) {
      setState(() {
        _localImages.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _takePhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _localImages.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _localImages.removeAt(index);
      if (index < _uploadedImageUrls.length) {
        _uploadedImageUrls.removeAt(index);
      }
    });
  }

  Future<void> _uploadImages() async {
    if (_localImages.isEmpty) return;
    
    setState(() => _isUploading = true);
    
    try {
      final storageService = ref.read(supabaseStorageProvider);
      _uploadedImageUrls.clear();
      
      int successCount = 0;
      for (final image in _localImages) {
        final url = await storageService.uploadFile(image, 'auctions');
        if (url != null) {
          _uploadedImageUrls.add(url);
          successCount++;
        }
      }
      
      if (successCount == 0 && _localImages.isNotEmpty) {
        throw Exception('Could not upload any images. Please check your internet connection or storage configuration.');
      }
      
      if (successCount < _localImages.length) {
        throw Exception('Only $successCount of ${_localImages.length} images were uploaded. Please try again.');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount photos uploaded'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload Error: $e'), backgroundColor: AppColors.error),
        );
      }
      rethrow; // Re-throw to prevent publishing
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _publishAuction() async {
    // Validate
    if (_localImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo'), backgroundColor: AppColors.warning),
      );
      setState(() => _currentStep = 0);
      return;
    }
    
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), backgroundColor: AppColors.warning),
      );
      setState(() => _currentStep = 1);
      return;
    }
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category'), backgroundColor: AppColors.warning),
      );
      setState(() => _currentStep = 1);
      return;
    }
    
    final startingPrice = double.tryParse(_startingPriceController.text);
    if (startingPrice == null || startingPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid starting price'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isPublishing = true);
    
    try {
      // Upload images if not already done
      if (_uploadedImageUrls.length != _localImages.length) {
        await _uploadImages();
      }
      
      if (_uploadedImageUrls.isEmpty) {
        throw Exception('Failed to upload images');
      }
      
      final user = ref.read(currentUserProvider);
      if (user?.homeTownId == null) {
        throw Exception('Please set your home town first');
      }
      
      // Create auction
      final repository = ref.read(auctionRepositoryProvider);
      final auction = await repository.createAuction(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        startingPrice: startingPrice,
        reservePrice: double.tryParse(_reservePriceController.text),
        bidIncrement: double.tryParse(_bidIncrementController.text) ?? 5.0,
        categoryId: _selectedCategory!.id,
        townId: user!.homeTownId!,
        suburbId: user.homeSuburbId,
        condition: _selectedCondition,
        images: _uploadedImageUrls,
        pickupLocation: _pickupLocationController.text.trim().isNotEmpty 
            ? _pickupLocationController.text.trim() 
            : null,
        shippingAvailable: _shippingAvailable,
        allowOffers: _allowOffers,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auction published successfully!'), backgroundColor: AppColors.success),
        );
        // Navigate to the created auction
        context.go('/auction/${auction.id}');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('error')) {
          errorMessage = data['error'];
        } else if (e.response?.statusMessage != null) {
          errorMessage = 'Server Error: ${e.response?.statusCode} ${e.response?.statusMessage}';
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $errorMessage'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _localImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo'), backgroundColor: AppColors.warning),
      );
      return;
    }
    
    if (_currentStep == 1) {
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title'), backgroundColor: AppColors.warning),
        );
        return;
      }
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category'), backgroundColor: AppColors.warning),
        );
        return;
      }
    }
    
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _publishAuction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
        title: Text('Create Auction', style: AppTypography.titleLarge),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : () => _saveDraft(),
            child: Text('Save Draft', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: i <= _currentStep ? AppColors.primary : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),
          // Step labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepLabel(index: 0, label: 'Photos', isActive: _currentStep == 0, isCompleted: _currentStep > 0),
                _StepLabel(index: 1, label: 'Details', isActive: _currentStep == 1, isCompleted: _currentStep > 1),
                _StepLabel(index: 2, label: 'Pricing', isActive: _currentStep == 2, isCompleted: false),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(categoriesAsync, user),
            ),
          ),
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildStepContent(AsyncValue<List<Category>> categoriesAsync, User? user) {
    switch (_currentStep) {
      case 0: return _buildPhotoStep();
      case 1: return _buildDetailsStep(categoriesAsync);
      case 2: return _buildPricingStep(user);
      default: return const SizedBox();
    }
  }

  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Photos', style: AppTypography.headlineMedium),
        const SizedBox(height: 8),
        Text('Add up to 10 photos. First photo is the cover.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
        const SizedBox(height: 24),
        
        // Photo grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: (_localImages.length < 10) ? _localImages.length + 1 : _localImages.length,
          itemBuilder: (_, i) {
            if (i == _localImages.length && _localImages.length < 10) {
              return _AddPhotoCard(onTap: _showPhotoOptions);
            }
            return _PhotoCard(
              file: _localImages[i],
              isCover: i == 0,
              onRemove: () => _removeImage(i),
            );
          },
        ),
        
        if (_localImages.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_localImages.length} photo${_localImages.length > 1 ? 's' : ''} selected. Drag to reorder.',
                  style: AppTypography.bodySmall,
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsStep(AsyncValue<List<Category>> categoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Item Details', style: AppTypography.headlineMedium),
        const SizedBox(height: 24),
        
        AppTextField(
          controller: _titleController,
          label: 'Title *',
          hintText: 'What are you selling?',
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _descriptionController,
          label: 'Description',
          hintText: 'Describe your item, including brand, size, condition details...',
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        
        // Category selection
        Text('Category *', style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading categories: $e'),
          data: (categories) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) => ChoiceChip(
              label: Text(cat.name),
              selected: _selectedCategory?.id == cat.id,
              onSelected: (s) => setState(() => _selectedCategory = s ? cat : null),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: _selectedCategory?.id == cat.id ? Colors.white : AppColors.textPrimaryLight,
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 24),
        
        // Condition
        Text('Condition *', style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ('new', 'New', Icons.fiber_new),
            ('like_new', 'Like New', Icons.star),
            ('good', 'Good', Icons.thumb_up),
            ('fair', 'Fair', Icons.thumbs_up_down),
            ('poor', 'Poor', Icons.warning),
          ].map((c) => ChoiceChip(
            avatar: Icon(c.$3, size: 16, color: _selectedCondition == c.$1 ? Colors.white : AppColors.textSecondaryLight),
            label: Text(c.$2),
            selected: _selectedCondition == c.$1,
            onSelected: (s) => setState(() => _selectedCondition = c.$1),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: _selectedCondition == c.$1 ? Colors.white : AppColors.textPrimaryLight,
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildPricingStep(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set Your Price', style: AppTypography.headlineMedium),
        const SizedBox(height: 24),
        
        AppTextField(
          controller: _startingPriceController,
          label: 'Starting Price *',
          hintText: '0.00',
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _reservePriceController,
          label: 'Reserve Price (Optional)',
          hintText: 'Minimum you\'ll accept',
          prefixIcon: Icons.lock_outline,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        Text(
          'If bids don\'t reach reserve, you\'re not obligated to sell.',
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _bidIncrementController,
          label: 'Minimum Bid Increment',
          hintText: '5.00',
          prefixIcon: Icons.trending_up,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        
        // Location info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.location_on, color: AppColors.info),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Listing Location', style: AppTypography.titleSmall),
                Text(
                  '${user?.homeTown?.name ?? 'Your town'}${user?.homeSuburb != null ? ', ${user!.homeSuburb!.name}' : ''}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        
        AppTextField(
          controller: _pickupLocationController,
          label: 'Pickup Location (Optional)',
          hintText: 'Where can buyers collect the item?',
          prefixIcon: Icons.place,
        ),
        const SizedBox(height: 24),
        
        // Options
        _SwitchOption(
          title: 'Shipping Available',
          subtitle: 'Will you ship this item?',
          value: _shippingAvailable,
          onChanged: (v) => setState(() => _shippingAvailable = v),
        ),
        const SizedBox(height: 8),
        _SwitchOption(
          title: 'Allow Offers',
          subtitle: 'Let buyers make offers before auction ends',
          value: _allowOffers,
          onChanged: (v) => setState(() => _allowOffers = v),
        ),
        const SizedBox(height: 24),
        
        // Duration info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.timer, color: AppColors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Auction Duration', style: AppTypography.titleSmall),
                Text('Your auction will run for 7 days', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
              ]),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: AppButton(
                label: 'Back',
                onPressed: _isPublishing ? null : () => setState(() => _currentStep--),
                isOutlined: true,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              label: _currentStep == 2 
                  ? (_isPublishing ? 'Publishing...' : 'Publish Auction')
                  : 'Next',
              onPressed: (_isPublishing || _isUploading) ? null : _nextStep,
              icon: _currentStep == 2 ? Icons.rocket_launch : Icons.arrow_forward,
            ),
          ),
        ]),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImages();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _takePhoto();
            },
          ),
        ]),
      ),
    );
  }

  void _showExitDialog() {
    if (_localImages.isEmpty && _titleController.text.isEmpty) {
      context.pop();
      return;
    }
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard Auction?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _saveDraft() {
    // TODO: Implement save draft functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved'), backgroundColor: AppColors.success),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final int index;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepLabel({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive || isCompleted ? AppColors.primary : AppColors.textSecondaryLight;
    
    return Column(children: [
      if (isCompleted)
        Icon(Icons.check_circle, size: 16, color: color)
      else
        Text('${index + 1}', style: AppTypography.labelSmall.copyWith(color: color)),
      Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
    ]);
  }
}

class _AddPhotoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, style: BorderStyle.solid, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_a_photo, color: AppColors.primary),
          const SizedBox(height: 4),
          Text('Add', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
        ]),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final File file;
  final bool isCover;
  final VoidCallback onRemove;

  const _PhotoCard({
    required this.file,
    required this.isCover,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (isCover)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Cover', style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 10)),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTypography.titleSmall),
            Text(subtitle, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.primary),
      ]),
    );
  }
}
