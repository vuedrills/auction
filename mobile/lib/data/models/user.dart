/// User model
class User {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final bool isVerified;
  final bool isActive;
  final String? homeTownId;
  final String? homeSuburbId;
  final DateTime? lastTownChange;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Town? homeTown;
  final Suburb? homeSuburb;
  
  // Reputation fields
  final double rating;
  final int ratingCount;
  final int completedAuctions;
  final double totalSales;
  final bool isTrustedSeller;
  final List<String> badges;
  final DateTime? memberSince;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.isVerified = false,
    this.isActive = true,
    this.homeTownId,
    this.homeSuburbId,
    this.lastTownChange,
    required this.createdAt,
    required this.updatedAt,
    this.homeTown,
    this.homeSuburb,
    this.rating = 0,
    this.ratingCount = 0,
    this.completedAuctions = 0,
    this.totalSales = 0,
    this.isTrustedSeller = false,
    this.badges = const [],
    this.memberSince,
  });

  /// Calculate star rating display (e.g., "4.5")
  String get ratingDisplay => rating.toStringAsFixed(1);
  
  /// Check if user is a top seller (rating >= 4.5 and completed >= 10)
  bool get isTopSeller => rating >= 4.5 && completedAuctions >= 10;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      username: json['username'] as String,
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      homeTownId: json['home_town_id'] as String?,
      homeSuburbId: json['home_suburb_id'] as String?,
      lastTownChange: json['last_town_change'] != null 
          ? DateTime.parse(json['last_town_change'] as String) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
      homeTown: json['home_town'] != null 
          ? Town.fromJson(json['home_town'] as Map<String, dynamic>) 
          : null,
      homeSuburb: json['home_suburb'] != null 
          ? Suburb.fromJson(json['home_suburb'] as Map<String, dynamic>) 
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      completedAuctions: json['completed_auctions'] as int? ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0,
      isTrustedSeller: json['is_trusted_seller'] as bool? ?? false,
      badges: json['badges'] != null ? List<String>.from(json['badges'] as List) : [],
      memberSince: json['member_since'] != null 
          ? DateTime.parse(json['member_since'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'is_verified': isVerified,
      'is_active': isActive,
      'home_town_id': homeTownId,
      'home_suburb_id': homeSuburbId,
      'last_town_change': lastTownChange?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'rating': rating,
      'rating_count': ratingCount,
      'completed_auctions': completedAuctions,
      'total_sales': totalSales,
      'is_trusted_seller': isTrustedSeller,
      'badges': badges,
      'member_since': memberSince?.toIso8601String(),
    };
  }
}

/// Town model
class Town {
  final String id;
  final String name;
  final String? state;
  final String country;
  final String? timezone;
  final int activeAuctions;
  final int totalSuburbs;
  final List<Suburb>? suburbs;

  Town({
    required this.id,
    required this.name,
    this.state,
    required this.country,
    this.timezone,
    this.activeAuctions = 0,
    this.totalSuburbs = 0,
    this.suburbs,
  });

  factory Town.fromJson(Map<String, dynamic> json) {
    return Town(
      id: json['id'] as String,
      name: json['name'] as String,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'Zimbabwe',
      timezone: json['timezone'] as String?,
      activeAuctions: json['active_auctions'] as int? ?? 0,
      totalSuburbs: json['total_suburbs'] as int? ?? 0,
      suburbs: json['suburbs'] != null
          ? (json['suburbs'] as List).map((s) => Suburb.fromJson(s as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'country': country,
      'timezone': timezone,
      'active_auctions': activeAuctions,
      'total_suburbs': totalSuburbs,
    };
  }
}

/// Suburb model
class Suburb {
  final String id;
  final String name;
  final String? zipCode;
  final String townId;
  final int activeAuctions;
  final int endingSoon;
  final String? townName;

  Suburb({
    required this.id,
    required this.name,
    this.zipCode,
    required this.townId,
    this.activeAuctions = 0,
    this.endingSoon = 0,
    this.townName,
  });

  factory Suburb.fromJson(Map<String, dynamic> json) {
    return Suburb(
      id: json['id'] as String,
      name: json['name'] as String,
      zipCode: json['zip_code'] as String?,
      townId: json['town_id'] as String,
      activeAuctions: json['active_auctions'] as int? ?? 0,
      endingSoon: json['ending_soon'] as int? ?? 0,
      townName: json['town_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'zip_code': zipCode,
      'town_id': townId,
      'active_auctions': activeAuctions,
      'ending_soon': endingSoon,
    };
  }
}

/// Auth response model
class AuthResponse {
  final String token;
  final int expiresAt;
  final User user;

  AuthResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      expiresAt: json['expires_at'] as int,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
