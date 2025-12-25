import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/app_button.dart';

/// Register Screen - Connected to Backend with Town Selection
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  Town? _selectedTown;
  Suburb? _selectedSuburb;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTown == null) {
      setState(() => _errorMessage = 'Please select your home town');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        homeTownId: _selectedTown!.id,
        homeSuburbId: _selectedSuburb?.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!'), backgroundColor: AppColors.success),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showTownPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TownPickerSheet(
        selectedTown: _selectedTown,
        onTownSelected: (town) {
          setState(() {
            _selectedTown = town;
            _selectedSuburb = null;
          });
          Navigator.pop(context);
          // Show suburb picker for the selected town
          _showSuburbPicker(town.id);
        },
      ),
    );
  }

  void _showSuburbPicker(String townId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SuburbPickerSheet(
        townId: townId,
        selectedSuburb: _selectedSuburb,
        onSuburbSelected: (suburb) {
          setState(() => _selectedSuburb = suburb);
          Navigator.pop(context);
        },
        onSkip: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                  ),
                  Expanded(
                    child: Text('Create Account', textAlign: TextAlign.center, style: AppTypography.titleLarge),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline
                      Text('Join Your Town', style: AppTypography.displaySmall),
                      const SizedBox(height: 8),
                      Text(
                        'Create an account to start buying and selling in your community.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 24),

                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Full Name
                      AppTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'Jane Doe',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Username
                      AppTextField(
                        controller: _usernameController,
                        label: 'Username',
                        hintText: 'janedoe',
                        prefixIcon: Icons.alternate_email,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a username';
                          if (value.length < 3) return 'Username must be at least 3 characters';
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return 'Only letters, numbers, and underscores';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Home Town Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Home Town', style: AppTypography.titleMedium),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Required', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showTownPicker,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedTown != null ? AppColors.primary : AppColors.borderLight,
                                  width: _selectedTown != null ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    color: _selectedTown != null ? AppColors.primary : AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedTown?.name ?? 'Select your town',
                                          style: AppTypography.titleSmall.copyWith(
                                            color: _selectedTown != null ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        if (_selectedSuburb != null)
                                          Text(
                                            _selectedSuburb!.name,
                                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can only sell in your home town, but you can buy from anywhere nationally.',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'jane@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your email';
                          if (!value.contains('@')) return 'Please enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone (Optional)
                      AppTextField(
                        controller: _phoneController,
                        label: 'Phone (Optional)',
                        hintText: '+263 77 123 4567',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Password
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondaryLight,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a password';
                          if (value.length < 8) return 'Password must be at least 8 characters';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer CTA
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AppButton(
                    label: 'Create Account',
                    onPressed: _isLoading ? null : _handleRegister,
                    isLoading: _isLoading,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ", style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text('Sign In', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Town Picker Bottom Sheet
class _TownPickerSheet extends ConsumerStatefulWidget {
  final Town? selectedTown;
  final ValueChanged<Town> onTownSelected;

  const _TownPickerSheet({
    required this.selectedTown,
    required this.onTownSelected,
  });

  @override
  ConsumerState<_TownPickerSheet> createState() => _TownPickerSheetState();
}

class _TownPickerSheetState extends ConsumerState<_TownPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final townsAsync = ref.watch(townsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
          ),
          
          // Title
          Text('Select Your Town', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search towns...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Towns list
          Expanded(
            child: townsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (towns) {
                final filtered = _searchQuery.isEmpty
                    ? towns
                    : towns.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                return ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final town = filtered[i];
                    final isSelected = widget.selectedTown?.id == town.id;

                    return ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_city,
                          color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                        ),
                      ),
                      title: Text(town.name, style: AppTypography.titleSmall),
                      trailing: isSelected ? Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () => widget.onTownSelected(town),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Suburb Picker Bottom Sheet
class _SuburbPickerSheet extends ConsumerStatefulWidget {
  final String townId;
  final Suburb? selectedSuburb;
  final ValueChanged<Suburb> onSuburbSelected;
  final VoidCallback onSkip;

  const _SuburbPickerSheet({
    required this.townId,
    required this.selectedSuburb,
    required this.onSuburbSelected,
    required this.onSkip,
  });

  @override
  ConsumerState<_SuburbPickerSheet> createState() => _SuburbPickerSheetState();
}

class _SuburbPickerSheetState extends ConsumerState<_SuburbPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final suburbsAsync = ref.watch(suburbsProvider(widget.townId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
          ),
          
          // Title
          Text('Select Your Suburb', style: AppTypography.titleLarge),
          Text('(Optional)', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 16),
          
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search suburbs...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Skip button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: widget.onSkip,
              child: Text('Skip - I\'ll select later', style: TextStyle(color: AppColors.textSecondaryLight)),
            ),
          ),
          
          // Suburbs list
          Expanded(
            child: suburbsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (suburbs) {
                final filtered = _searchQuery.isEmpty
                    ? suburbs
                    : suburbs.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No suburbs found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final suburb = filtered[i];
                    final isSelected = widget.selectedSuburb?.id == suburb.id;

                    return ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                        ),
                      ),
                      title: Text(suburb.name, style: AppTypography.titleSmall),
                      trailing: isSelected ? Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () => widget.onSuburbSelected(suburb),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
