import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/services/storage_service.dart';

/// Onboarding Screen - Introduction carousel
/// Design Reference: trabab/designs/onboarding_carousel/
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Auctions start at',
      highlightedTitle: 'home',
      description: 'Browse and create listings exclusive to your local town. Connect with neighbors in real-time.',
      icon: Icons.location_on_rounded,
      iconLabel: 'Your Location',
      iconSubLabel: 'Fairview Town',
    ),
    OnboardingSlide(
      title: 'Suburbs run the',
      highlightedTitle: 'show',
      description: 'Every suburb has its own independent auction block. No noise, just local gems.',
      icon: Icons.home_work_rounded,
      iconLabel: 'Connected',
      iconSubLabel: 'Communities',
    ),
    OnboardingSlide(
      title: 'See the bigger',
      highlightedTitle: 'picture',
      description: 'Zoom out to the National View to see trending auctions across every town in the country.',
      icon: Icons.public_rounded,
      iconLabel: 'National',
      iconSubLabel: 'Auctions',
    ),
    OnboardingSlide(
      title: 'Fair slots for',
      highlightedTitle: 'everyone',
      description: 'Our slot-based system ensures every item gets its moment in the spotlight. No crowding.',
      icon: Icons.gavel_rounded,
      iconLabel: 'LIVE',
      iconSubLabel: 'Queue System',
      isLast: true,
    ),
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingComplete(true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(slide: _slides[index]);
                },
              ),
            ),

            // Action area
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == 0 || _currentPage == _slides.length - 1
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: _currentPage == 0 || _currentPage == _slides.length - 1
                            ? Colors.white
                            : AppColors.primary,
                        elevation: _currentPage == 0 || _currentPage == _slides.length - 1 ? 4 : 0,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _slides.length - 1 ? 'Join Your Town' : 'Next',
                            style: AppTypography.titleLarge,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _slides.length - 1
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentPage ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? AppColors.primary
                              : AppColors.borderLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
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

/// Onboarding slide data
class OnboardingSlide {
  final String title;
  final String highlightedTitle;
  final String description;
  final IconData icon;
  final String iconLabel;
  final String iconSubLabel;
  final bool isLast;

  OnboardingSlide({
    required this.title,
    required this.highlightedTitle,
    required this.description,
    required this.icon,
    required this.iconLabel,
    required this.iconSubLabel,
    this.isLast = false,
  });
}

/// Single onboarding page
class _OnboardingPage extends StatelessWidget {
  final OnboardingSlide slide;

  const _OnboardingPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero illustration
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.backgroundDark.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                
                // Center icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      slide.icon,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                // Floating info card
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slide.iconLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              slide.iconSubLabel,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Text content
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimaryLight,
              ),
              children: [
                TextSpan(text: '${slide.title}\n'),
                TextSpan(
                  text: slide.highlightedTitle,
                  style: const TextStyle(color: AppColors.primary),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
