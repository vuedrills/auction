package models

import (
	"time"

	"github.com/google/uuid"
)

// AuctionStatus represents auction state
type AuctionStatus string

const (
	AuctionStatusDraft      AuctionStatus = "draft"
	AuctionStatusPending    AuctionStatus = "pending"
	AuctionStatusActive     AuctionStatus = "active"
	AuctionStatusEndingSoon AuctionStatus = "ending_soon"
	AuctionStatusEnded      AuctionStatus = "ended"
	AuctionStatusSold       AuctionStatus = "sold"
	AuctionStatusCancelled  AuctionStatus = "cancelled"
)

// Auction represents an auction listing
type Auction struct {
	ID                uuid.UUID     `json:"id"`
	Title             string        `json:"title"`
	Description       *string       `json:"description,omitempty"`
	StartingPrice     float64       `json:"starting_price"`
	CurrentPrice      *float64      `json:"current_price,omitempty"`
	ReservePrice      *float64      `json:"reserve_price,omitempty"`
	BidIncrement      float64       `json:"bid_increment"`
	SellerID          uuid.UUID     `json:"seller_id"`
	WinnerID          *uuid.UUID    `json:"winner_id,omitempty"`
	CategoryID        uuid.UUID     `json:"category_id"`
	TownID            uuid.UUID     `json:"town_id"`
	SuburbID          *uuid.UUID    `json:"suburb_id,omitempty"`
	Status            AuctionStatus `json:"status"`
	Condition         string        `json:"condition"`
	StartTime         *time.Time    `json:"start_time,omitempty"`
	EndTime           *time.Time    `json:"end_time,omitempty"`
	OriginalEndTime   *time.Time    `json:"original_end_time,omitempty"`
	AntiSnipeMinutes  int           `json:"anti_snipe_minutes"`
	TotalBids         int           `json:"total_bids"`
	Views             int           `json:"views"`
	Images            []string      `json:"images"`
	IsFeatured        bool          `json:"is_featured"`
	AllowOffers       bool          `json:"allow_offers"`
	PickupLocation    *string       `json:"pickup_location,omitempty"`
	ShippingAvailable bool          `json:"shipping_available"`
	CreatedAt         time.Time     `json:"created_at"`
	UpdatedAt         time.Time     `json:"updated_at"`

	// Joined fields
	Seller   *User     `json:"seller,omitempty"`
	Winner   *User     `json:"winner,omitempty"`
	Category *Category `json:"category,omitempty"`
	Town     *Town     `json:"town,omitempty"`
	Suburb   *Suburb   `json:"suburb,omitempty"`

	// Computed fields
	TimeRemaining    string   `json:"time_remaining,omitempty"`
	IsEndingSoon     bool     `json:"is_ending_soon,omitempty"`
	MinNextBid       float64  `json:"min_next_bid,omitempty"`
	UserIsHighBidder bool     `json:"user_is_high_bidder,omitempty"`
	UserHasBid       bool     `json:"user_has_bid,omitempty"`
	Tags             []string `json:"tags,omitempty"` // hot, trending, bidding_war, ending_soon
}

// CreateAuctionRequest represents auction creation input
type CreateAuctionRequest struct {
	Title             string     `json:"title" binding:"required,min=5,max=200"`
	Description       string     `json:"description"`
	StartingPrice     float64    `json:"starting_price" binding:"required,min=0.01"`
	ReservePrice      *float64   `json:"reserve_price"`
	BidIncrement      float64    `json:"bid_increment"`
	CategoryID        uuid.UUID  `json:"category_id" binding:"required"`
	SuburbID          *uuid.UUID `json:"suburb_id"`
	Condition         string     `json:"condition" binding:"required,oneof=new like_new used good fair poor"`
	DurationHours     int        `json:"duration_hours"`
	Images            []string   `json:"images" binding:"required,min=1,max=10"`
	AllowOffers       bool       `json:"allow_offers"`
	PickupLocation    *string    `json:"pickup_location"`
	ShippingAvailable bool       `json:"shipping_available"`
}

// UpdateAuctionRequest represents auction update input
type UpdateAuctionRequest struct {
	Title             *string  `json:"title"`
	Description       *string  `json:"description"`
	Images            []string `json:"images"`
	PickupLocation    *string  `json:"pickup_location"`
	ShippingAvailable *bool    `json:"shipping_available"`
}

// AuctionFilters represents query filters for auctions
type AuctionFilters struct {
	TownID     *string        `form:"town_id"`
	SuburbID   *string        `form:"suburb_id"`
	CategoryID *string        `form:"category_id"`
	SellerID   *string        `form:"seller_id"`
	Status     *AuctionStatus `form:"status"`
	Search     *string        `form:"search"`
	MinPrice   *float64       `form:"min_price"`
	MaxPrice   *float64       `form:"max_price"`
	SortBy     string         `form:"sort_by"`
	SortOrder  string         `form:"sort_order"`
	Page       int            `form:"page"`
	Limit      int            `form:"limit"`
}

// AuctionListResponse represents paginated auction list
type AuctionListResponse struct {
	Auctions   []Auction `json:"auctions"`
	Total      int       `json:"total"`
	Page       int       `json:"page"`
	Limit      int       `json:"limit"`
	TotalPages int       `json:"total_pages"`
}
