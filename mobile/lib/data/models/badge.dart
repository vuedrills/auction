import 'package:flutter/material.dart';

/// Badge model
class Badge {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String icon;
  final String category;
  final int priority;
  final bool isActive;
  final DateTime createdAt;

  Badge({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.category,
    required this.priority,
    required this.isActive,
    required this.createdAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'star',
      category: json['category'] ?? 'other',
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Get Flutter icon from icon name
  IconData get iconData {
    switch (icon) {
      case 'verified_user':
        return Icons.verified_user;
      case 'phone_android':
        return Icons.phone_android;
      case 'mark_email_read':
        return Icons.mark_email_read;
      case 'sell':
        return Icons.sell;
      case 'thumb_up':
        return Icons.thumb_up;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'diamond':
        return Icons.diamond;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'payments':
        return Icons.payments;
      case 'history':
        return Icons.history;
      case 'cake':
        return Icons.cake;
      case 'star':
        return Icons.star;
      case 'military_tech':
        return Icons.military_tech;
      case 'public':
        return Icons.public;
      case 'storefront':
        return Icons.storefront;
      case 'gavel':
        return Icons.gavel;
      case 'visibility':
        return Icons.visibility;
      default:
        return Icons.verified;
    }
  }

  /// Get badge color based on category
  Color get color {
    switch (category) {
      case 'trust':
        return const Color(0xFF2196F3); // Blue
      case 'seller':
        return const Color(0xFF4CAF50); // Green
      case 'buyer':
        return const Color(0xFFFF9800); // Orange
      case 'community':
        return const Color(0xFF9C27B0); // Purple
      case 'activity':
        return const Color(0xFF607D8B); // Blue Grey
      default:
        return const Color(0xFF757575); // Grey
    }
  }
}

/// User's badge (with earned date)
class UserBadge {
  final String id;
  final String oderId;
  final String badgeId;
  final DateTime earnedAt;
  final DateTime? expiresAt;
  final Badge? badge;

  UserBadge({
    required this.id,
    required this.oderId,
    required this.badgeId,
    required this.earnedAt,
    this.expiresAt,
    this.badge,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] ?? '',
      oderId: json['user_id'] ?? '',
      badgeId: json['badge_id'] ?? '',
      earnedAt: DateTime.tryParse(json['earned_at'] ?? '') ?? DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      badge: json['badge'] != null ? Badge.fromJson(json['badge']) : null,
    );
  }
}

/// Verification status
class VerificationStatus {
  final bool isVerified;
  final bool pendingRequest;
  final String status;
  final DateTime? submittedAt;

  VerificationStatus({
    required this.isVerified,
    required this.pendingRequest,
    required this.status,
    this.submittedAt,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      isVerified: json['is_verified'] ?? false,
      pendingRequest: json['pending_request'] ?? false,
      status: json['status'] ?? 'not_submitted',
      submittedAt: json['submitted_at'] != null ? DateTime.tryParse(json['submitted_at']) : null,
    );
  }
}
