import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product? product; // If null, create new

  const EditProductScreen({super.key, this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  
  // State
  String _pricingType = 'fixed'; // fixed, negotiable
  String _condition = 'new';
  List<String> _uploadedImages = [];
  List<XFile> _newImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _titleController.text = widget.product!.title;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stockQuantity.toString();
      _pricingType = widget.product!.pricingType;
      _condition = widget.product!.condition;
      _uploadedImages = List.from(widget.product!.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload new images
      final storage = ref.read(supabaseStorageProvider);
      final newUrls = <String>[];
      
      for (var file in _newImages) {
        final url = await storage.uploadFile(File(file.path), 'auctions'); // Reusing auction bucket
        if (url != null) newUrls.add(url);
      }

      final finalImages = [..._uploadedImages, ...newUrls];

      // 2. Create or Update
      if (widget.product == null) {
        // Create
        final request = CreateProductRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          stockQuantity: int.parse(_stockController.text),
          condition: _condition,
          pricingType: _pricingType,
          images: finalImages,
        );
        
        await ref.read(storeRepositoryProvider).createProduct(request);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully!')),
          );
        }
      } else {
        // Update
        await ref.read(storeRepositoryProvider).updateProduct(
          widget.product!.id,
          {
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': double.parse(_priceController.text),
            'stock_quantity': int.parse(_stockController.text),
            'condition': _condition,
            'pricing_type': _pricingType,
            'images': finalImages,
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully!')),
          );
        }
      }

      // Refresh providers
      ref.invalidate(myProductsProvider);
      ref.invalidate(myStoreProvider);
      
      // Also invalidate store-front products if we know the slug
      final myStore = ref.read(myStoreProvider).valueOrNull;
      if (myStore != null) {
        ref.invalidate(storeProductsProvider(StoreProductsParams(slug: myStore.slug)));
      }
      
      if (mounted) context.pop();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images Section
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add Button
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('Add Photo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Existing Images
                  ..._uploadedImages.map((url) => _buildImageThumbnail(url, isNetwork: true)),
                  
                  // New Images
                  ..._newImages.map((file) => _buildImageThumbnail(file.path, isNetwork: false)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Basic Info
            AppTextField(
              label: 'Product Title',
              hintText: 'e.g. iPhone 13 Pro Max',
              controller: _titleController,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Price',
              hintText: '0.00',
              controller: _priceController,
              prefixIcon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            // Options Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Pricing Type'),
                    value: _pricingType,
                    items: const [
                       DropdownMenuItem(value: 'fixed', child: Text('Fixed Price')),
                       DropdownMenuItem(value: 'negotiable', child: Text('Negotiable')),
                    ],
                    onChanged: (v) => setState(() => _pricingType = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Condition'),
                    value: _condition,
                    items: const [
                       DropdownMenuItem(value: 'new', child: Text('New')),
                       DropdownMenuItem(value: 'used', child: Text('Used')),
                       DropdownMenuItem(value: 'refurbished', child: Text('Refurbished')),
                    ],
                    onChanged: (v) => setState(() => _condition = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Stock Quantity',
              controller: _stockController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Description',
              hintText: 'Describe your product...',
              controller: _descriptionController,
              maxLines: 4,
            ),
            
            const SizedBox(height: 32),
            AppButton(
              label: widget.product == null ? 'Post Product' : 'Save Changes',
              onPressed: _submit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String path, {required bool isNetwork}) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            image: DecorationImage(
              image: isNetwork ? NetworkImage(path) as ImageProvider : FileImage(File(path)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isNetwork) {
                  _uploadedImages.remove(path);
                } else {
                  _newImages.removeWhere((file) => file.path == path);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
