package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/middleware"
	"github.com/airmass/backend/internal/models"
	"github.com/airmass/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// AuctionHandler handles auction endpoints
type AuctionHandler struct {
	db  *database.DB
	hub *websocket.Hub
}

// NewAuctionHandler creates a new auction handler
func NewAuctionHandler(db *database.DB, hub *websocket.Hub) *AuctionHandler {
	return &AuctionHandler{db: db, hub: hub}
}

// BidIncrementTier represents a bid increment tier from the database
type BidIncrementTier struct {
	MinPrice  float64
	MaxPrice  *float64
	Increment float64
}

// GetBidIncrement calculates the bid increment based on tiered pricing
// This is the critical tiered bid increment logic
func (h *AuctionHandler) GetBidIncrement(currentPrice float64) float64 {
	// Tiered bid increment rules (enforced SERVER-SIDE)
	// $0 - $4.99 → +$1
	// $5 - $19.99 → +$2
	// $20 - $99.99 → +$5
	// $100 - $499.99 → +$10
	// $500+ → +$25

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

// fetchFullAuction retrieves a complete auction object with all joined data
func (h *AuctionHandler) fetchFullAuction(ctx context.Context, auctionID uuid.UUID) (*models.Auction, error) {
	row := h.db.Pool.QueryRow(ctx, `
		SELECT a.id, a.title, a.description, a.starting_price, a.current_price, a.reserve_price,
		a.bid_increment, a.seller_id, a.winner_id, a.category_id, a.town_id, a.suburb_id, 
		a.status, a.condition, a.start_time, a.end_time, a.original_end_time, a.anti_snipe_minutes,
		a.total_bids, a.views, a.images, a.is_featured, a.allow_offers, 
		a.pickup_location, a.shipping_available, a.created_at, a.updated_at,
		u.id, u.username, u.full_name, u.avatar_url, u.rating, u.rating_count, u.completed_auctions, u.is_verified,
		c.name, c.icon,
		t.name, s.name
		FROM auctions a
		LEFT JOIN users u ON a.seller_id = u.id
		LEFT JOIN categories c ON a.category_id = c.id
		LEFT JOIN towns t ON a.town_id = t.id
		LEFT JOIN suburbs s ON a.suburb_id = s.id
		WHERE a.id = $1
	`, auctionID)

	var auction models.Auction
	var seller models.User
	var categoryName, categoryIcon, townName, suburbName *string
	var sellerRating *float64
	var sellerRatingCount, sellerCompletedAuctions *int
	var sellerIsVerified *bool

	err := row.Scan(
		&auction.ID, &auction.Title, &auction.Description, &auction.StartingPrice, &auction.CurrentPrice,
		&auction.ReservePrice, &auction.BidIncrement, &auction.SellerID, &auction.WinnerID,
		&auction.CategoryID, &auction.TownID, &auction.SuburbID, &auction.Status, &auction.Condition,
		&auction.StartTime, &auction.EndTime, &auction.OriginalEndTime, &auction.AntiSnipeMinutes,
		&auction.TotalBids, &auction.Views, &auction.Images, &auction.IsFeatured, &auction.AllowOffers,
		&auction.PickupLocation, &auction.ShippingAvailable, &auction.CreatedAt, &auction.UpdatedAt,
		&seller.ID, &seller.Username, &seller.FullName, &seller.AvatarURL,
		&sellerRating, &sellerRatingCount, &sellerCompletedAuctions, &sellerIsVerified,
		&categoryName, &categoryIcon, &townName, &suburbName,
	)
	if err != nil {
		return nil, err
	}

	// Set seller details
	if sellerRating != nil {
		seller.Rating = *sellerRating
	}
	if sellerRatingCount != nil {
		seller.RatingCount = *sellerRatingCount
	}
	if sellerCompletedAuctions != nil {
		seller.CompletedAuctions = *sellerCompletedAuctions
	}
	if sellerIsVerified != nil {
		seller.IsVerified = *sellerIsVerified
	}
	auction.Seller = &seller

	if categoryName != nil {
		auction.Category = &models.Category{ID: auction.CategoryID, Name: *categoryName, Icon: categoryIcon}
	}
	if townName != nil {
		auction.Town = &models.Town{ID: auction.TownID, Name: *townName}
	}
	if suburbName != nil && auction.SuburbID != nil {
		auction.Suburb = &models.Suburb{ID: *auction.SuburbID, Name: *suburbName}
	}

	// Calculate computed fields
	if auction.EndTime != nil {
		remaining := time.Until(*auction.EndTime)
		if remaining > 0 {
			auction.TimeRemaining = formatDuration(remaining)
			auction.IsEndingSoon = remaining < time.Hour
		}
	}

	currentPrice := auction.StartingPrice
	if auction.CurrentPrice != nil {
		currentPrice = *auction.CurrentPrice
	}
	increment := h.GetBidIncrement(currentPrice)
	auction.BidIncrement = increment
	auction.MinNextBid = currentPrice + increment

	return &auction, nil
}

// GetNextValidBid returns the ONLY valid next bid amount for an auction
func (h *AuctionHandler) GetNextValidBid(auctionID uuid.UUID) (float64, float64, error) {
	var currentPrice, startingPrice float64
	var currentPricePtr *float64

	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT COALESCE(current_price, starting_price), starting_price FROM auctions WHERE id = $1",
		auctionID,
	).Scan(&currentPricePtr, &startingPrice)

	if err != nil {
		return 0, 0, err
	}

	if currentPricePtr != nil {
		currentPrice = *currentPricePtr
	} else {
		currentPrice = startingPrice
	}

	increment := h.GetBidIncrement(currentPrice)
	nextBid := currentPrice + increment

	return nextBid, increment, nil
}

// GetAuctions returns paginated auctions with filters
func (h *AuctionHandler) GetAuctions(c *gin.Context) {
	var filters models.AuctionFilters
	if err := c.ShouldBindQuery(&filters); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Default pagination
	if filters.Page < 1 {
		filters.Page = 1
	}
	if filters.Limit < 1 || filters.Limit > 50 {
		filters.Limit = 20
	}
	offset := (filters.Page - 1) * filters.Limit

	// Check for context filters (from GetMyTownAuctions)
	if ctxFilters, exists := c.Get("filters"); exists {
		if f, ok := ctxFilters.(models.AuctionFilters); ok {
			if f.TownID != nil {
				filters.TownID = f.TownID
			}
			if f.SuburbID != nil {
				filters.SuburbID = f.SuburbID
			}
		}
	}

	// Build query
	query := `
		SELECT a.id, a.title, a.description, a.starting_price, a.current_price, a.bid_increment,
		a.seller_id, a.category_id, a.town_id, a.suburb_id, a.status, a.condition,
		a.start_time, a.end_time, a.total_bids, a.views, a.images,
		a.is_featured, a.created_at,
		u.username as seller_username, u.avatar_url as seller_avatar,
		c.name as category_name, c.icon as category_icon,
		t.name as town_name, s.name as suburb_name
		FROM auctions a
		LEFT JOIN users u ON a.seller_id = u.id
		LEFT JOIN categories c ON a.category_id = c.id
		LEFT JOIN towns t ON a.town_id = t.id
		LEFT JOIN suburbs s ON a.suburb_id = s.id
		WHERE a.status IN ('active', 'ending_soon')
	`
	countQuery := `SELECT COUNT(*) FROM auctions a WHERE a.status IN ('active', 'ending_soon')`
	args := []interface{}{}
	argCount := 0

	// Apply filters
	if filters.TownID != nil {
		argCount++
		query += fmt.Sprintf(" AND a.town_id = $%d", argCount)
		countQuery += fmt.Sprintf(" AND a.town_id = $%d", argCount)
		args = append(args, *filters.TownID)
	}
	if filters.SuburbID != nil {
		argCount++
		query += fmt.Sprintf(" AND a.suburb_id = $%d", argCount)
		countQuery += fmt.Sprintf(" AND a.suburb_id = $%d", argCount)
		args = append(args, *filters.SuburbID)
	}
	if filters.CategoryID != nil {
		argCount++
		query += fmt.Sprintf(" AND a.category_id = $%d", argCount)
		countQuery += fmt.Sprintf(" AND a.category_id = $%d", argCount)
		args = append(args, *filters.CategoryID)
	}
	if filters.SellerID != nil {
		argCount++
		query += fmt.Sprintf(" AND a.seller_id = $%d", argCount)
		countQuery += fmt.Sprintf(" AND a.seller_id = $%d", argCount)
		args = append(args, *filters.SellerID)
	}
	if filters.Search != nil && *filters.Search != "" {
		argCount++
		query += fmt.Sprintf(" AND (a.title ILIKE $%d OR a.description ILIKE $%d)", argCount, argCount)
		countQuery += fmt.Sprintf(" AND (a.title ILIKE $%d OR a.description ILIKE $%d)", argCount, argCount)
		args = append(args, "%"+*filters.Search+"%")
	}

	// Sorting
	switch filters.SortBy {
	case "ending_soon":
		query += " ORDER BY a.end_time ASC"
	case "price_low":
		query += " ORDER BY COALESCE(a.current_price, a.starting_price) ASC"
	case "price_high":
		query += " ORDER BY COALESCE(a.current_price, a.starting_price) DESC"
	case "most_bids":
		query += " ORDER BY a.total_bids DESC"
	default:
		query += " ORDER BY a.created_at DESC"
	}

	// Pagination
	query += fmt.Sprintf(" LIMIT %d OFFSET %d", filters.Limit, offset)

	// Get total count
	var total int
	h.db.Pool.QueryRow(context.Background(), countQuery, args...).Scan(&total)

	// Execute main query
	rows, err := h.db.Pool.Query(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch auctions"})
		return
	}
	defer rows.Close()

	auctions := h.scanAuctions(rows)

	// Check if user has bid on any
	userID, hasUser := middleware.GetUserID(c)
	if hasUser {
		for i := range auctions {
			h.db.Pool.QueryRow(context.Background(),
				"SELECT EXISTS(SELECT 1 FROM bids WHERE auction_id = $1 AND bidder_id = $2)",
				auctions[i].ID, userID,
			).Scan(&auctions[i].UserHasBid)

			h.db.Pool.QueryRow(context.Background(),
				"SELECT EXISTS(SELECT 1 FROM bids WHERE auction_id = $1 AND bidder_id = $2 AND is_winning = true)",
				auctions[i].ID, userID,
			).Scan(&auctions[i].UserIsHighBidder)
		}
	}

	c.JSON(http.StatusOK, models.AuctionListResponse{
		Auctions:   auctions,
		Total:      total,
		Page:       filters.Page,
		Limit:      filters.Limit,
		TotalPages: int(math.Ceil(float64(total) / float64(filters.Limit))),
	})
}

// GetMyTownAuctions returns auctions in the user's home town
func (h *AuctionHandler) GetMyTownAuctions(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	// Get user's home town
	var townID uuid.UUID
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT home_town_id FROM users WHERE id = $1",
		userID,
	).Scan(&townID)
	if err != nil {
		if err == pgx.ErrNoRows {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found. Please log in again."})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "Please set your home town first"})
		return
	}

	// Forward to GetAuctions with town filter
	townIDStr := townID.String()
	c.Set("town_id", townID)
	filters := models.AuctionFilters{TownID: &townIDStr}
	c.Set("filters", filters)
	h.GetAuctions(c)
}

// GetNationalAuctions returns auctions aggregated nationally
func (h *AuctionHandler) GetNationalAuctions(c *gin.Context) {
	// Just get all auctions without town filter
	h.GetAuctions(c)
}

// GetAuction returns a specific auction with tiered bid increment info
func (h *AuctionHandler) GetAuction(c *gin.Context) {
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	// Increment views
	h.db.Pool.Exec(context.Background(),
		"UPDATE auctions SET views = views + 1 WHERE id = $1",
		auctionID,
	)

	row := h.db.Pool.QueryRow(context.Background(), `
		SELECT a.id, a.title, a.description, a.starting_price, a.current_price, a.reserve_price,
		a.bid_increment, a.seller_id, a.winner_id, a.category_id, a.town_id, a.suburb_id, 
		a.status, a.condition, a.start_time, a.end_time, a.original_end_time, a.anti_snipe_minutes,
		a.total_bids, a.views, a.images, a.is_featured, a.allow_offers, 
		a.pickup_location, a.shipping_available, a.created_at, a.updated_at,
		u.id, u.username, u.full_name, u.avatar_url, u.rating, u.rating_count, u.completed_auctions, u.is_verified,
		c.name, c.icon,
		t.name, s.name
		FROM auctions a
		LEFT JOIN users u ON a.seller_id = u.id
		LEFT JOIN categories c ON a.category_id = c.id
		LEFT JOIN towns t ON a.town_id = t.id
		LEFT JOIN suburbs s ON a.suburb_id = s.id
		WHERE a.id = $1
	`, auctionID)

	var auction models.Auction
	var seller models.User
	var categoryName, categoryIcon, townName, suburbName *string
	var sellerRating *float64
	var sellerRatingCount, sellerCompletedAuctions *int
	var sellerIsVerified *bool

	err = row.Scan(
		&auction.ID, &auction.Title, &auction.Description, &auction.StartingPrice, &auction.CurrentPrice,
		&auction.ReservePrice, &auction.BidIncrement, &auction.SellerID, &auction.WinnerID,
		&auction.CategoryID, &auction.TownID, &auction.SuburbID, &auction.Status, &auction.Condition,
		&auction.StartTime, &auction.EndTime, &auction.OriginalEndTime, &auction.AntiSnipeMinutes,
		&auction.TotalBids, &auction.Views, &auction.Images, &auction.IsFeatured, &auction.AllowOffers,
		&auction.PickupLocation, &auction.ShippingAvailable, &auction.CreatedAt, &auction.UpdatedAt,
		&seller.ID, &seller.Username, &seller.FullName, &seller.AvatarURL,
		&sellerRating, &sellerRatingCount, &sellerCompletedAuctions, &sellerIsVerified,
		&categoryName, &categoryIcon, &townName, &suburbName,
	)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Auction not found"})
		return
	}

	// Set seller details
	if sellerRating != nil {
		seller.Rating = *sellerRating
	}
	if sellerRatingCount != nil {
		seller.RatingCount = *sellerRatingCount
	}
	if sellerCompletedAuctions != nil {
		seller.CompletedAuctions = *sellerCompletedAuctions
	}
	if sellerIsVerified != nil {
		seller.IsVerified = *sellerIsVerified
	}

	auction.Seller = &seller
	if categoryName != nil {
		auction.Category = &models.Category{Name: *categoryName, Icon: categoryIcon}
	}
	if townName != nil {
		auction.Town = &models.Town{Name: *townName}
	}
	if suburbName != nil {
		auction.Suburb = &models.Suburb{Name: *suburbName}
	}

	// Calculate time remaining
	if auction.EndTime != nil {
		remaining := time.Until(*auction.EndTime)
		if remaining > 0 {
			auction.TimeRemaining = formatDuration(remaining)
			auction.IsEndingSoon = remaining < time.Hour
		}
	}

	// Calculate TIERED min next bid - THIS IS THE KEY CHANGE
	currentPrice := auction.StartingPrice
	if auction.CurrentPrice != nil {
		currentPrice = *auction.CurrentPrice
	}

	// Use tiered increment calculation
	tieredIncrement := h.GetBidIncrement(currentPrice)
	auction.BidIncrement = tieredIncrement
	auction.MinNextBid = currentPrice + tieredIncrement

	// Get auction tags (hot, trending, etc.)
	tags := []string{}
	tagRows, _ := h.db.Pool.Query(context.Background(),
		"SELECT tag_type FROM auction_tags WHERE auction_id = $1 AND (expires_at IS NULL OR expires_at > NOW())",
		auctionID,
	)
	if tagRows != nil {
		defer tagRows.Close()
		for tagRows.Next() {
			var tag string
			tagRows.Scan(&tag)
			tags = append(tags, tag)
		}
	}
	auction.Tags = tags

	// Check user's bid status
	userID, hasUser := middleware.GetUserID(c)
	if hasUser {
		h.db.Pool.QueryRow(context.Background(),
			"SELECT EXISTS(SELECT 1 FROM bids WHERE auction_id = $1 AND bidder_id = $2)",
			auctionID, userID,
		).Scan(&auction.UserHasBid)

		h.db.Pool.QueryRow(context.Background(),
			"SELECT EXISTS(SELECT 1 FROM bids WHERE auction_id = $1 AND bidder_id = $2 AND is_winning = true)",
			auctionID, userID,
		).Scan(&auction.UserIsHighBidder)
	}

	c.JSON(http.StatusOK, auction)
}

// CreateAuction creates a new auction
func (h *AuctionHandler) CreateAuction(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	var req models.CreateAuctionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user's home town (sellers can only create in their town)
	var townID uuid.UUID
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT home_town_id FROM users WHERE id = $1",
		userID,
	).Scan(&townID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Please set your home town before creating auctions"})
		return
	}

	// Check category slot availability
	var maxActive, currentActive int
	h.db.Pool.QueryRow(context.Background(),
		"SELECT COALESCE(max_active_auctions, 10) FROM category_slots WHERE category_id = $1 AND town_id = $2",
		req.CategoryID, townID,
	).Scan(&maxActive)
	if maxActive == 0 {
		maxActive = 10
	}

	h.db.Pool.QueryRow(context.Background(),
		"SELECT COUNT(*) FROM auctions WHERE category_id = $1 AND town_id = $2 AND status IN ('active', 'ending_soon')",
	).Scan(&currentActive)

	status := "active"
	message := "Auction published successfully!"

	if currentActive >= maxActive {
		status = "pending"
		message = "Category is full. Your auction has been added to the waiting list and will go live automatically."
	}

	// Calculate TIERED bid increment based on starting price
	bidIncrement := h.GetBidIncrement(req.StartingPrice)

	durationHours := req.DurationHours
	if durationHours <= 0 {
		durationHours = 168 // 7 days default
	}

	startTime := time.Now()
	endTime := startTime.Add(time.Duration(durationHours) * time.Hour)

	// Create auction
	var auctionID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(),
		`INSERT INTO auctions (
			title, description, starting_price, current_price, reserve_price, bid_increment,
			seller_id, category_id, town_id, suburb_id, status, condition,
			start_time, end_time, original_end_time, images, allow_offers,
			pickup_location, shipping_available
		) VALUES ($1, $2, $3, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $13, $14, $15, $16, $17)
		RETURNING id`,
		req.Title, req.Description, req.StartingPrice, req.ReservePrice, bidIncrement,
		userID, req.CategoryID, townID, req.SuburbID, status, req.Condition,
		startTime, endTime, req.Images, req.AllowOffers, req.PickupLocation, req.ShippingAvailable,
	).Scan(&auctionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create auction"})
		return
	}

	// Broadcast to town subscribers if active
	if status == "active" {
		h.hub.BroadcastToTown(townID, websocket.MessageTypeAuctionUpdate, gin.H{
			"action":     "new_auction",
			"auction_id": auctionID,
			"title":      req.Title,
		})
	}

	// Fetch full auction for response
	createdAuction, err := h.fetchFullAuction(context.Background(), auctionID)
	if err != nil {
		log.Printf("DEBUG: fetchFullAuction failed: %v", err)
		// Fallback if full fetch fails
		c.JSON(http.StatusCreated, gin.H{
			"id":      auctionID,
			"status":  status,
			"message": message,
		})
		return
	}

	respBody := gin.H{
		"auction": createdAuction,
		"status":  status,
		"message": message,
		"id":      auctionID, // Still provide ID at top level
	}

	respJSON, _ := json.Marshal(respBody)
	log.Printf("DEBUG: CreateAuction Response: %s", string(respJSON))

	c.JSON(http.StatusCreated, respBody)
}

// PlaceBid places a bid on an auction with STRICT tiered increment enforcement
// This uses database transactions and row locking to prevent race conditions
func (h *AuctionHandler) PlaceBid(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	// Start a transaction for atomic bid placement
	tx, err := h.db.Pool.Begin(context.Background())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}
	defer tx.Rollback(context.Background())

	// Lock the auction row to prevent race conditions
	var auction models.Auction
	var previousHighBidderID *uuid.UUID
	err = tx.QueryRow(context.Background(),
		`SELECT id, seller_id, current_price, starting_price, status, end_time
		FROM auctions WHERE id = $1 FOR UPDATE`,
		auctionID,
	).Scan(&auction.ID, &auction.SellerID, &auction.CurrentPrice, &auction.StartingPrice,
		&auction.Status, &auction.EndTime)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Auction not found"})
		return
	}

	// === STRICT VALIDATION CHECKS ===

	// 1. Check auction is active
	if auction.Status != models.AuctionStatusActive && auction.Status != models.AuctionStatusEndingSoon {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Auction is not active", "code": "AUCTION_NOT_ACTIVE"})
		return
	}

	// 2. Check seller is not bidding on own auction (fraud prevention)
	if auction.SellerID == userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You cannot bid on your own auction", "code": "SELF_BID_FORBIDDEN"})
		return
	}

	// 3. Check auction hasn't ended
	if auction.EndTime != nil && time.Now().After(*auction.EndTime) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Auction has ended", "code": "AUCTION_ENDED"})
		return
	}

	// === CALCULATE THE ONLY VALID NEXT BID (SERVER-SIDE) ===
	currentPrice := auction.StartingPrice
	if auction.CurrentPrice != nil {
		currentPrice = *auction.CurrentPrice
	}

	// Use TIERED bid increment - client amount is IGNORED
	tieredIncrement := h.GetBidIncrement(currentPrice)
	requiredBid := currentPrice + tieredIncrement

	// Get previous high bidder for outbid notification
	tx.QueryRow(context.Background(),
		"SELECT bidder_id FROM bids WHERE auction_id = $1 AND is_winning = true",
		auctionID,
	).Scan(&previousHighBidderID)

	// Place bid with the SERVER-CALCULATED amount (ignoring client amount entirely)
	var bid models.Bid
	err = tx.QueryRow(context.Background(),
		`INSERT INTO bids (auction_id, bidder_id, amount)
		VALUES ($1, $2, $3) RETURNING id, created_at`,
		auctionID, userID, requiredBid,
	).Scan(&bid.ID, &bid.CreatedAt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to place bid"})
		return
	}

	// Commit transaction
	if err = tx.Commit(context.Background()); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit bid"})
		return
	}

	bid.AuctionID = auctionID
	bid.BidderID = userID
	bid.Amount = requiredBid
	bid.IsWinning = true

	// Check if time was extended (anti-sniping) - read updated auction
	var newEndTime *time.Time
	timeExtended := false
	h.db.Pool.QueryRow(context.Background(),
		"SELECT end_time FROM auctions WHERE id = $1",
		auctionID,
	).Scan(&newEndTime)

	if newEndTime != nil && auction.EndTime != nil && newEndTime.After(*auction.EndTime) {
		timeExtended = true
	}

	// Calculate the NEXT bid increment for response
	nextIncrement := h.GetBidIncrement(requiredBid)
	nextBidAmount := requiredBid + nextIncrement

	// Broadcast bid to auction subscribers
	h.hub.BroadcastToAuction(auctionID, websocket.MessageTypeBidNew, gin.H{
		"bid_id":          bid.ID,
		"amount":          requiredBid,
		"bidder_id":       userID,
		"time_extended":   timeExtended,
		"new_end_time":    newEndTime,
		"next_bid_amount": nextBidAmount,
		"next_increment":  nextIncrement,
	})

	// Notify previous high bidder (outbid)
	if previousHighBidderID != nil && *previousHighBidderID != userID {
		h.hub.BroadcastToUser(*previousHighBidderID, websocket.MessageTypeBidOutbid, gin.H{
			"auction_id": auctionID,
			"new_amount": requiredBid,
		})

		// Create notification
		h.db.Pool.Exec(context.Background(),
			`INSERT INTO notifications (user_id, type, title, body, related_auction_id)
			VALUES ($1, 'outbid', 'You''ve been outbid!', $2, $3)`,
			previousHighBidderID, fmt.Sprintf("Someone bid $%.2f", requiredBid), auctionID,
		)
	}

	c.JSON(http.StatusOK, models.BidResponse{
		Bid:           &bid,
		IsHighBidder:  true,
		Message:       "Bid placed successfully",
		NewPrice:      requiredBid,
		TimeExtended:  timeExtended,
		NewEndTime:    newEndTime,
		NextBidAmount: nextBidAmount,
		NextIncrement: nextIncrement,
	})
}

// GetBidHistory returns bids for an auction
func (h *AuctionHandler) GetBidHistory(c *gin.Context) {
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT b.id, b.auction_id, b.bidder_id, b.amount, b.is_winning, b.created_at,
		u.username, u.avatar_url
		FROM bids b
		LEFT JOIN users u ON b.bidder_id = u.id
		WHERE b.auction_id = $1
		ORDER BY b.amount DESC, b.created_at DESC
		LIMIT 50`,
		auctionID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch bids"})
		return
	}
	defer rows.Close()

	var bids []models.Bid
	var highestBid float64
	for rows.Next() {
		var bid models.Bid
		var bidder models.User
		rows.Scan(&bid.ID, &bid.AuctionID, &bid.BidderID, &bid.Amount, &bid.IsWinning, &bid.CreatedAt,
			&bidder.Username, &bidder.AvatarURL)
		bidder.ID = bid.BidderID
		bid.Bidder = &bidder
		bids = append(bids, bid)
		if bid.Amount > highestBid {
			highestBid = bid.Amount
		}
	}

	// Get current increment for next bid info
	var nextBidAmount, nextIncrement float64
	if highestBid > 0 {
		nextIncrement = h.GetBidIncrement(highestBid)
		nextBidAmount = highestBid + nextIncrement
	}

	c.JSON(http.StatusOK, models.BidHistory{
		Bids:          bids,
		TotalBids:     len(bids),
		HighestBid:    highestBid,
		NextBidAmount: nextBidAmount,
		NextIncrement: nextIncrement,
	})
}

// CancelAuction allows seller to cancel/end their auction
func (h *AuctionHandler) CancelAuction(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	// Verify ownership
	var sellerID uuid.UUID
	var status string
	err = h.db.Pool.QueryRow(context.Background(),
		"SELECT seller_id, status FROM auctions WHERE id = $1",
		auctionID,
	).Scan(&sellerID, &status)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Auction not found"})
		return
	}

	if sellerID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only cancel your own auctions"})
		return
	}

	if status != "active" && status != "ending_soon" && status != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Auction cannot be cancelled"})
		return
	}

	// Cancel the auction
	_, err = h.db.Pool.Exec(context.Background(),
		"UPDATE auctions SET status = 'cancelled', updated_at = NOW() WHERE id = $1",
		auctionID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to cancel auction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Auction cancelled"})
}

func (h *AuctionHandler) scanAuctions(rows pgx.Rows) []models.Auction {
	var auctions []models.Auction
	for rows.Next() {
		var a models.Auction
		var seller models.User
		var categoryName, categoryIcon, townName, suburbName *string

		rows.Scan(
			&a.ID, &a.Title, &a.Description, &a.StartingPrice, &a.CurrentPrice, &a.BidIncrement,
			&a.SellerID, &a.CategoryID, &a.TownID, &a.SuburbID, &a.Status, &a.Condition,
			&a.StartTime, &a.EndTime, &a.TotalBids, &a.Views, &a.Images,
			&a.IsFeatured, &a.CreatedAt,
			&seller.Username, &seller.AvatarURL,
			&categoryName, &categoryIcon, &townName, &suburbName,
		)

		seller.ID = a.SellerID
		a.Seller = &seller

		if categoryName != nil {
			a.Category = &models.Category{Name: *categoryName, Icon: categoryIcon}
		}
		if townName != nil {
			a.Town = &models.Town{Name: *townName}
		}
		if suburbName != nil {
			a.Suburb = &models.Suburb{Name: *suburbName}
		}

		// Calculate time remaining
		if a.EndTime != nil {
			remaining := time.Until(*a.EndTime)
			if remaining > 0 {
				a.TimeRemaining = formatDuration(remaining)
				a.IsEndingSoon = remaining < time.Hour
			}
		}

		// Calculate TIERED min next bid
		currentPrice := a.StartingPrice
		if a.CurrentPrice != nil {
			currentPrice = *a.CurrentPrice
		}
		tieredIncrement := h.GetBidIncrement(currentPrice)
		a.BidIncrement = tieredIncrement
		a.MinNextBid = currentPrice + tieredIncrement

		auctions = append(auctions, a)
	}
	return auctions
}

// GetMyAuctions returns all auctions created by the current user
func (h *AuctionHandler) GetMyAuctions(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	// Parse query parameters
	status := c.Query("status") // active, ended, pending, or empty for all
	page := 1
	limit := 20
	if p := c.Query("page"); p != "" {
		fmt.Sscanf(p, "%d", &page)
	}
	if l := c.Query("limit"); l != "" {
		fmt.Sscanf(l, "%d", &limit)
	}
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 50 {
		limit = 20
	}
	offset := (page - 1) * limit

	// Build query based on status filter
	baseQuery := `
		SELECT a.id, a.title, a.description, a.starting_price, a.current_price, a.bid_increment,
		a.seller_id, a.category_id, a.town_id, a.suburb_id, a.status, a.condition,
		a.start_time, a.end_time, a.total_bids, a.views, a.images,
		a.is_featured, a.created_at,
		u.username as seller_username, u.avatar_url as seller_avatar,
		c.name as category_name, c.icon as category_icon,
		t.name as town_name, s.name as suburb_name
		FROM auctions a
		LEFT JOIN users u ON a.seller_id = u.id
		LEFT JOIN categories c ON a.category_id = c.id
		LEFT JOIN towns t ON a.town_id = t.id
		LEFT JOIN suburbs s ON a.suburb_id = s.id
		WHERE a.seller_id = $1
	`
	countQuery := `SELECT COUNT(*) FROM auctions a WHERE a.seller_id = $1`
	args := []interface{}{userID}
	argCount := 1

	// Apply status filter
	if status != "" {
		argCount++
		switch status {
		case "active":
			baseQuery += " AND a.status IN ('active', 'ending_soon')"
			countQuery += " AND a.status IN ('active', 'ending_soon')"
		case "ended":
			baseQuery += " AND a.status IN ('ended', 'sold', 'cancelled')"
			countQuery += " AND a.status IN ('ended', 'sold', 'cancelled')"
		case "pending":
			baseQuery += " AND a.status = 'pending'"
			countQuery += " AND a.status = 'pending'"
		default:
			argCount-- // No filter applied
		}
	}

	baseQuery += " ORDER BY a.created_at DESC"
	baseQuery += fmt.Sprintf(" LIMIT %d OFFSET %d", limit, offset)

	// Get total count
	var total int
	h.db.Pool.QueryRow(context.Background(), countQuery, args...).Scan(&total)

	// Execute main query
	rows, err := h.db.Pool.Query(context.Background(), baseQuery, args...)
	if err != nil {
		log.Printf("GetMyAuctions error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch auctions"})
		return
	}
	defer rows.Close()

	auctions := h.scanAuctions(rows)

	// Add time remaining for each auction
	for i := range auctions {
		if auctions[i].EndTime != nil {
			remaining := time.Until(*auctions[i].EndTime)
			if remaining > 0 {
				auctions[i].TimeRemaining = formatDuration(remaining)
			}
		}
	}

	c.JSON(http.StatusOK, models.AuctionListResponse{
		Auctions:   auctions,
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: int(math.Ceil(float64(total) / float64(limit))),
	})
}

// GetMyBids returns all bids for the current user
func (h *AuctionHandler) GetMyBids(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	page := 1
	limit := 20
	// Simple pagination parsing (can be improved)

	offset := (page - 1) * limit

	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT b.id, b.auction_id, b.bidder_id, b.amount, b.is_winning, b.created_at,
		a.title, a.status, a.end_time
		FROM bids b
		JOIN auctions a ON b.auction_id = a.id
		WHERE b.bidder_id = $1
		ORDER BY b.created_at DESC
		LIMIT $2 OFFSET $3`,
		userID, limit, offset,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch bids"})
		return
	}
	defer rows.Close()

	var bids []gin.H
	for rows.Next() {
		var bid models.Bid
		var auctionTitle, auctionStatus string
		var auctionEndTime *time.Time
		rows.Scan(&bid.ID, &bid.AuctionID, &bid.BidderID, &bid.Amount, &bid.IsWinning, &bid.CreatedAt,
			&auctionTitle, &auctionStatus, &auctionEndTime)

		// Manual join map construction for response
		bids = append(bids, gin.H{
			"id":         bid.ID,
			"auction_id": bid.AuctionID,
			"amount":     bid.Amount,
			"is_winning": bid.IsWinning,
			"created_at": bid.CreatedAt,
			"auction": gin.H{
				"title":    auctionTitle,
				"status":   auctionStatus,
				"end_time": auctionEndTime,
			},
		})
	}

	c.JSON(http.StatusOK, gin.H{"bids": bids})
}

// GetWonAuctions returns auctions won by the current user
func (h *AuctionHandler) GetWonAuctions(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	// Query matches the column order expected by scanAuctions
	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT a.id, a.title, a.description, a.starting_price, a.current_price, a.bid_increment,
		a.seller_id, a.category_id, a.town_id, a.suburb_id, a.status, a.condition,
		a.start_time, a.end_time, a.total_bids, a.views, a.images,
		a.is_featured, a.created_at,
		u.username, u.avatar_url,
		c.name, c.icon,
		t.name, s.name
		FROM auctions a
		LEFT JOIN users u ON a.seller_id = u.id
		LEFT JOIN categories c ON a.category_id = c.id
		LEFT JOIN towns t ON a.town_id = t.id
		LEFT JOIN suburbs s ON a.suburb_id = s.id
		WHERE a.winner_id = $1
		ORDER BY a.end_time DESC
	`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch won auctions"})
		return
	}
	defer rows.Close()

	auctions := h.scanAuctions(rows)
	c.JSON(http.StatusOK, models.AuctionListResponse{Auctions: auctions, Total: len(auctions), Page: 1, Limit: 100})
}

func formatDuration(d time.Duration) string {
	if d < time.Minute {
		return fmt.Sprintf("%ds", int(d.Seconds()))
	}
	if d < time.Hour {
		return fmt.Sprintf("%dm", int(d.Minutes()))
	}
	if d < 24*time.Hour {
		hours := int(d.Hours())
		mins := int(d.Minutes()) % 60
		return fmt.Sprintf("%dh %dm", hours, mins)
	}
	days := int(d.Hours() / 24)
	hours := int(d.Hours()) % 24
	return fmt.Sprintf("%dd %dh", days, hours)
}

// AddToWatchlist adds an auction to the user's watchlist
func (h *AuctionHandler) AddToWatchlist(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	_, err = h.db.Pool.Exec(context.Background(),
		"INSERT INTO watchlist (user_id, auction_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
		userID, auctionID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add to watchlist"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Added to watchlist"})
}

// RemoveFromWatchlist removes an auction from the user's watchlist
func (h *AuctionHandler) RemoveFromWatchlist(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	_, err = h.db.Pool.Exec(context.Background(),
		"DELETE FROM watchlist WHERE user_id = $1 AND auction_id = $2",
		userID, auctionID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove from watchlist"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Removed from watchlist"})
}

// GetWatchlist returns auctions in the user's watchlist
func (h *AuctionHandler) GetWatchlist(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	page := 1
	limit := 20
	// Simple pagination parsing
	if c.Query("page") != "" {
		fmt.Sscanf(c.Query("page"), "%d", &page)
	}
	if c.Query("limit") != "" {
		fmt.Sscanf(c.Query("limit"), "%d", &limit)
	}

	offset := (page - 1) * limit

	query := `
		SELECT a.id, a.title, a.description, a.starting_price, a.current_price, a.bid_increment,
		a.seller_id, a.category_id, a.town_id, a.suburb_id, a.status, a.condition,
		a.start_time, a.end_time, a.total_bids, a.views, a.images,
		a.is_featured, a.created_at,
		u.username as seller_username, u.avatar_url as seller_avatar,
		c.name as category_name, c.icon as category_icon,
		t.name as town_name, s.name as suburb_name
		FROM watchlist w
		JOIN auctions a ON w.auction_id = a.id
		LEFT JOIN users u ON a.seller_id = u.id
		LEFT JOIN categories c ON a.category_id = c.id
		LEFT JOIN towns t ON a.town_id = t.id
		LEFT JOIN suburbs s ON a.suburb_id = s.id
		WHERE w.user_id = $1
		ORDER BY w.created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := h.db.Pool.Query(context.Background(), query, userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch watchlist"})
		return
	}
	defer rows.Close()

	auctions := h.scanAuctions(rows)

	// Check user bid status for these auctions
	if len(auctions) > 0 {
		for i := range auctions {
			h.db.Pool.QueryRow(context.Background(),
				"SELECT EXISTS(SELECT 1 FROM bids WHERE auction_id = $1 AND bidder_id = $2)",
				auctions[i].ID, userID,
			).Scan(&auctions[i].UserHasBid)

			h.db.Pool.QueryRow(context.Background(),
				"SELECT EXISTS(SELECT 1 FROM bids WHERE auction_id = $1 AND bidder_id = $2 AND is_winning = true)",
				auctions[i].ID, userID,
			).Scan(&auctions[i].UserIsHighBidder)
		}
	}

	// Calculate total count
	var total int
	h.db.Pool.QueryRow(context.Background(), "SELECT COUNT(*) FROM watchlist WHERE user_id = $1", userID).Scan(&total)

	c.JSON(http.StatusOK, models.AuctionListResponse{
		Auctions:   auctions,
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: int(math.Ceil(float64(total) / float64(limit))),
	})
}
