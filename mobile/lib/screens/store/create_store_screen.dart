import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class CreateStoreScreen extends ConsumerStatefulWidget {
  const CreateStoreScreen({super.key});

  @override
  ConsumerState<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends ConsumerState<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _whatsappController = TextEditingController();
  
  String? _selectedCategoryId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = CreateStoreRequest(
        storeName: _nameController.text.trim(),
        tagline: _taglineController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        categoryId: _selectedCategoryId,
      );

      final store = await ref.read(storeRepositoryProvider).createStore(request);
      
      if (mounted) {
        // Refresh my store provider
        ref.invalidate(myStoreProvider);
        
        // Show success and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store created successfully! 🎉')),
        );
        context.go('/store/${store.slug}');
      }
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
    final categoriesAsync = ref.watch(storeCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Create Your Store'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Intro Card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Selling Today', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(
                          'Create your own digital shop, list fixed-price items, and reach more customers.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Text('Store Details', style: AppTypography.headlineSmall),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Store Name',
              hintText: 'e.g. Tendai Tech Hub',
              controller: _nameController,
              prefixIcon: Icons.store,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            AppTextField(
              label: 'Tagline (Short)',
              hintText: 'e.g. Best gadgets in Harare',
              controller: _taglineController,
            ),
            const SizedBox(height: 4),
            Text('Appears under your store name', style: AppTypography.labelSmall.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),

            Text('Business Category', style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            
            categoriesAsync.when(
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    label: Text(cat.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategoryId = selected ? cat.id : null);
                    },
                    avatar: Icon(cat.iconData, size: 16, color: isSelected ? Colors.white : Colors.black54),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (e, _) => Text('Failed to load categories: $e'),
            ),
            const SizedBox(height: 24),

            Text('Contact Info', style: AppTypography.headlineSmall),
            const SizedBox(height: 16),

            AppTextField(
              label: 'WhatsApp Number',
              hintText: '+263 7...',
              controller: _whatsappController,
              prefixIcon: Icons.chat,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 4),
            Text('Customers will contact you here', style: AppTypography.labelSmall.copyWith(color: Colors.grey)),
            
            const SizedBox(height: 32),

            AppButton(
              label: 'Launch Store 🚀',
              onPressed: _submit,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
