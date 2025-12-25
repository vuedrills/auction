import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../widgets/common/app_button.dart';

/// Session Expired Screen
class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.timer_off_outlined, size: 48, color: AppColors.warning),
              ),
              const SizedBox(height: 32),
              Text('Session Expired', style: AppTypography.displaySmall),
              const SizedBox(height: 12),
              Text('Your session has expired for security reasons.\nPlease log in again to continue.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              AppButton(label: 'Log In Again', onPressed: () => context.go('/login')),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text('Go to Home', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondaryLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Network Offline Screen
class NetworkOfflineScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const NetworkOfflineScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
              ),
              const SizedBox(height: 32),
              Text('No Internet Connection', style: AppTypography.displaySmall),
              const SizedBox(height: 12),
              Text('Please check your internet connection\nand try again.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              AppButton(label: 'Try Again', onPressed: onRetry ?? () {}, icon: Icons.refresh),
            ],
          ),
        ),
      ),
    );
  }
}

/// No Auctions In Town Screen
class NoAuctionsInTownScreen extends StatelessWidget {
  final String townName;
  final VoidCallback? onCreateAuction;
  const NoAuctionsInTownScreen({super.key, required this.townName, this.onCreateAuction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.storefront_outlined, size: 48, color: AppColors.secondary),
            ),
            const SizedBox(height: 24),
            Text('No Auctions Yet', style: AppTypography.headlineLarge),
            const SizedBox(height: 8),
            Text('Be the first to list an item in $townName!\nStart an auction and get the ball rolling.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            AppButton(label: 'Create First Auction', onPressed: onCreateAuction ?? () => context.push('/create-auction'), icon: Icons.add),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/national'),
              child: Text('Browse National Auctions', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty Suburb State
class EmptySuburbScreen extends StatelessWidget {
  final String suburbName;
  final VoidCallback? onCreateAuction;
  const EmptySuburbScreen({super.key, required this.suburbName, this.onCreateAuction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.location_off_outlined, size: 40, color: AppColors.info),
            ),
            const SizedBox(height: 24),
            Text('$suburbName is Quiet', style: AppTypography.headlineMedium),
            const SizedBox(height: 8),
            Text('No active auctions in this suburb yet.\nCheck back later or explore other areas.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onCreateAuction,
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty Notifications State
class EmptyNotificationsScreen extends StatelessWidget {
  const EmptyNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('All Caught Up!', style: AppTypography.headlineMedium),
            const SizedBox(height: 8),
            Text("You don't have any notifications yet.\nWe'll let you know when something happens.",
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Category Full Error State
class CategoryFullScreen extends StatelessWidget {
  final String categoryName;
  final int waitingPosition;
  final VoidCallback? onJoinWaitlist;
  const CategoryFullScreen({super.key, required this.categoryName, this.waitingPosition = 0, this.onJoinWaitlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(backgroundColor: AppColors.backgroundLight, leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.warning),
              ),
              const SizedBox(height: 32),
              Text('$categoryName is Full', style: AppTypography.displaySmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('All auction slots in this category are currently taken. Join the waiting list to be notified when a slot opens up.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              if (waitingPosition > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text("You're #$waitingPosition on the waiting list", style: AppTypography.titleSmall.copyWith(color: AppColors.success)),
                    ],
                  ),
                ),
              ] else ...[
                AppButton(label: 'Join Waiting List', onPressed: onJoinWaitlist ?? () {}, icon: Icons.add_alert),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Choose Different Category', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
