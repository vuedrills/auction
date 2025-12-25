import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/app_button.dart';

/// Forgot Password Screen - Connected to Backend
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your email');
      return;
    }
    
    if (!_emailController.text.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).forgotPassword(_emailController.text.trim());
      setState(() => _emailSent = true);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openEmailApp() {
    // Just show a message - opening email app requires url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please check your email app for the reset link')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Forgot Password?', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text(
          "No worries! Enter your email and we'll send you reset instructions.",
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 32),

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
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppColors.error))),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        AppTextField(
          controller: _emailController,
          label: 'Email Address',
          hintText: 'Enter your email',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'Send Reset Link',
          onPressed: _isLoading ? null : _handleSubmit,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: Text('Back to Login', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read, size: 48, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        Text('Check Your Email', style: AppTypography.headlineLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'We sent a password reset link to\n${_emailController.text}',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'If you don\'t see it, check your spam folder.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Open Email App',
          onPressed: _openEmailApp,
          icon: Icons.open_in_new,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _emailSent = false;
            _errorMessage = null;
          }),
          child: Text(
            "Didn't receive email? Try again",
            style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            'Back to Login',
            style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight),
          ),
        ),
      ],
    );
  }
}
