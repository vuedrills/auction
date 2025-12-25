import 'package:flutter/material.dart' hide Badge;
import '../../data/models/badge.dart';
import '../../app/theme.dart';

/// Widget to display a single badge
class BadgeChip extends StatelessWidget {
  final Badge badge;
  final bool showLabel;
  final double size;

  const BadgeChip({
    super.key,
    required this.badge,
    this.showLabel = true,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showLabel ? 8 : 4,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: badge.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(showLabel ? 12 : 8),
          border: Border.all(color: badge.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badge.iconData, size: size * 0.7, color: badge.color),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                badge.displayName,
                style: AppTypography.labelSmall.copyWith(
                  color: badge.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget to display a row of user badges
class BadgeRow extends StatelessWidget {
  final List<UserBadge> badges;
  final int maxDisplay;
  final bool showLabels;
  final VoidCallback? onSeeAll;

  const BadgeRow({
    super.key,
    required this.badges,
    this.maxDisplay = 3,
    this.showLabels = false,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    final displayBadges = badges.take(maxDisplay).toList();
    final remaining = badges.length - displayBadges.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayBadges.map((ub) {
          if (ub.badge == null) return const SizedBox.shrink();
          return BadgeChip(badge: ub.badge!, showLabel: showLabels);
        }),
        if (remaining > 0)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$remaining',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondaryLight),
              ),
            ),
          ),
      ],
    );
  }
}

/// Full badge showcase widget (for profile pages)
class BadgeShowcase extends StatelessWidget {
  final List<UserBadge> badges;
  final VoidCallback? onGetVerified;

  const BadgeShowcase({
    super.key,
    required this.badges,
    this.onGetVerified,
  });

  @override
  Widget build(BuildContext context) {
    // Check if user has ID verified badge
    final hasIdVerified = badges.any((b) => b.badge?.name == 'id_verified');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.verified, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Badges', style: AppTypography.titleSmall),
              const Spacer(),
              if (badges.isNotEmpty)
                Text(
                  '${badges.length} earned',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (badges.isEmpty)
            _buildEmptyState(context, hasIdVerified)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges.map((ub) {
                if (ub.badge == null) return const SizedBox.shrink();
                return BadgeChip(badge: ub.badge!, showLabel: true);
              }).toList(),
            ),
          if (!hasIdVerified && onGetVerified != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onGetVerified,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get Verified',
                            style: AppTypography.labelMedium.copyWith(color: Colors.blue.shade700),
                          ),
                          Text(
                            'Build trust with ID verification',
                            style: AppTypography.bodySmall.copyWith(color: Colors.blue.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue.shade700),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasIdVerified) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'No badges yet',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
          ),
          Text(
            'Complete activities to earn badges',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

/// Compact badge indicator (for listings, search results)
class BadgeIndicator extends StatelessWidget {
  final bool isVerified;
  final bool isTrustedSeller;
  final bool isPowerSeller;

  const BadgeIndicator({
    super.key,
    this.isVerified = false,
    this.isTrustedSeller = false,
    this.isPowerSeller = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified && !isTrustedSeller && !isPowerSeller) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isVerified)
          const Tooltip(
            message: 'ID Verified',
            child: Icon(Icons.verified_user, size: 16, color: Color(0xFF2196F3)),
          ),
        if (isTrustedSeller) ...[
          if (isVerified) const SizedBox(width: 4),
          const Tooltip(
            message: 'Trusted Seller',
            child: Icon(Icons.thumb_up, size: 16, color: Color(0xFF4CAF50)),
          ),
        ],
        if (isPowerSeller) ...[
          if (isVerified || isTrustedSeller) const SizedBox(width: 4),
          const Tooltip(
            message: 'Power Seller',
            child: Icon(Icons.diamond, size: 16, color: Color(0xFFFF9800)),
          ),
        ],
      ],
    );
  }
}
