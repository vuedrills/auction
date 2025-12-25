import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/app_button.dart';

/// Email Verification Screen - Connected to Backend
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() async {
    while (_resendTimer > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendTimer--);
    }
  }

  void _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).verifyEmail(code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!'), backgroundColor: AppColors.success),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          // Clear the code fields on error
          for (final c in _controllers) {
            c.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleResend() async {
    try {
      await ref.read(authRepositoryProvider).forgotPassword(widget.email);
      setState(() => _resendTimer = 60);
      _startTimer();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent!'), backgroundColor: AppColors.info),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final text = data!.text!.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.length >= 6) {
        for (var i = 0; i < 6; i++) {
          _controllers[i].text = text[i];
        }
        _focusNodes[5].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Verify Email', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Icon
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mail_outline, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              
              Text('Enter Verification Code', style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to\n${widget.email}',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
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
                      Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppColors.error))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) => SizedBox(
                  width: 48, height: 56,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: AppTypography.headlineMedium,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.error, width: 2),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        _focusNodes[i + 1].requestFocus();
                      }
                      if (v.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                      // Auto-submit when all fields are filled
                      if (i == 5 && v.isNotEmpty) {
                        final code = _controllers.map((c) => c.text).join();
                        if (code.length == 6) {
                          _handleVerify();
                        }
                      }
                    },
                  ),
                )),
              ),
              const SizedBox(height: 16),

              // Paste button
              TextButton.icon(
                onPressed: _handlePaste,
                icon: Icon(Icons.content_paste, size: 18, color: AppColors.primary),
                label: Text('Paste from clipboard', style: TextStyle(color: AppColors.primary)),
              ),
              const SizedBox(height: 24),

              // Verify button
              AppButton(
                label: 'Verify',
                onPressed: _isLoading ? null : _handleVerify,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              // Resend timer
              _resendTimer > 0
                  ? Text(
                      'Resend code in ${_resendTimer}s',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                    )
                  : TextButton(
                      onPressed: _handleResend,
                      child: Text('Resend Code', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                    ),
              const SizedBox(height: 16),

              // Change email
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Wrong email? Go back',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
