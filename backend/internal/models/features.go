package models

import (
	"time"

	"github.com/google/uuid"
)

// =============================================================================
// AUTO-BID MODELS
// =============================================================================

// AutoBid represents an auto-bid configuration
type AutoBid struct {
	ID                 uuid.UUID  `json:"id"`
	AuctionID          uuid.UUID  `json:"auction_id"`
	UserID             uuid.UUID  `json:"user_id"`
	MaxAmount          float64    `json:"max_amount"`
	CurrentBidAmount   *float64   `json:"current_bid_amount,omitempty"`
	IsActive           bool       `json:"is_active"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
	DeactivatedAt      *time.Time `json:"deactivated_at,omitempty"`
	DeactivationReason *string    `json:"deactivation_reason,omitempty"`
}

// CreateAutoBidRequest for setting up auto-bid
type CreateAutoBidRequest struct {
	MaxAmount float64 `json:"max_amount" binding:"required,min=0.01"`
}

// AutoBidResponse after creating/updating auto-bid
type AutoBidResponse struct {
	AutoBid      *AutoBid `json:"auto_bid"`
	Message      string   `json:"message"`
	CurrentBid   float64  `json:"current_bid"`
	NextBid      float64  `json:"next_bid"`
	BidsPlaced   int      `json:"bids_placed"`
	IsHighBidder bool     `json:"is_high_bidder"`
}

// =============================================================================
// SAVED SEARCH & ALERT MODELS
// =============================================================================

// SavedSearch represents a user's saved search
type SavedSearch struct {
	ID                uuid.UUID  `json:"id"`
	UserID            uuid.UUID  `json:"user_id"`
	Name              string     `json:"name"`
	SearchQuery       *string    `json:"search_query,omitempty"`
	CategoryID        *uuid.UUID `json:"category_id,omitempty"`
	TownID            *uuid.UUID `json:"town_id,omitempty"`
	MinPrice          *float64   `json:"min_price,omitempty"`
	MaxPrice          *float64   `json:"max_price,omitempty"`
	Keywords          []string   `json:"keywords,omitempty"`
	Condition         *string    `json:"condition,omitempty"`
	NotifyNewListings bool       `json:"notify_new_listings"`
	NotifyPriceDrops  bool       `json:"notify_price_drops"`
	NotifyEmail       bool       `json:"notify_email"`
	NotifyPush        bool       `json:"notify_push"`
	MatchCount        int        `json:"match_count"`
	IsActive          bool       `json:"is_active"`
	LastNotifiedAt    *time.Time `json:"last_notified_at,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`

	// Joined
	Category *Category `json:"category,omitempty"`
	Town     *Town     `json:"town,omitempty"`
}

// CreateSavedSearchRequest for saving a search
type CreateSavedSearchRequest struct {
	Name              string     `json:"name" binding:"required,min=1,max=100"`
	SearchQuery       *string    `json:"search_query"`
	CategoryID        *uuid.UUID `json:"category_id"`
	TownID            *uuid.UUID `json:"town_id"`
	MinPrice          *float64   `json:"min_price"`
	MaxPrice          *float64   `json:"max_price"`
	Keywords          []string   `json:"keywords"`
	Condition         *string    `json:"condition"`
	NotifyNewListings bool       `json:"notify_new_listings"`
	NotifyPriceDrops  bool       `json:"notify_price_drops"`
	NotifyEmail       bool       `json:"notify_email"`
	NotifyPush        bool       `json:"notify_push"`
}

// SearchAlert represents a notification for a saved search match
type SearchAlert struct {
	ID            uuid.UUID `json:"id"`
	SavedSearchID uuid.UUID `json:"saved_search_id"`
	AuctionID     uuid.UUID `json:"auction_id"`
	UserID        uuid.UUID `json:"user_id"`
	AlertType     string    `json:"alert_type"` // new_match, price_drop
	WasRead       bool      `json:"was_read"`
	CreatedAt     time.Time `json:"created_at"`

	// Joined
	Auction *Auction `json:"auction,omitempty"`
}

// =============================================================================
// PROMOTION MODELS
// =============================================================================

// PromotedAuction represents a boosted auction
type PromotedAuction struct {
	ID              uuid.UUID  `json:"id"`
	AuctionID       uuid.UUID  `json:"auction_id"`
	UserID          uuid.UUID  `json:"user_id"`
	PromotionType   string     `json:"promotion_type"` // featured, boosted, pinned, highlighted
	TownID          *uuid.UUID `json:"town_id,omitempty"`
	StartsAt        time.Time  `json:"starts_at"`
	EndsAt          time.Time  `json:"ends_at"`
	AmountPaid      float64    `json:"amount_paid"`
	IsActive        bool       `json:"is_active"`
	Impressions     int        `json:"impressions"`
	Clicks          int        `json:"clicks"`
	BoostMultiplier float64    `json:"boost_multiplier"`
	PaymentStatus   string     `json:"payment_status"`
	CreatedAt       time.Time  `json:"created_at"`
}

// PromotionPricing represents available promotion options
type PromotionPricing struct {
	ID              uuid.UUID  `json:"id"`
	Name            string     `json:"name"`
	PromotionType   string     `json:"promotion_type"`
	DurationHours   int        `json:"duration_hours"`
	Price           float64    `json:"price"`
	BoostMultiplier float64    `json:"boost_multiplier"`
	Description     string     `json:"description"`
	IsActive        bool       `json:"is_active"`
	TownID          *uuid.UUID `json:"town_id,omitempty"`
}

// CreatePromotionRequest for promoting an auction
type CreatePromotionRequest struct {
	PricingID uuid.UUID `json:"pricing_id" binding:"required"`
}

// PromotionResponse after creating promotion
type PromotionResponse struct {
	Promotion *PromotedAuction `json:"promotion"`
	Message   string           `json:"message"`
	ExpiresAt time.Time        `json:"expires_at"`
}

// =============================================================================
// SLOT PURCHASE MODELS
// =============================================================================

// SlotPurchase represents a queue skip purchase
type SlotPurchase struct {
	ID                   uuid.UUID  `json:"id"`
	UserID               uuid.UUID  `json:"user_id"`
	CategoryID           uuid.UUID  `json:"category_id"`
	TownID               uuid.UUID  `json:"town_id"`
	AuctionID            *uuid.UUID `json:"auction_id,omitempty"`
	AmountPaid           float64    `json:"amount_paid"`
	OriginalWaitPosition int        `json:"original_wait_position"`
	PurchaseType         string     `json:"purchase_type"` // skip_queue, extra_slot
	Status               string     `json:"status"`        // pending, completed, refunded
	CreatedAt            time.Time  `json:"created_at"`
	ProcessedAt          *time.Time `json:"processed_at,omitempty"`
}

// SlotPricing for category queues
type SlotPricing struct {
	ID             uuid.UUID `json:"id"`
	CategoryID     uuid.UUID `json:"category_id"`
	TownID         uuid.UUID `json:"town_id"`
	SkipQueuePrice float64   `json:"skip_queue_price"`
	ExtraSlotPrice float64   `json:"extra_slot_price"`
	IsActive       bool      `json:"is_active"`

	// Joined
	Category *Category `json:"category,omitempty"`
	Town     *Town     `json:"town,omitempty"`
}

// =============================================================================
// REPUTATION & USER EXTENSION MODELS
// =============================================================================

// UserReputation extended user info
type UserReputation struct {
	UserID                 uuid.UUID `json:"user_id"`
	Username               string    `json:"username"`
	FullName               string    `json:"full_name"`
	AvatarURL              *string   `json:"avatar_url,omitempty"`
	Rating                 float64   `json:"rating"`
	RatingCount            int       `json:"rating_count"`
	CompletedAuctions      int       `json:"completed_auctions"`
	BadgeLevel             string    `json:"badge_level"` // none, bronze, silver, gold
	IsTrustedSeller        bool      `json:"is_trusted_seller"`
	IsVerified             bool      `json:"is_verified"`
	IsFastResponder        bool      `json:"is_fast_responder"`
	CompletionRate         float64   `json:"completion_rate"` // % without disputes
	TotalTransactions      int       `json:"total_transactions"`
	SuccessfulTransactions int       `json:"successful_transactions"`
	MemberSince            time.Time `json:"member_since"`
	Badges                 []string  `json:"badges"`
}

// UserRating represents a review
type UserRating struct {
	ID                  uuid.UUID  `json:"id"`
	RaterID             uuid.UUID  `json:"rater_id"`
	RatedUserID         uuid.UUID  `json:"rated_user_id"`
	AuctionID           *uuid.UUID `json:"auction_id,omitempty"`
	Rating              int        `json:"rating"` // 1-5
	CommunicationRating *int       `json:"communication_rating,omitempty"`
	AccuracyRating      *int       `json:"accuracy_rating,omitempty"`
	SpeedRating         *int       `json:"speed_rating,omitempty"`
	Review              *string    `json:"review,omitempty"`
	Role                string     `json:"role"` // buyer, seller
	WouldRecommend      bool       `json:"would_recommend"`
	CreatedAt           time.Time  `json:"created_at"`

	// Joined
	Rater *User `json:"rater,omitempty"`
}

// CreateRatingRequest for rating a user
type CreateRatingRequest struct {
	Rating              int     `json:"rating" binding:"required,min=1,max=5"`
	CommunicationRating *int    `json:"communication_rating" binding:"omitempty,min=1,max=5"`
	AccuracyRating      *int    `json:"accuracy_rating" binding:"omitempty,min=1,max=5"`
	SpeedRating         *int    `json:"speed_rating" binding:"omitempty,min=1,max=5"`
	Review              *string `json:"review"`
	WouldRecommend      bool    `json:"would_recommend"`
}

// =============================================================================
// TOWN LEADERBOARD MODELS
// =============================================================================

// LeaderboardEntry for town rankings
type LeaderboardEntry struct {
	Rank        int       `json:"rank"`
	UserID      uuid.UUID `json:"user_id"`
	Username    string    `json:"username"`
	FullName    string    `json:"full_name"`
	AvatarURL   *string   `json:"avatar_url,omitempty"`
	BadgeLevel  string    `json:"badge_level"`
	Score       float64   `json:"score"`
	MetricValue int       `json:"metric_value"`
}

// TownLeaderboard contains leaderboard data
type TownLeaderboard struct {
	TownID          uuid.UUID          `json:"town_id"`
	TownName        string             `json:"town_name"`
	LeaderboardType string             `json:"leaderboard_type"`
	Period          string             `json:"period"`
	Entries         []LeaderboardEntry `json:"entries"`
	CalculatedAt    time.Time          `json:"calculated_at"`
}

// TownStats aggregated town statistics
type TownStats struct {
	TownID          uuid.UUID  `json:"town_id"`
	TownName        string     `json:"town_name"`
	ActiveAuctions  int        `json:"active_auctions"`
	TotalAuctions   int        `json:"total_auctions"`
	TotalUsers      int        `json:"total_users"`
	ActiveSellers   int        `json:"active_sellers"`
	TotalSalesValue float64    `json:"total_sales_value"`
	AvgAuctionPrice float64    `json:"avg_auction_price"`
	TopCategoryID   *uuid.UUID `json:"top_category_id,omitempty"`
	TopCategory     *Category  `json:"top_category,omitempty"`
	CalculatedAt    time.Time  `json:"calculated_at"`
}

// =============================================================================
// FRAUD DETECTION MODELS
// =============================================================================

// FraudSignal represents a detected suspicious activity
type FraudSignal struct {
	ID          uuid.UUID  `json:"id"`
	UserID      uuid.UUID  `json:"user_id"`
	AuctionID   *uuid.UUID `json:"auction_id,omitempty"`
	SignalType  string     `json:"signal_type"` // self_bidding, rapid_bids, ip_reuse, etc
	Severity    string     `json:"severity"`    // low, medium, high, critical
	Details     string     `json:"details"`     // JSON details
	ScoreImpact float64    `json:"score_impact"`
	IPAddress   *string    `json:"ip_address,omitempty"`
	IsReviewed  bool       `json:"is_reviewed"`
	ReviewedBy  *uuid.UUID `json:"reviewed_by,omitempty"`
	ReviewedAt  *time.Time `json:"reviewed_at,omitempty"`
	AutoFlagged bool       `json:"auto_flagged"`
	CreatedAt   time.Time  `json:"created_at"`
}

// UserBehaviorMetrics for fraud detection
type UserBehaviorMetrics struct {
	UserID              uuid.UUID `json:"user_id"`
	BidCancelRate       float64   `json:"bid_cancel_rate"`
	AvgBidTimeBeforeEnd *int      `json:"avg_bid_time_before_end_mins,omitempty"`
	SameIPBiddersCount  int       `json:"same_ip_bidders_count"`
	RapidBidCount       int       `json:"rapid_bid_count"`
	SelfBidAttempts     int       `json:"self_bid_attempts"`
	ShillBidProbability float64   `json:"shill_bid_probability"`
	AccountAgeDays      int       `json:"account_age_days"`
	RiskLevel           string    `json:"risk_level"` // low, medium, high, critical
	LastCalculatedAt    time.Time `json:"last_calculated_at"`
}
