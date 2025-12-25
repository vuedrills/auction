package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/middleware"
	"github.com/airmass/backend/internal/models"
	"github.com/airmass/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// FeaturesHandler handles advanced feature endpoints
type FeaturesHandler struct {
	db  *database.DB
	hub *websocket.Hub
}

// NewFeaturesHandler creates a new features handler
func NewFeaturesHandler(db *database.DB, hub *websocket.Hub) *FeaturesHandler {
	return &FeaturesHandler{db: db, hub: hub}
}

// =============================================================================
// AUTO-BID ENDPOINTS
// =============================================================================

// SetAutoBid creates or updates an auto-bid for an auction
func (h *FeaturesHandler) SetAutoBid(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	var req models.CreateAutoBidRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Start transaction
	tx, err := h.db.Pool.Begin(context.Background())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}
	defer tx.Rollback(context.Background())

	// Lock auction and validate
	var auction struct {
		SellerID      uuid.UUID
		CurrentPrice  *float64
		StartingPrice float64
		Status        string
		EndTime       *time.Time
	}
	err = tx.QueryRow(context.Background(),
		`SELECT seller_id, current_price, starting_price, status, end_time 
		 FROM auctions WHERE id = $1 FOR UPDATE`,
		auctionID,
	).Scan(&auction.SellerID, &auction.CurrentPrice, &auction.StartingPrice, &auction.Status, &auction.EndTime)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Auction not found"})
		return
	}

	// Validations
	if auction.SellerID == userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Cannot auto-bid on your own auction"})
		return
	}
	if auction.Status != "active" && auction.Status != "ending_soon" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Auction is not active"})
		return
	}
	if auction.EndTime != nil && time.Now().After(*auction.EndTime) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Auction has ended"})
		return
	}

	// Calculate current and next bid
	currentPrice := auction.StartingPrice
	if auction.CurrentPrice != nil {
		currentPrice = *auction.CurrentPrice
	}

	// Get tiered increment
	var increment float64
	tx.QueryRow(context.Background(), "SELECT get_bid_increment($1)", currentPrice).Scan(&increment)
	if increment == 0 {
		increment = 1.0 // fallback
	}
	nextBid := currentPrice + increment

	// Validate max amount is reasonable
	if req.MaxAmount < nextBid {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":    fmt.Sprintf("Max amount must be at least $%.2f (next valid bid)", nextBid),
			"next_bid": nextBid,
		})
		return
	}

	// Create or update auto-bid
	var autoBidID uuid.UUID
	err = tx.QueryRow(context.Background(),
		`INSERT INTO auto_bids (auction_id, user_id, max_amount, is_active)
		 VALUES ($1, $2, $3, true)
		 ON CONFLICT (auction_id, user_id) DO UPDATE SET
		   max_amount = EXCLUDED.max_amount,
		   is_active = true,
		   updated_at = NOW(),
		   deactivated_at = NULL,
		   deactivation_reason = NULL
		 RETURNING id`,
		auctionID, userID, req.MaxAmount,
	).Scan(&autoBidID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set auto-bid"})
		return
	}

	// Check if we're not currently the high bidder - if so, place a bid immediately
	var isHighBidder bool
	tx.QueryRow(context.Background(),
		`SELECT EXISTS(SELECT 1 FROM bids WHERE auction_id = $1 AND bidder_id = $2 AND is_winning = true)`,
		auctionID, userID,
	).Scan(&isHighBidder)

	bidsPlaced := 0
	if !isHighBidder {
		// Place initial bid
		_, err = tx.Exec(context.Background(),
			`INSERT INTO bids (auction_id, bidder_id, amount, is_auto_bid) VALUES ($1, $2, $3, true)`,
			auctionID, userID, nextBid,
		)
		if err == nil {
			bidsPlaced = 1
			currentPrice = nextBid
			isHighBidder = true

			// Update auto-bid current amount
			tx.Exec(context.Background(),
				`UPDATE auto_bids SET current_bid_amount = $1 WHERE id = $2`,
				nextBid, autoBidID,
			)
		}
	}

	if err = tx.Commit(context.Background()); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit"})
		return
	}

	// Recalculate next bid
	increment = h.getIncrement(currentPrice)
	nextBid = currentPrice + increment

	c.JSON(http.StatusOK, models.AutoBidResponse{
		AutoBid: &models.AutoBid{
			ID:        autoBidID,
			AuctionID: auctionID,
			UserID:    userID,
			MaxAmount: req.MaxAmount,
			IsActive:  true,
		},
		Message:      "Auto-bid configured successfully",
		CurrentBid:   currentPrice,
		NextBid:      nextBid,
		BidsPlaced:   bidsPlaced,
		IsHighBidder: isHighBidder,
	})
}

// GetMyAutoBids returns user's active auto-bids
func (h *FeaturesHandler) GetMyAutoBids(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT ab.id, ab.auction_id, ab.max_amount, ab.current_bid_amount, ab.is_active,
		        ab.created_at, ab.updated_at, ab.deactivation_reason,
		        a.title, a.current_price, a.starting_price, a.end_time
		 FROM auto_bids ab
		 JOIN auctions a ON ab.auction_id = a.id
		 WHERE ab.user_id = $1
		 ORDER BY ab.is_active DESC, ab.updated_at DESC`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch auto-bids"})
		return
	}
	defer rows.Close()

	type AutoBidWithAuction struct {
		models.AutoBid
		AuctionTitle  string     `json:"auction_title"`
		CurrentPrice  *float64   `json:"current_price"`
		StartingPrice float64    `json:"starting_price"`
		EndTime       *time.Time `json:"end_time"`
	}

	var autoBids []AutoBidWithAuction
	for rows.Next() {
		var ab AutoBidWithAuction
		rows.Scan(&ab.ID, &ab.AuctionID, &ab.MaxAmount, &ab.CurrentBidAmount, &ab.IsActive,
			&ab.CreatedAt, &ab.UpdatedAt, &ab.DeactivationReason,
			&ab.AuctionTitle, &ab.CurrentPrice, &ab.StartingPrice, &ab.EndTime)
		autoBids = append(autoBids, ab)
	}

	c.JSON(http.StatusOK, gin.H{"auto_bids": autoBids})
}

// CancelAutoBid deactivates an auto-bid
func (h *FeaturesHandler) CancelAutoBid(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	result, err := h.db.Pool.Exec(context.Background(),
		`UPDATE auto_bids SET is_active = false, deactivated_at = NOW(), deactivation_reason = 'user_cancelled'
		 WHERE auction_id = $1 AND user_id = $2 AND is_active = true`,
		auctionID, userID,
	)
	if err != nil || result.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active auto-bid found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Auto-bid cancelled"})
}

// =============================================================================
// SAVED SEARCHES ENDPOINTS
// =============================================================================

// CreateSavedSearch saves a search for alerts
func (h *FeaturesHandler) CreateSavedSearch(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	var req models.CreateSavedSearchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Limit saved searches per user
	var count int
	h.db.Pool.QueryRow(context.Background(),
		"SELECT COUNT(*) FROM saved_searches WHERE user_id = $1 AND is_active = true",
		userID,
	).Scan(&count)
	if count >= 10 {
		c.JSON(http.StatusConflict, gin.H{"error": "Maximum 10 saved searches allowed"})
		return
	}

	var searchID uuid.UUID
	err := h.db.Pool.QueryRow(context.Background(),
		`INSERT INTO saved_searches (
			user_id, name, search_query, category_id, town_id, min_price, max_price,
			keywords, condition, notify_new_listings, notify_price_drops, notify_email, notify_push
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
		RETURNING id`,
		userID, req.Name, req.SearchQuery, req.CategoryID, req.TownID, req.MinPrice, req.MaxPrice,
		req.Keywords, req.Condition, req.NotifyNewListings, req.NotifyPriceDrops, req.NotifyEmail, req.NotifyPush,
	).Scan(&searchID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save search"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":      searchID,
		"message": "Search saved successfully",
	})
}

// GetMySavedSearches returns user's saved searches
func (h *FeaturesHandler) GetMySavedSearches(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT ss.id, ss.name, ss.search_query, ss.category_id, ss.town_id,
		        ss.min_price, ss.max_price, ss.keywords, ss.condition,
		        ss.notify_new_listings, ss.notify_price_drops, ss.match_count,
		        ss.is_active, ss.created_at,
		        c.name as category_name, t.name as town_name
		 FROM saved_searches ss
		 LEFT JOIN categories c ON ss.category_id = c.id
		 LEFT JOIN towns t ON ss.town_id = t.id
		 WHERE ss.user_id = $1
		 ORDER BY ss.is_active DESC, ss.created_at DESC`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch saved searches"})
		return
	}
	defer rows.Close()

	var searches []models.SavedSearch
	for rows.Next() {
		var s models.SavedSearch
		var categoryName, townName *string
		rows.Scan(&s.ID, &s.Name, &s.SearchQuery, &s.CategoryID, &s.TownID,
			&s.MinPrice, &s.MaxPrice, &s.Keywords, &s.Condition,
			&s.NotifyNewListings, &s.NotifyPriceDrops, &s.MatchCount,
			&s.IsActive, &s.CreatedAt,
			&categoryName, &townName)
		if categoryName != nil {
			s.Category = &models.Category{Name: *categoryName}
		}
		if townName != nil {
			s.Town = &models.Town{Name: *townName}
		}
		searches = append(searches, s)
	}

	c.JSON(http.StatusOK, gin.H{"saved_searches": searches})
}

// DeleteSavedSearch removes a saved search
func (h *FeaturesHandler) DeleteSavedSearch(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	searchID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid search ID"})
		return
	}

	result, err := h.db.Pool.Exec(context.Background(),
		"UPDATE saved_searches SET is_active = false WHERE id = $1 AND user_id = $2",
		searchID, userID,
	)
	if err != nil || result.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Saved search not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Saved search deleted"})
}

// =============================================================================
// PROMOTION ENDPOINTS
// =============================================================================

// GetPromotionPricing returns available promotion options
func (h *FeaturesHandler) GetPromotionPricing(c *gin.Context) {
	townID := c.Query("town_id")

	query := `SELECT id, name, promotion_type, duration_hours, price, boost_multiplier, description
	          FROM promotion_pricing WHERE is_active = true`
	args := []interface{}{}

	if townID != "" {
		townUUID, _ := uuid.Parse(townID)
		query += " AND (town_id IS NULL OR town_id = $1)"
		args = append(args, townUUID)
	} else {
		query += " AND town_id IS NULL"
	}
	query += " ORDER BY price ASC"

	rows, err := h.db.Pool.Query(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch pricing"})
		return
	}
	defer rows.Close()

	var pricing []models.PromotionPricing
	for rows.Next() {
		var p models.PromotionPricing
		rows.Scan(&p.ID, &p.Name, &p.PromotionType, &p.DurationHours, &p.Price, &p.BoostMultiplier, &p.Description)
		pricing = append(pricing, p)
	}

	c.JSON(http.StatusOK, gin.H{"pricing": pricing})
}

// PromoteAuction creates a promotion for an auction
func (h *FeaturesHandler) PromoteAuction(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	var req models.CreatePromotionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify ownership
	var sellerID uuid.UUID
	var townID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(),
		"SELECT seller_id, town_id FROM auctions WHERE id = $1 AND status IN ('active', 'ending_soon')",
		auctionID,
	).Scan(&sellerID, &townID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Auction not found or not active"})
		return
	}
	if sellerID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only promote your own auctions"})
		return
	}

	// Get pricing
	var pricing models.PromotionPricing
	err = h.db.Pool.QueryRow(context.Background(),
		"SELECT id, promotion_type, duration_hours, price, boost_multiplier FROM promotion_pricing WHERE id = $1 AND is_active = true",
		req.PricingID,
	).Scan(&pricing.ID, &pricing.PromotionType, &pricing.DurationHours, &pricing.Price, &pricing.BoostMultiplier)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid pricing option"})
		return
	}

	// Check for existing active promotion of same type
	var existingCount int
	h.db.Pool.QueryRow(context.Background(),
		`SELECT COUNT(*) FROM promoted_auctions 
		 WHERE auction_id = $1 AND promotion_type = $2 AND is_active = true AND ends_at > NOW()`,
		auctionID, pricing.PromotionType,
	).Scan(&existingCount)
	if existingCount > 0 {
		c.JSON(http.StatusConflict, gin.H{"error": "Auction already has this promotion active"})
		return
	}

	// Create promotion
	startsAt := time.Now()
	endsAt := startsAt.Add(time.Duration(pricing.DurationHours) * time.Hour)

	var promoID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(),
		`INSERT INTO promoted_auctions (auction_id, user_id, promotion_type, town_id, starts_at, ends_at, amount_paid, boost_multiplier, payment_status)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'paid')
		 RETURNING id`,
		auctionID, userID, pricing.PromotionType, townID, startsAt, endsAt, pricing.Price, pricing.BoostMultiplier,
	).Scan(&promoID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create promotion"})
		return
	}

	// Update auction featured status if applicable
	if pricing.PromotionType == "featured" || pricing.PromotionType == "pinned" {
		h.db.Pool.Exec(context.Background(),
			"UPDATE auctions SET is_featured = true WHERE id = $1",
			auctionID,
		)
	}

	c.JSON(http.StatusCreated, models.PromotionResponse{
		Promotion: &models.PromotedAuction{
			ID:            promoID,
			AuctionID:     auctionID,
			PromotionType: pricing.PromotionType,
			StartsAt:      startsAt,
			EndsAt:        endsAt,
			AmountPaid:    pricing.Price,
		},
		Message:   "Promotion activated",
		ExpiresAt: endsAt,
	})
}

// =============================================================================
// USER RATINGS ENDPOINTS
// =============================================================================

// RateUser creates a rating for a user after transaction
func (h *FeaturesHandler) RateUser(c *gin.Context) {
	raterID, _ := middleware.GetUserID(c)
	ratedUserID, err := uuid.Parse(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	auctionIDStr := c.Query("auction_id")
	var auctionID *uuid.UUID
	if auctionIDStr != "" {
		id, _ := uuid.Parse(auctionIDStr)
		auctionID = &id
	}

	var req models.CreateRatingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Cannot rate yourself
	if raterID == ratedUserID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot rate yourself"})
		return
	}

	// Determine role (buyer or seller)
	role := "buyer" // Default
	if auctionID != nil {
		var sellerID uuid.UUID
		h.db.Pool.QueryRow(context.Background(),
			"SELECT seller_id FROM auctions WHERE id = $1",
			auctionID,
		).Scan(&sellerID)
		if sellerID == raterID {
			role = "seller" // Rater is seller, rating the buyer
		}
	}

	var ratingID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(),
		`INSERT INTO user_ratings (rater_id, rated_user_id, auction_id, rating, communication_rating, accuracy_rating, speed_rating, review, role, would_recommend)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		 RETURNING id`,
		raterID, ratedUserID, auctionID, req.Rating, req.CommunicationRating, req.AccuracyRating, req.SpeedRating, req.Review, role, req.WouldRecommend,
	).Scan(&ratingID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create rating"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":      ratingID,
		"message": "Rating submitted successfully",
	})
}

// GetUserRatings returns ratings for a user
func (h *FeaturesHandler) GetUserRatings(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT ur.id, ur.rating, ur.communication_rating, ur.accuracy_rating, ur.speed_rating,
		        ur.review, ur.role, ur.would_recommend, ur.created_at,
		        u.id, u.username, u.avatar_url
		 FROM user_ratings ur
		 JOIN users u ON ur.rater_id = u.id
		 WHERE ur.rated_user_id = $1
		 ORDER BY ur.created_at DESC
		 LIMIT 50`,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch ratings"})
		return
	}
	defer rows.Close()

	var ratings []models.UserRating
	for rows.Next() {
		var r models.UserRating
		var rater models.User
		rows.Scan(&r.ID, &r.Rating, &r.CommunicationRating, &r.AccuracyRating, &r.SpeedRating,
			&r.Review, &r.Role, &r.WouldRecommend, &r.CreatedAt,
			&rater.ID, &rater.Username, &rater.AvatarURL)
		r.Rater = &rater
		ratings = append(ratings, r)
	}

	// Get aggregate stats
	var avgRating float64
	var totalRatings int
	h.db.Pool.QueryRow(context.Background(),
		"SELECT COALESCE(AVG(rating), 0), COUNT(*) FROM user_ratings WHERE rated_user_id = $1",
		userID,
	).Scan(&avgRating, &totalRatings)

	c.JSON(http.StatusOK, gin.H{
		"ratings":       ratings,
		"average":       avgRating,
		"total_ratings": totalRatings,
	})
}

// GetUserReputation returns detailed reputation info
func (h *FeaturesHandler) GetUserReputation(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	var rep models.UserReputation
	var badges []byte
	err = h.db.Pool.QueryRow(context.Background(),
		`SELECT id, username, full_name, avatar_url, rating, rating_count, completed_auctions,
		        badge_level, is_trusted_seller, is_verified, is_fast_responder,
		        total_transactions, successful_transactions, COALESCE(member_since, created_at), badges
		 FROM users WHERE id = $1`,
		userID,
	).Scan(&rep.UserID, &rep.Username, &rep.FullName, &rep.AvatarURL, &rep.Rating, &rep.RatingCount,
		&rep.CompletedAuctions, &rep.BadgeLevel, &rep.IsTrustedSeller, &rep.IsVerified,
		&rep.IsFastResponder, &rep.TotalTransactions, &rep.SuccessfulTransactions, &rep.MemberSince, &badges)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Parse badges
	if badges != nil {
		json.Unmarshal(badges, &rep.Badges)
	}

	// Calculate completion rate
	if rep.TotalTransactions > 0 {
		rep.CompletionRate = float64(rep.SuccessfulTransactions) / float64(rep.TotalTransactions) * 100
	} else {
		rep.CompletionRate = 100
	}

	c.JSON(http.StatusOK, rep)
}

// =============================================================================
// TOWN LEADERBOARDS ENDPOINTS
// =============================================================================

// GetTownLeaderboard returns leaderboard for a town
func (h *FeaturesHandler) GetTownLeaderboard(c *gin.Context) {
	townID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid town ID"})
		return
	}

	lbType := c.DefaultQuery("type", "top_sellers")
	period := c.DefaultQuery("period", "monthly")

	// Validate params
	validTypes := map[string]bool{"top_sellers": true, "highest_rated": true, "most_active": true}
	validPeriods := map[string]bool{"weekly": true, "monthly": true, "all_time": true}
	if !validTypes[lbType] || !validPeriods[period] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid type or period"})
		return
	}

	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT lb.rank, lb.user_id, u.username, u.full_name, u.avatar_url, u.badge_level, lb.score, lb.metric_value
		 FROM town_leaderboards lb
		 JOIN users u ON lb.user_id = u.id
		 WHERE lb.town_id = $1 AND lb.leaderboard_type = $2 AND lb.period = $3
		 ORDER BY lb.rank ASC
		 LIMIT 20`,
		townID, lbType, period,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch leaderboard"})
		return
	}
	defer rows.Close()

	var entries []models.LeaderboardEntry
	for rows.Next() {
		var e models.LeaderboardEntry
		rows.Scan(&e.Rank, &e.UserID, &e.Username, &e.FullName, &e.AvatarURL, &e.BadgeLevel, &e.Score, &e.MetricValue)
		entries = append(entries, e)
	}

	// Get town name
	var townName string
	h.db.Pool.QueryRow(context.Background(), "SELECT name FROM towns WHERE id = $1", townID).Scan(&townName)

	c.JSON(http.StatusOK, models.TownLeaderboard{
		TownID:          townID,
		TownName:        townName,
		LeaderboardType: lbType,
		Period:          period,
		Entries:         entries,
		CalculatedAt:    time.Now(),
	})
}

// GetTownStats returns aggregated stats for a town
func (h *FeaturesHandler) GetTownStats(c *gin.Context) {
	townID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid town ID"})
		return
	}

	var stats models.TownStats
	err = h.db.Pool.QueryRow(context.Background(),
		`SELECT ts.town_id, t.name, ts.active_auctions, ts.total_auctions, ts.total_users,
		        ts.active_sellers, ts.total_sales_value, ts.avg_auction_price, ts.top_category_id, ts.calculated_at
		 FROM town_stats ts
		 JOIN towns t ON ts.town_id = t.id
		 WHERE ts.town_id = $1`,
		townID,
	).Scan(&stats.TownID, &stats.TownName, &stats.ActiveAuctions, &stats.TotalAuctions,
		&stats.TotalUsers, &stats.ActiveSellers, &stats.TotalSalesValue, &stats.AvgAuctionPrice,
		&stats.TopCategoryID, &stats.CalculatedAt)
	if err != nil {
		// Stats not cached, calculate on the fly
		h.db.Pool.QueryRow(context.Background(), "SELECT refresh_town_stats($1)", townID)
		// Try again
		h.db.Pool.QueryRow(context.Background(),
			`SELECT ts.town_id, t.name, ts.active_auctions, ts.total_auctions, ts.total_users,
			        ts.active_sellers, ts.total_sales_value, ts.avg_auction_price, ts.calculated_at
			 FROM town_stats ts
			 JOIN towns t ON ts.town_id = t.id
			 WHERE ts.town_id = $1`,
			townID,
		).Scan(&stats.TownID, &stats.TownName, &stats.ActiveAuctions, &stats.TotalAuctions,
			&stats.TotalUsers, &stats.ActiveSellers, &stats.TotalSalesValue, &stats.AvgAuctionPrice,
			&stats.CalculatedAt)
	}

	c.JSON(http.StatusOK, stats)
}

// GetTopSellersInTown returns top sellers for a town (quick endpoint)
func (h *FeaturesHandler) GetTopSellersInTown(c *gin.Context) {
	townID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid town ID"})
		return
	}

	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT u.id, u.username, u.full_name, u.avatar_url, u.rating, u.rating_count,
		        u.completed_auctions, u.badge_level, u.is_verified, u.is_fast_responder
		 FROM users u
		 WHERE u.home_town_id = $1 AND u.completed_auctions > 0
		 ORDER BY u.completed_auctions DESC, u.rating DESC
		 LIMIT 10`,
		townID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch top sellers"})
		return
	}
	defer rows.Close()

	var sellers []models.UserReputation
	for rows.Next() {
		var s models.UserReputation
		rows.Scan(&s.UserID, &s.Username, &s.FullName, &s.AvatarURL, &s.Rating, &s.RatingCount,
			&s.CompletedAuctions, &s.BadgeLevel, &s.IsVerified, &s.IsFastResponder)
		sellers = append(sellers, s)
	}

	c.JSON(http.StatusOK, gin.H{"top_sellers": sellers})
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

func (h *FeaturesHandler) getIncrement(currentPrice float64) float64 {
	switch {
	case currentPrice < 5:
		return 1.00
	case currentPrice < 20:
		return 2.00
	case currentPrice < 100:
		return 5.00
	case currentPrice < 500:
		return 10.00
	default:
		return 25.00
	}
}
