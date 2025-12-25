import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/profile_screen.dart';
import 'national_auctions_screen.dart';
import '../notification/notification_inbox_screen.dart';

/// Home Screen - Wrapper with bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    if (index == 2) {
      // Center FAB - Create auction
      context.push('/create-auction');
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myTownAuctionsProvider.notifier).loadAuctions(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: const [
          MyTownTabContent(),
          NationalAuctionsScreen(),
          NotificationInboxScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
      extendBody: true,
    );
  }
}

/// My Town Tab Content - Connected to Backend
class MyTownTabContent extends ConsumerWidget {
  const MyTownTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auctionState = ref.watch(myTownAuctionsProvider);
    final user = ref.watch(currentUserProvider);
    final endingSoonAsync = ref.watch(endingSoonProvider(user?.homeTownId));

    return RefreshIndicator(
      onRefresh: () => ref.read(myTownAuctionsProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader(context, user)),
          
          // Suburb chips
          SliverToBoxAdapter(child: _SuburbChips(townId: user?.homeTownId)),
          
          // Ending Soon Section
          SliverToBoxAdapter(child: _buildSectionHeader(context, 'Ending Soon', Icons.timer_rounded)),
          SliverToBoxAdapter(
            child: endingSoonAsync.when(
              data: (auctions) => _EndingSoonList(auctions: auctions),
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(height: 200, child: Center(child: Text('Failed to load'))),
            ),
          ),
          
          // Fresh in Town Section
          SliverToBoxAdapter(child: _buildSectionHeader(context, 'Fresh in Your Town', Icons.local_fire_department_rounded)),
          
          if (auctionState.isLoading && auctionState.auctions.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (auctionState.error != null && auctionState.auctions.isEmpty)
            SliverFillRemaining(child: Center(child: Text('Error: ${auctionState.error}')))
          else if (auctionState.auctions.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No auctions in your town yet')))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AuctionCard(auction: auctionState.auctions[index]),
                  childCount: auctionState.auctions.length,
                ),
              ),
            ),
          
          // Bottom padding for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(color: AppColors.surfaceLight),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  Text('HOME TOWN', style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
                GestureDetector(
                  onTap: () => context.push('/national'),
                  child: Row(children: [
                    Text('See National', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondaryLight)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight, size: 18),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(user?.homeTown?.name ?? 'Your Town', style: AppTypography.displaySmall),
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: user?.avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(imageUrl: user!.avatarUrl!, fit: BoxFit.cover),
                        )
                      : Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.headlineSmall),
          ]),
          Text('See All', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

/// Suburb Chips - Connected to Backend
class _SuburbChips extends ConsumerWidget {
  final String? townId;
  const _SuburbChips({this.townId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (townId == null) return const SizedBox.shrink();
    
    final suburbsAsync = ref.watch(suburbsProvider(townId!));
    final selectedSuburb = ref.watch(selectedSuburbProvider);

    return suburbsAsync.when(
      data: (suburbs) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // "All" chip
            _SuburbChip(
              name: 'All Suburbs',
              isSelected: selectedSuburb == null,
              onTap: () => ref.read(selectedSuburbProvider.notifier).state = null,
            ),
            ...suburbs.map((s) => _SuburbChip(
              name: s.name,
              isSelected: selectedSuburb?.id == s.id,
              onTap: () => ref.read(selectedSuburbProvider.notifier).state = s,
            )),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SuburbChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;
  const _SuburbChip({required this.name, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.textPrimaryLight : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderLight),
          ),
          child: Text(name, style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimaryLight)),
        ),
      ),
    );
  }
}

/// Ending Soon List
class _EndingSoonList extends StatelessWidget {
  final List<Auction> auctions;
  const _EndingSoonList({required this.auctions});

  @override
  Widget build(BuildContext context) {
    if (auctions.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text('No auctions ending soon', style: AppTypography.bodyMedium)),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: auctions.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _EndingSoonCard(auction: auctions[index]),
        ),
      ),
    );
  }
}

class _EndingSoonCard extends StatelessWidget {
  final Auction auction;
  const _EndingSoonCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${auction.id}'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (auction.primaryImage != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: auction.primaryImage!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Center(child: Icon(Icons.image, color: Colors.grey.shade400)),
                        errorWidget: (_, __, ___) => Center(child: Icon(Icons.broken_image, color: Colors.grey.shade400)),
                      ),
                    )
                  else
                    Center(child: Icon(Icons.image_rounded, size: 40, color: Colors.grey.shade400)),
                  // Timer badge
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.timer_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(auction.timeRemaining ?? '', style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auction.title, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('\$${auction.displayPrice.toStringAsFixed(2)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.gavel_rounded, size: 12, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text('${auction.totalBids} bids', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuctionCard extends StatelessWidget {
  final Auction auction;
  const _AuctionCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auction/${auction.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (auction.primaryImage != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: auction.primaryImage!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Center(child: Icon(Icons.image, color: Colors.grey.shade400)),
                          errorWidget: (_, __, ___) => Center(child: Icon(Icons.broken_image, color: Colors.grey.shade400)),
                        ),
                      )
                    else
                      Center(child: Icon(Icons.image_rounded, size: 40, color: Colors.grey.shade400)),
                    if (auction.isEndingSoon)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('LIVE', style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auction.title, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(auction.suburb?.name ?? auction.town?.name ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        Text(auction.timeRemaining ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder tabs - redirect to actual screens
class _NationalTabPlaceholder extends StatelessWidget {
  const _NationalTabPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('National Tab - Navigate to /national'));
}

class _NotificationsTabPlaceholder extends StatelessWidget {
  const _NotificationsTabPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Notifications Tab'));
}

class _ProfileTabPlaceholder extends StatelessWidget {
  const _ProfileTabPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Profile Tab'));
}
