import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme.dart';
import '../../data/data.dart';
import '../../core/network/websocket_service.dart';

/// Auction Detail Screen - Connected to Backend with Real-time Updates
class AuctionDetailScreen extends ConsumerStatefulWidget {
  final String auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  ConsumerState<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends ConsumerState<AuctionDetailScreen> {
  int _currentImageIndex = 0;
  final _bidController = TextEditingController();
  bool _isPlacingBid = false;
  StreamSubscription<BidUpdate>? _bidSubscription;
  StreamSubscription<BidUpdate>? _outbidSubscription;
  
  // Local state for real-time updates
  double? _livePrice;
  int? _liveBidCount;
  String? _liveTimeRemaining;
  
  // Store WebSocket manager reference for cleanup in dispose
  late final WebSocketManager _wsManager;

  @override
  void initState() {
    super.initState();
    _wsManager = ref.read(wsManagerProvider.notifier);
    _setupWebSocket();
  }
  
  void _setupWebSocket() {
    // Connect to WebSocket if not already connected
    _wsManager.connect();
    
    // Subscribe to this auction's updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wsManager.subscribeToAuction(widget.auctionId);
      _listenToBidUpdates();
    });
  }
  
  void _listenToBidUpdates() {
    final wsService = ref.read(wsServiceProvider);
    
    // Listen for bid updates on this auction
    _bidSubscription = wsService.bidUpdates
        .where((update) => update.auctionId == widget.auctionId)
        .listen((update) {
      setState(() {
        _livePrice = update.amount;
        _liveBidCount = update.totalBids;
        _liveTimeRemaining = update.timeRemaining;
      });
      
      // Refresh bid history
      ref.invalidate(bidHistoryProvider(widget.auctionId));
    });
    
    // Listen for outbid notifications
    _outbidSubscription = wsService.outbidNotifications
        .where((update) => update.auctionId == widget.auctionId)
        .listen((update) {
      _showOutbidNotification(update);
    });
  }
  
  void _showOutbidNotification(BidUpdate update) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('You\'ve been outbid! New bid: \$${update.amount.toStringAsFixed(2)}')),
          ],
        ),
        backgroundColor: AppColors.warning,
        action: SnackBarAction(
          label: 'Bid Again',
          textColor: Colors.white,
          onPressed: () => _bidController.text = (update.amount + 5).toStringAsFixed(0),
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _openFullScreenGallery(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: CachedNetworkImageProvider(images[index]),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    heroAttributes: PhotoViewHeroAttributes(tag: 'auction_image_${widget.auctionId}_$index'),
                  );
                },
                itemCount: images.length,
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                pageController: PageController(initialPage: initialIndex),
              ),
              Positioned(
                top: 50,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bidSubscription?.cancel();
    _outbidSubscription?.cancel();
    // Unsubscribe from auction when leaving (using stored reference)
    _wsManager.unsubscribeFromAuction(widget.auctionId);
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auctionAsync = ref.watch(auctionDetailProvider(widget.auctionId));
    
    return auctionAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        )),
        body: Center(child: Text('Error loading auction: $e')),
      ),
      data: (auction) => _buildContent(context, auction),
    );
  }

  Widget _buildContent(BuildContext context, Auction auction) {
    final bidHistoryAsync = ref.watch(bidHistoryProvider(widget.auctionId));
    final currentUser = ref.watch(currentUserProvider);
    final isSeller = currentUser?.id == auction.sellerId;
    
    // Use live values if available, otherwise use fetched auction data
    final displayPrice = _livePrice ?? auction.displayPrice;
    final displayBidCount = _liveBidCount ?? auction.totalBids;
    final displayTimeRemaining = _liveTimeRemaining ?? auction.timeRemaining;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildImageSection(auction)),
              SliverToBoxAdapter(child: _buildAuctionContent(auction, displayPrice, displayBidCount, displayTimeRemaining)),
              SliverToBoxAdapter(child: _buildSellerSection(auction)),
              SliverToBoxAdapter(
                child: bidHistoryAsync.when(
                  data: (bids) => _buildBidHistory(bids, currentUser?.id),
                  loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const Padding(padding: EdgeInsets.all(16), child: Text('Failed to load bid history')),
                ),
              ),
              // Add padding for bottom sheet - adjust based on whether user can bid
              // Bottom sheet height is approximately 180px when visible (including SafeArea)
              SliverToBoxAdapter(
                child: SizedBox(height: isSeller ? 24 : 180),
              ),
            ],
          ),
          if (!isSeller)
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBidFooter(auction)),
        ],
      ),
    );
  }

  Widget _buildImageSection(Auction auction) {
    final images = auction.images.isNotEmpty ? auction.images : [''];
    final watchlistState = ref.watch(watchlistProvider);
    final isInWatchlist = watchlistState.auctions.any((a) => a.id == auction.id);

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openFullScreenGallery(context, images, i),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                ),
                child: images[i].isNotEmpty
                    ? Hero(
                        tag: 'auction_image_${widget.auctionId}_$i',
                        child: CachedNetworkImage(
                          imageUrl: images[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => Icon(Icons.broken_image, size: 64, color: Colors.grey.shade400),
                        ),
                      )
                    : Icon(Icons.image, size: 64, color: Colors.grey.shade400),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(Icons.arrow_back, () {
                      // Try to pop, fall back to home if no back stack
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    }),
                    Row(children: [
                      GestureDetector(
                        onTap: () => _toggleWatchlist(auction, isInWatchlist),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
                          child: Icon(
                            isInWatchlist ? Icons.favorite : Icons.favorite_border,
                            color: isInWatchlist ? AppColors.error : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CircleButton(Icons.share, () {}),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 24, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentImageIndex ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentImageIndex ? AppColors.primary : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuctionContent(Auction auction, double displayPrice, int displayBidCount, String? displayTimeRemaining) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location - consistent font size
          Text(
            '${auction.town?.name ?? ''}${auction.suburb != null ? ' • ${auction.suburb!.name}' : ''}${auction.category != null ? ' • ${auction.category!.name}' : ''}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 12),
          Text(auction.title, style: AppTypography.headlineMedium),
          const SizedBox(height: 20),
          
          // Price and status - simplified design
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      if (auction.status == AuctionStatus.active) ...[
                        Container(width: 6, height: 6, decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        )),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      '\$${displayPrice.toStringAsFixed(2)}',
                      style: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimaryLight),
                    ),
                    const SizedBox(height: 4),
                    Text('$displayBidCount bids', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                  ]),
                ),
                if (displayTimeRemaining != null && displayTimeRemaining.isNotEmpty)
                  Column(children: [
                    Icon(Icons.access_time, color: AppColors.textSecondaryLight, size: 20),
                    const SizedBox(height: 4),
                    Text(displayTimeRemaining, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                  ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Condition and shipping - simplified
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(auction.condition, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimaryLight)),
              ),
              if (auction.shippingAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_shipping, size: 14, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text('Shipping', style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimaryLight)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Description', style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text(auction.description ?? 'No description provided.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _buildSellerSection(Auction auction) {
    final seller = auction.seller;
    if (seller == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: seller.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(imageUrl: seller.avatarUrl!, fit: BoxFit.cover),
                    )
                  : Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(seller.fullName, style: AppTypography.titleMedium),
                Text(seller.homeTown?.name ?? '', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
              ]),
            ),
            TextButton(
              onPressed: () => context.push('/user/${seller.id}'),
              child: Text('View Profile', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBidHistory(List<Bid> bids, String? currentUserId) {
    if (bids.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bid History', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No bids yet. Be the first!', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight)),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bid History', style: AppTypography.titleLarge),
          const SizedBox(height: 16),
          ...bids.take(5).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final bid = entry.value;
            final isHighest = i == 0;
            final isCurrentUser = bid.bidderId == currentUserId;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isHighest ? AppColors.primary : AppColors.borderLight,
                  width: isHighest ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(children: [
                      if (isHighest) ...[
                        Icon(Icons.emoji_events, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                      ],
                      Text(bid.bidder?.fullName ?? 'Anonymous', style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isHighest ? FontWeight.w600 : FontWeight.w400,
                      )),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('You', style: AppTypography.labelSmall.copyWith(color: Colors.white)),
                        ),
                      ],
                    ]),
                  ),
                  Text('\$${bid.amount.toStringAsFixed(2)}', style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: isHighest ? FontWeight.w700 : FontWeight.w400,
                  )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBidFooter(Auction auction) {
    // Server calculates the ONLY valid next bid - we just display it
    final nextBid = auction.minNextBid > 0 ? auction.minNextBid : auction.displayPrice + auction.bidIncrement;
    final increment = auction.bidIncrement;
    final currentPrice = auction.displayPrice;
    
    // Check if user can bid
    final isEnded = auction.status == AuctionStatus.ended || auction.status == AuctionStatus.sold;
    final isUserHighBidder = auction.userIsHighBidder;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price info row - simplified
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Bid', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                    Text('\$${currentPrice.toStringAsFixed(2)}', style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryLight)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Next Bid', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight)),
                    Text('\$${nextBid.toStringAsFixed(2)}', style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimaryLight)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action row
            if (isEnded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Auction Ended',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondaryLight),
                ),
              )
            else if (isUserHighBidder)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text('You\'re the highest bidder!', style: AppTypography.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              // THE CRITICAL "BID +$X" BUTTON - NO FREE-FORM INPUT!
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPlacingBid ? null : () => _placeTieredBid(auction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isPlacingBid
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Bid +\$${increment.toStringAsFixed(increment == increment.truncate() ? 0 : 2)}',
                              style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '\$${nextBid.toStringAsFixed(2)}',
                                style: AppTypography.bodySmall.copyWith(color: Colors.white),
                              ),
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

  void _toggleWatchlist(Auction auction, bool isInWatchlist) {
    final watchlist = ref.read(watchlistProvider.notifier);
    if (isInWatchlist) {
      watchlist.removeFromWatchlist(auction.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed from watchlist'), duration: Duration(seconds: 2)),
      );
    } else {
      watchlist.addToWatchlist(auction.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to watchlist'), duration: Duration(seconds: 2)),
      );
    }
  }

  /// Place bid with TIERED INCREMENT - server determines exact amount
  /// Client does NOT send a custom amount - the server calculates it!
  void _placeTieredBid(Auction auction) async {
    setState(() => _isPlacingBid = true);
    
    try {
      final repository = ref.read(auctionRepositoryProvider);
      
      // Send the expected next bid amount (server will validate/recalculate)
      final nextBid = auction.minNextBid > 0 ? auction.minNextBid : auction.displayPrice + auction.bidIncrement;
      final result = await repository.placeBid(auction.id, nextBid);
      
      // Refresh auction detail to get new price
      ref.invalidate(auctionDetailProvider(widget.auctionId));
      ref.invalidate(bidHistoryProvider(widget.auctionId));
      
      if (mounted) {
        // Show success with animation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bid placed successfully!'),
                      Text('You bid \$${result.newPrice?.toStringAsFixed(2) ?? nextBid.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Check if time was extended (anti-sniping)
        if (result.timeExtended) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.timer, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Auction extended! Anti-sniping activated.'),
                ],
              ),
              backgroundColor: AppColors.info,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Parse specific error codes
        if (errorMessage.contains('AUCTION_ENDED')) {
          errorMessage = 'This auction has ended';
        } else if (errorMessage.contains('SELF_BID_FORBIDDEN')) {
          errorMessage = 'You cannot bid on your own auction';
        } else if (errorMessage.contains('AUCTION_NOT_ACTIVE')) {
          errorMessage = 'This auction is no longer active';
        } else {
          errorMessage = 'Failed to place bid. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingBid = false);
    }
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.textPrimaryLight),
      ),
    );
  }
}
