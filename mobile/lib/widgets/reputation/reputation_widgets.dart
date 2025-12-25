import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../data/data.dart';

/// Seller badge widget showing reputation level
class SellerBadge extends StatelessWidget {
  final String badgeLevel;
  final bool showLabel;
  final double size;

  const SellerBadge({
    super.key,
    required this.badgeLevel,
    this.showLabel = false,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeLevel == 'none') return const SizedBox.shrink();

    final (color, icon, label) = switch (badgeLevel) {
      'gold' => (const Color(0xFFFFD700), Icons.military_tech, 'Gold Seller'),
      'silver' => (const Color(0xFFC0C0C0), Icons.military_tech, 'Silver Seller'),
      'bronze' => (const Color(0xFFCD7F32), Icons.military_tech, 'Bronze Seller'),
      _ => (Colors.grey, Icons.person, 'Seller'),
    };

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: size),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

/// Verification badges row
class VerificationBadges extends StatelessWidget {
  final bool isVerified;
  final bool isTrustedSeller;
  final bool isFastResponder;
  final bool compact;

  const VerificationBadges({
    super.key,
    this.isVerified = false,
    this.isTrustedSeller = false,
    this.isFastResponder = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (isVerified) {
      badges.add(_buildBadge(
        icon: Icons.verified,
        label: 'Verified',
        color: AppColors.info,
        compact: compact,
      ));
    }

    if (isTrustedSeller) {
      badges.add(_buildBadge(
        icon: Icons.shield,
        label: 'Trusted',
        color: AppColors.success,
        compact: compact,
      ));
    }

    if (isFastResponder) {
      badges.add(_buildBadge(
        icon: Icons.flash_on,
        label: 'Fast',
        color: AppColors.warning,
        compact: compact,
      ));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges,
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool compact,
  }) {
    if (compact) {
      return Tooltip(
        message: label,
        child: Icon(icon, color: color, size: 16),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 2),
          Text(label, style: AppTypography.labelSmall.copyWith(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

/// Star rating display
class StarRating extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final double starSize;
  final bool showCount;

  const StarRating({
    super.key,
    required this.rating,
    this.ratingCount = 0,
    this.starSize = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final starValue = i + 1;
          IconData icon;
          Color color;

          if (rating >= starValue) {
            icon = Icons.star;
            color = AppColors.warning;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
            color = AppColors.warning;
          } else {
            icon = Icons.star_border;
            color = Colors.grey.shade400;
          }

          return Icon(icon, size: starSize, color: color);
        }),
        if (showCount && ratingCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($ratingCount)',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight),
          ),
        ],
      ],
    );
  }
}

/// Complete seller reputation card
class SellerReputationCard extends ConsumerWidget {
  final String userId;
  final bool compact;

  const SellerReputationCard({
    super.key,
    required this.userId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reputationAsync = ref.watch(userReputationProvider(userId));

    return reputationAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (rep) => _buildCard(context, rep),
    );
  }

  Widget _buildCard(BuildContext context, UserReputation rep) {
    if (compact) {
      return Row(
        children: [
          SellerBadge(badgeLevel: rep.badgeLevel, size: 16),
          const SizedBox(width: 8),
          StarRating(rating: rep.rating, ratingCount: rep.ratingCount, starSize: 14),
          if (rep.isVerified) ...[
            const SizedBox(width: 4),
            Icon(Icons.verified, color: AppColors.info, size: 14),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: rep.avatarUrl != null ? NetworkImage(rep.avatarUrl!) : null,
                child: rep.avatarUrl == null
                    ? Text(rep.username.isNotEmpty ? rep.username[0].toUpperCase() : '?',
                        style: AppTypography.titleLarge.copyWith(color: AppColors.primary))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rep.fullName.isNotEmpty ? rep.fullName : rep.username,
                            style: AppTypography.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SellerBadge(badgeLevel: rep.badgeLevel, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    StarRating(rating: rep.rating, ratingCount: rep.ratingCount, starSize: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          VerificationBadges(
            isVerified: rep.isVerified,
            isTrustedSeller: rep.isTrustedSeller,
            isFastResponder: rep.isFastResponder,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStat('Sales', rep.completedAuctions.toString()),
              Container(width: 1, height: 20, color: Colors.grey.shade300),
              _buildStat('Completion', '${rep.completionRate.toStringAsFixed(0)}%'),
              Container(width: 1, height: 20, color: Colors.grey.shade300),
              _buildStat('Member', _formatMemberSince(rep.memberSince)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.titleSmall.copyWith(color: AppColors.primary)),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }

  String _formatMemberSince(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 30) return '${diff.inDays}d';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo';
    return '${diff.inDays ~/ 365}y';
  }
}

/// Auto-bid setup bottom sheet
class AutoBidSheet extends ConsumerStatefulWidget {
  final Auction auction;

  const AutoBidSheet({super.key, required this.auction});

  @override
  ConsumerState<AutoBidSheet> createState() => _AutoBidSheetState();
}

class _AutoBidSheetState extends ConsumerState<AutoBidSheet> {
  final _maxBidController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default to 20% above next bid
    final nextBid = widget.auction.minNextBid > 0
        ? widget.auction.minNextBid
        : widget.auction.displayPrice + widget.auction.bidIncrement;
    _maxBidController.text = (nextBid * 1.2).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _maxBidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice = widget.auction.displayPrice;
    final nextBid = widget.auction.minNextBid > 0
        ? widget.auction.minNextBid
        : currentPrice + widget.auction.bidIncrement;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Set Auto-Bid', style: AppTypography.headlineSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Auto-bid will automatically place bids for you up to your maximum amount using the tiered increment system.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Bid', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                    Text('\$${currentPrice.toStringAsFixed(2)}', style: AppTypography.titleMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Next Bid', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
                    Text('\$${nextBid.toStringAsFixed(2)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Your Maximum Bid', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _maxBidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '\$ ',
              hintText: 'Enter max amount',
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              helperText: 'Minimum: \$${nextBid.toStringAsFixed(2)}',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAutoBid,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Enable Auto-Bid', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAutoBid() async {
    final maxAmount = double.tryParse(_maxBidController.text);
    if (maxAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final nextBid = widget.auction.minNextBid > 0
        ? widget.auction.minNextBid
        : widget.auction.displayPrice + widget.auction.bidIncrement;

    if (maxAmount < nextBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum must be at least \$${nextBid.toStringAsFixed(2)}')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ref.read(autoBidNotifierProvider.notifier).setAutoBid(
            widget.auction.id,
            maxAmount,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.isHighBidder
                ? 'Auto-bid set! You\'re the highest bidder.'
                : 'Auto-bid set! Will bid automatically when outbid.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set auto-bid: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

/// Town leaderboard widget
class TownLeaderboardWidget extends ConsumerWidget {
  final String townId;
  final String type;
  final String period;

  const TownLeaderboardWidget({
    super.key,
    required this.townId,
    this.type = 'top_sellers',
    this.period = 'monthly',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(townLeaderboardProvider((
      townId: townId,
      type: type,
      period: period,
    )));

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (lb) => _buildLeaderboard(context, lb),
    );
  }

  Widget _buildLeaderboard(BuildContext context, TownLeaderboard lb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(_getTitle(type), style: AppTypography.titleLarge),
            ],
          ),
        ),
        ...lb.entries.take(10).map((entry) => _buildEntry(context, entry)),
      ],
    );
  }

  String _getTitle(String type) {
    switch (type) {
      case 'top_sellers':
        return 'Top Sellers';
      case 'highest_rated':
        return 'Highest Rated';
      case 'most_active':
        return 'Most Active';
      default:
        return 'Leaderboard';
    }
  }

  Widget _buildEntry(BuildContext context, LeaderboardEntry entry) {
    final isTop3 = entry.rank <= 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.warning.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isTop3 ? Border.all(color: AppColors.warning.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              entry.rank <= 3 ? ['🥇', '🥈', '🥉'][entry.rank - 1] : '#${entry.rank}',
              style: AppTypography.titleMedium,
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(entry.fullName, style: AppTypography.titleSmall, overflow: TextOverflow.ellipsis)),
                    if (entry.badgeLevel != 'none') ...[
                      const SizedBox(width: 4),
                      Text(entry.badgeEmoji, style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
                Text('@${entry.username}', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
          Text(entry.metricValue.toString(), style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}
