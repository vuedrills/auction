import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../core/services/supabase_storage_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class EditStoreScreen extends ConsumerStatefulWidget {
  final Store store;

  const EditStoreScreen({super.key, required this.store});

  @override
  ConsumerState<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends ConsumerState<EditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _aboutController;
  late TextEditingController _whatsappController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  String? _logoUrl;
  String? _coverUrl;
  File? _newLogoFile;
  File? _newCoverFile;
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.storeName);
    _taglineController = TextEditingController(text: widget.store.tagline);
    _aboutController = TextEditingController(text: widget.store.about);
    _whatsappController = TextEditingController(text: widget.store.whatsapp);
    _phoneController = TextEditingController(text: widget.store.phone);
    _addressController = TextEditingController(text: widget.store.address);
    _logoUrl = widget.store.logoUrl;
    _coverUrl = widget.store.coverUrl;
    _selectedCategoryId = widget.store.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _aboutController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isLogo) {
          _newLogoFile = File(image.path);
        } else {
          _newCoverFile = File(image.path);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storage = ref.read(supabaseStorageProvider);
      
      String? finalLogoUrl = _logoUrl;
      String? finalCoverUrl = _coverUrl;

      if (_newLogoFile != null) {
        finalLogoUrl = await storage.uploadFile(_newLogoFile!, 'stores');
      }
      if (_newCoverFile != null) {
        finalCoverUrl = await storage.uploadFile(_newCoverFile!, 'stores');
      }

      final updates = {
        'store_name': _nameController.text,
        'tagline': _taglineController.text,
        'about': _aboutController.text,
        'whatsapp': _whatsappController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'category_id': _selectedCategoryId,
        'logo_url': finalLogoUrl,
        'cover_url': finalCoverUrl,
      };

      await ref.read(storeRepositoryProvider).updateMyStore(updates);
      
      if (mounted) {
        ref.invalidate(myStoreProvider);
        ref.invalidate(storeBySlugProvider(widget.store.slug));
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Store?'),
        content: const Text('This will permanently delete your store and all its products. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(storeRepositoryProvider).deleteStore();
        if (mounted) {
          ref.invalidate(myStoreProvider);
          ref.invalidate(featuredStoresProvider);
          // Go back to profile or home
          context.go('/profile');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting store: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(storeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Store')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analytics Access
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/store/${widget.store.id}/analytics'),
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('View Store Analytics'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                        ),
                      ),
                    ),

                    // Cover Image Picker
                    Text('Cover Image', style: AppTypography.titleSmall),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          image: _newCoverFile != null
                              ? DecorationImage(image: FileImage(_newCoverFile!), fit: BoxFit.cover)
                              : (_coverUrl != null
                                  ? DecorationImage(image: CachedNetworkImageProvider(_coverUrl!), fit: BoxFit.cover)
                                  : null),
                        ),
                        child: (_newCoverFile == null && _coverUrl == null)
                            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Logo Picker
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Store Logo', style: AppTypography.titleSmall),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _pickImage(true),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _newLogoFile != null
                                    ? FileImage(_newLogoFile!)
                                    : (_logoUrl != null
                                        ? CachedNetworkImageProvider(_logoUrl!)
                                        : null) as ImageProvider?,
                                child: (_newLogoFile == null && _logoUrl == null)
                                    ? const Icon(Icons.store, color: Colors.grey)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: 'Store Name',
                            controller: _nameController,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      label: 'Tagline',
                      controller: _taglineController,
                      hintText: 'e.g. Best electronics in town',
                    ),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      label: 'About Store',
                      controller: _aboutController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    Text('Category', style: AppTypography.titleSmall),
                    const SizedBox(height: 8),
                    categoriesAsync.when(
                      data: (list) => DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: list.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.displayName),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading categories'),
                    ),
                    const SizedBox(height: 24),

                    Text('Contact & Location', style: AppTypography.titleMedium),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'WhatsApp',
                            controller: _whatsappController,
                            prefixIcon: Icons.chat,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppTextField(
                            label: 'Phone',
                            controller: _phoneController,
                            prefixIcon: Icons.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Physical Address',
                      controller: _addressController,
                      prefixIcon: Icons.location_on,
                      hintText: 'Street number, Building name, etc.',
                    ),
                    const SizedBox(height: 32),

                    AppButton(
                      label: 'Save Changes',
                      onPressed: _save,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _deleteStore,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete Store', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
