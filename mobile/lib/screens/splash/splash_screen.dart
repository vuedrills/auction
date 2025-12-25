import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/services/storage_service.dart';
import '../../data/providers/auth_provider.dart';

/// Splash Screen - First screen shown when app launches
/// Design Reference: trabab/designs/splash_screen/
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final storage = ref.read(storageServiceProvider);
    final token = await storage.getToken();
    final onboardingComplete = await storage.isOnboardingComplete();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Initialize auth state with existing token
      ref.read(authProvider.notifier).initialize();
      context.go('/home');
    } else if (onboardingComplete) {
      context.go('/login');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background texture (subtle)
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.backgroundLight,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo composition
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main icon container
                      Container(
                        width: 144,
                        height: 144,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                      
                      // Secondary "Town" badge
                      Positioned(
                        bottom: -16,
                        right: -16,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 16,
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.backgroundLight,
                              width: 4,
                            ),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Typography
                  Text(
                    'AirMass',
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.textPrimaryLight,
                      letterSpacing: -1,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Your Town. Your Auctions.',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 64),
                  
                  // Loading indicator
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Version footer
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'v1.0',
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
