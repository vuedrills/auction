import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/store_repository.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../profile/profile_screen.dart';
import '../store/shops_tab_screen.dart';
import '../notification/notification_inbox_screen.dart';
import '../../widgets/store/featured_stores_list.dart';

/// View Scope Provider - Town vs National
enum ViewScope { town, national }
final viewScopeProvider = StateProvider<ViewScope>((ref) => ViewScope.town);

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
    final unreadNotifications = ref.watch(unreadNotificationCountProvider);
    final unreadChats = ref.watch(unreadChatCountProvider);
    final totalUnread = unreadNotifications + unreadChats;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: const [
          HomeTabContent(),        // Unified Home (Town/National toggle)
          ShopsTabScreen(),        // Dedicated Shops tab
          NotificationInboxScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        notificationBadgeCount: totalUnread,
      ),
      extendBody: true,
    );
  }
}

/// Home Tab Content - Unified Town/National with scope toggle
class HomeTabContent extends ConsumerWidget {
  const HomeTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(viewScopeProvider);
    final user = ref.watch(currentUserProvider);
    
    // Use different providers based on scope
    final auctionState = scope == ViewScope.town 
        ? ref.watch(myTownAuctionsProvider)
        : ref.watch(nationalAuctionsProvider);
    
    final endingSoonAsync = scope == ViewScope.town
        ? ref.watch(endingSoonProvider(user?.homeTownId))
        : ref.watch(endingSoonProvider(null)); // null = national
    
    final selectedSuburb = ref.watch(selectedSuburbProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedTown = ref.watch(selectedTownFilterProvider);

    // Filter auctions based on scope
    final filteredAuctions = auctionState.auctions.where((a) {
      if (scope == ViewScope.town) {
        final matchesSuburb = selectedSuburb == null || a.suburbId == selectedSuburb.id;
        final matchesCategory = selectedCategory == null || a.categoryId == selectedCategory.id;
        return matchesSuburb && matchesCategory;
      } else {
        final matchesTown = selectedTown == null || a.townId == selectedTown.id;
        final matchesCategory = selectedCategory == null || a.categoryId == selectedCategory.id;
        return matchesTown && matchesCategory;
      }
    }).toList();

    return RefreshIndicator(
      onRefresh: () => scope == ViewScope.town
          ? ref.read(myTownAuctionsProvider.notifier).refresh()
          : ref.read(nationalAuctionsProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // Header with scope toggle
          SliverToBoxAdapter(child: _UnifiedHeader(scope: scope, user: user)),
          
          // Category Chips
          const SliverToBoxAdapter(child: _CategoryChips()),

          // Featured Stores
          const SliverToBoxAdapter(child: FeaturedStoresList()),
          
          // Ending Soon Section
          SliverToBoxAdapter(child: _buildSectionHeader(
            context, 
            'Ending Soon', 
            Icons.timer_rounded,
            onSeeAll: () {
              final params = <String, String>{
                'title': 'Ending Soon',
                'filter': 'ending_soon',
              };
              if (scope == ViewScope.town && user?.homeTownId != null) {
                params['townId'] = user!.homeTownId!;
              }
              if (selectedSuburb != null) params['suburbId'] = selectedSuburb.id;
              if (selectedCategory != null) params['categoryId'] = selectedCategory.id;
              context.push('/auctions/filtered?${Uri(queryParameters: params).query}');
            },
          )),
          SliverToBoxAdapter(
            child: endingSoonAsync.when(
              data: (auctions) {
                // Filter ending soon
                final filtered = auctions.where((a) {
                  if (scope == ViewScope.town) {
                    final matchesSuburb = selectedSuburb == null || a.suburbId == selectedSuburb.id;
                    final matchesCategory = selectedCategory == null || a.categoryId == selectedCategory.id;
                    return matchesSuburb && matchesCategory;
                  } else {
                    final matchesTown = selectedTown == null || a.townId == selectedTown.id;
                    final matchesCategory = selectedCategory == null || a.categoryId == selectedCategory.id;
                    return matchesTown && matchesCategory;
                  }
                }).toList();
                return _EndingSoonList(auctions: filtered);
              },
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(height: 200, child: Center(child: Text('Failed to load'))),
            ),
          ),
          
          // Fresh Auctions Section
          SliverToBoxAdapter(child: _buildSectionHeader(
            context, 
            scope == ViewScope.town 
                ? 'Fresh in ${user?.homeTown?.name ?? 'Your Town'}'
                : 'Fresh Nationwide', 
            Icons.local_fire_department_rounded,
            onSeeAll: () {
              final params = <String, String>{
                'title': scope == ViewScope.town 
                    ? 'Fresh in ${user?.homeTown?.name ?? 'Your Town'}'
                    : 'Fresh Nationwide',
                'filter': 'fresh',
              };
              if (scope == ViewScope.town && user?.homeTownId != null) {
                params['townId'] = user!.homeTownId!;
              }
              if (selectedSuburb != null) params['suburbId'] = selectedSuburb.id;
              if (selectedCategory != null) params['categoryId'] = selectedCategory.id;
              context.push('/auctions/filtered?${Uri(queryParameters: params).query}');
            },
          )),
          
          if (auctionState.isLoading && auctionState.auctions.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (auctionState.error != null && auctionState.auctions.isEmpty)
            SliverFillRemaining(child: Center(child: Text('Error: ${auctionState.error}')))
          else if (filteredAuctions.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 200,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      _getEmptyMessage(scope, selectedSuburb, selectedTown, selectedCategory),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
            )
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
                  (context, index) => _AuctionCard(auction: filteredAuctions[index]),
                  childCount: filteredAuctions.length,
                ),
              ),
            ),
          
          // Bottom padding for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
  
  String _getEmptyMessage(ViewScope scope, Suburb? suburb, Town? town, Category? category) {
    if (scope == ViewScope.town) {
      if (suburb != null && category != null) {
        return 'No ${category.name} in ${suburb.name}';
      } else if (suburb != null) {
        return 'No auctions in ${suburb.name}';
      } else if (category != null) {
        return 'No ${category.name} auctions';
      }
      return 'No auctions in your town yet';
    } else {
      if (town != null && category != null) {
        return 'No ${category.name} in ${town.name}';
      } else if (town != null) {
        return 'No auctions in ${town.name}';
      } else if (category != null) {
        return 'No ${category.name} auctions';
      }
      return 'No auctions found';
    }
  }
}

/// Town filter provider (for national scope)
final selectedTownFilterProvider = StateProvider<Town?>((ref) => null);



/// Header with integrated suburb dropdown
class _HeaderWithDropdown extends ConsumerWidget {
  final User? user;
  const _HeaderWithDropdown({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suburbsAsync = user?.homeTownId != null 
        ? ref.watch(suburbsProvider(user!.homeTownId!))
        : const AsyncValue<List<Suburb>>.data([]);
    final selectedSuburb = ref.watch(selectedSuburbProvider);

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

              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Town name
                Text(user?.homeTown?.name ?? 'Your Town', style: AppTypography.displaySmall),
                const Spacer(),
                // Suburb dropdown (compact)
                suburbsAsync.when(
                  data: (suburbs) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<Suburb?>(
                      value: selectedSuburb,
                      hint: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 14, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text('All', style: AppTypography.labelSmall),
                        ],
                      ),
                      underline: const SizedBox(),
                      isDense: true,
                      icon: Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondaryLight),
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimaryLight),
                      items: [
                        DropdownMenuItem<Suburb?>(value: null, child: Text('All Suburbs')),
                        ...suburbs.map((s) => DropdownMenuItem<Suburb?>(
                          value: s,
                          child: Text(s.name),
                        )),
                      ],
                      onChanged: (s) => ref.read(selectedSuburbProvider.notifier).state = s,
                    ),
                  ),
                  loading: () => const SizedBox(width: 60),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                // Profile icon
                GestureDetector(
                  onTap: () {
                    if (user?.homeTownId != null) {
                      context.push('/suburbs/${user?.homeTownId}?name=${Uri.encodeComponent(user?.homeTown?.name ?? '')}');
                    }
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.explore_outlined, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified Header with scope toggle
class _UnifiedHeader extends ConsumerWidget {
  final ViewScope scope;
  final User? user;
  const _UnifiedHeader({required this.scope, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suburbsAsync = user?.homeTownId != null 
        ? ref.watch(suburbsProvider(user!.homeTownId!))
        : const AsyncValue<List<Suburb>>.data([]);
    final townsAsync = ref.watch(townsProvider);
    final selectedSuburb = ref.watch(selectedSuburbProvider);
    final selectedTown = ref.watch(selectedTownFilterProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(color: AppColors.surfaceLight),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scope indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(
                    scope == ViewScope.town ? Icons.location_on_rounded : Icons.public_rounded, 
                    color: AppColors.primary, 
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    scope == ViewScope.town ? 'MY TOWN' : 'NATIONWIDE', 
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary, 
                      fontWeight: FontWeight.w700, 
                      letterSpacing: 1,
                    ),
                  ),
                ]),
                // Scope toggle button
                GestureDetector(
                  onTap: () {
                    ref.read(viewScopeProvider.notifier).state = 
                        scope == ViewScope.town ? ViewScope.national : ViewScope.town;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scope == ViewScope.town 
                          ? Colors.blue.shade50 
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scope == ViewScope.town 
                            ? Colors.blue.shade200 
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          scope == ViewScope.town ? Icons.public_rounded : Icons.home_rounded,
                          size: 14,
                          color: scope == ViewScope.town ? Colors.blue : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scope == ViewScope.town ? 'National' : 'My Town',
                          style: AppTypography.labelSmall.copyWith(
                            color: scope == ViewScope.town ? Colors.blue : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Location name
                Expanded(
                  child: Text(
                    scope == ViewScope.town 
                        ? (user?.homeTown?.name ?? 'Your Town')
                        : (selectedTown?.name ?? 'All Zimbabwe'),
                    style: AppTypography.displaySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Filter dropdown based on scope
                if (scope == ViewScope.town)
                  // Suburb dropdown for town scope
                  suburbsAsync.when(
                    data: (suburbs) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<Suburb?>(
                        value: selectedSuburb,
                        hint: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 14, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text('All', style: AppTypography.labelSmall),
                          ],
                        ),
                        underline: const SizedBox(),
                        isDense: true,
                        icon: Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondaryLight),
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimaryLight),
                        items: [
                          DropdownMenuItem<Suburb?>(value: null, child: Text('All Suburbs')),
                          ...suburbs.map((s) => DropdownMenuItem<Suburb?>(
                            value: s,
                            child: Text(s.name),
                          )),
                        ],
                        onChanged: (s) => ref.read(selectedSuburbProvider.notifier).state = s,
                      ),
                    ),
                    loading: () => const SizedBox(width: 60),
                    error: (_, __) => const SizedBox.shrink(),
                  )
                else
                  // Town dropdown for national scope
                  townsAsync.when(
                    data: (towns) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<Town?>(
                        value: selectedTown,
                        hint: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_city, size: 14, color: AppColors.textSecondaryLight),
                            const SizedBox(width: 4),
                            Text('All Towns', style: AppTypography.labelSmall),
                          ],
                        ),
                        underline: const SizedBox(),
                        isDense: true,
                        icon: Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondaryLight),
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimaryLight),
                        items: [
                          DropdownMenuItem<Town?>(value: null, child: Text('All Towns')),
                          ...towns.map((t) => DropdownMenuItem<Town?>(
                            value: t,
                            child: Text(t.name),
                          )),
                        ],
                        onChanged: (t) => ref.read(selectedTownFilterProvider.notifier).state = t,
                      ),
                    ),
                    loading: () => const SizedBox(width: 60),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {VoidCallback? onSeeAll}) {
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
        GestureDetector(
          onTap: onSeeAll,
          child: Text('See All', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
        ),
      ],
    ),
  );
}


/// Category Chips - Primary Filter
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return categoriesAsync.when(
      data: (categories) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // "All" chip
            _CategoryChip(
              name: 'All',
              icon: Icons.grid_view_rounded,
              isSelected: selectedCategory == null,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
            ),
            ...categories.map((c) => _CategoryChip(
              name: c.name,
              icon: _getCategoryIcon(c.icon),
              isSelected: selectedCategory?.id == c.id,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = c,
            )),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'phone_iphone': return Icons.phone_iphone;
      case 'directions_car': return Icons.directions_car;
      case 'checkroom': return Icons.checkroom;
      case 'chair': return Icons.chair;
      case 'build': return Icons.build;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'auto_stories': return Icons.auto_stories;
      case 'toys': return Icons.toys;
      case 'kitchen': return Icons.kitchen;
      case 'music_note': return Icons.music_note;
      case 'diamond': return Icons.diamond;
      default: return Icons.category;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryChip({required this.name, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.textPrimaryLight : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Text(name, style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              )),
            ],
          ),
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
        height: 240,
        child: Center(child: Text('No auctions ending soon', style: AppTypography.bodyMedium)),
      );
    }

    return SizedBox(
      height: 240,
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
        width: 175,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
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
                    // Timer badge
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: auction.isEndingSoon ? AppColors.secondary : Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_rounded, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(auction.timeRemaining ?? '', style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auction.title, style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(auction.suburb?.name ?? auction.town?.name ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                        ),
                        if (auction.totalBids > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gavel_rounded, size: 10, color: AppColors.textSecondaryLight),
                              const SizedBox(width: 2),
                              Text('${auction.totalBids}', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                            ],
                          ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${auction.displayPrice.toStringAsFixed(0)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        if (auction.timeRemaining != null)
                          Text(auction.timeRemaining!, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(auction.suburb?.name ?? auction.town?.name ?? '', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                        ),
                        // Only show bid count when there's at least 1 bid
                        if (auction.totalBids > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gavel_rounded, size: 10, color: AppColors.textSecondaryLight),
                              const SizedBox(width: 2),
                              Text('${auction.totalBids}', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                            ],
                          ),
                      ],
                    ),
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
