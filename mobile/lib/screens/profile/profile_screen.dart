import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/common/badge_widgets.dart';

/// Profile Screen - Connected to Backend
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.surfaceLight,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)]),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side - User info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Guest User',
                                style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user != null ? 'Member since ${_formatDate(user.createdAt)}' : '',
                                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                              ),
                              if (user?.homeTown != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      user!.homeTown!.name,
                                      style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right side - Avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: user?.avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: CachedNetworkImage(
                                    imageUrl: user!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Icon(Icons.person, size: 35, color: AppColors.primary),
                                    errorWidget: (_, __, ___) => const Icon(Icons.person, size: 35, color: AppColors.primary),
                                  ),
                                )
                              : const Icon(Icons.person, size: 35, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Stats
          SliverToBoxAdapter(child: _buildStatsSection(ref)),
          
          // Badges Section
          SliverToBoxAdapter(child: _buildBadgesSection(ref, context)),
          
          // Menu items
          SliverToBoxAdapter(
            child: Column(children: [
              _MenuItem(
                icon: Icons.gavel,
                title: 'My Auctions',
                onTap: () => context.push('/profile/auctions'),
              ),
              _MenuItem(
                icon: Icons.history,
                title: 'Bid History',
                onTap: () => context.push('/profile/bids'),
              ),
              _MenuItem(
                icon: Icons.emoji_events,
                title: 'Won Items',
                onTap: () => context.push('/profile/won'),
              ),
              _MenuItem(
                icon: Icons.favorite_border,
                title: 'Watchlist',
                onTap: () => context.push('/profile/watchlist'),
              ),
              const SizedBox(height: 16),
              _MenuItem(
                icon: Icons.edit,
                title: 'Edit Profile',
                onTap: () => context.push('/profile/edit'),
              ),
              _MenuItem(
                icon: Icons.settings,
                title: 'Settings',
                onTap: () => context.push('/settings'),
              ),
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => context.push('/help'),
              ),
              _MenuItem(
                icon: Icons.logout,
                title: authState.status == AuthStatus.loading ? 'Logging out...' : 'Log Out',
                onTap: () => _handleLogout(context, ref),
                isDestructive: true,
              ),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(WidgetRef ref) {
    final myAuctionsState = ref.watch(myAuctionsProvider);
    final wonAuctionsAsync = ref.watch(wonAuctionsProvider);
    final myBidsAsync = ref.watch(myBidsProvider);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        _StatItem(
          value: '${myAuctionsState.auctions.length}',
          label: 'Auctions',
        ),
        _StatItem(
          value: wonAuctionsAsync.when(
            data: (r) => '${r.auctions.length}',
            loading: () => '-',
            error: (_, __) => '0',
          ),
          label: 'Won',
        ),
        _StatItem(
          value: myBidsAsync.when(
            data: (bids) => '${bids.length}',
            loading: () => '-',
            error: (_, __) => '0',
          ),
          label: 'Bids',
        ),
        const _StatItem(value: '4.8', label: 'Rating'),
      ]),
    );
  }

  Widget _buildBadgesSection(WidgetRef ref, BuildContext context) {
    final badgesAsync = ref.watch(myBadgesProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: badgesAsync.when(
        data: (badges) => BadgeShowcase(
          badges: badges,
          onGetVerified: () => context.push('/profile/verification'),
        ),
        loading: () => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}';
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: AppTypography.headlineMedium.copyWith(color: AppColors.primary)),
      Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
    ]));
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  const _MenuItem({required this.icon, required this.title, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: (isDestructive ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTypography.titleSmall.copyWith(color: isDestructive ? AppColors.error : null)),
      trailing: Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
      onTap: onTap,
    );
  }
}
