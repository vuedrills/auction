package models

import (
	"time"

	"github.com/google/uuid"
)

// Bid represents a bid on an auction
type Bid struct {
	ID         uuid.UUID `json:"id"`
	AuctionID  uuid.UUID `json:"auction_id"`
	BidderID   uuid.UUID `json:"bidder_id"`
	Amount     float64   `json:"amount"`
	IsWinning  bool      `json:"is_winning"`
	IsAutoBid  bool      `json:"is_auto_bid"`
	MaxAutoBid *float64  `json:"max_auto_bid,omitempty"`
	CreatedAt  time.Time `json:"created_at"`

	// Joined fields
	Bidder  *User    `json:"bidder,omitempty"`
	Auction *Auction `json:"auction,omitempty"`
}

// PlaceBidRequest represents bid placement input
type PlaceBidRequest struct {
	Amount     float64  `json:"amount" binding:"required,min=0.01"`
	MaxAutoBid *float64 `json:"max_auto_bid"`
}

// BidResponse represents bid placement response
type BidResponse struct {
	Bid           *Bid       `json:"bid"`
	IsHighBidder  bool       `json:"is_high_bidder"`
	Message       string     `json:"message"`
	NewPrice      float64    `json:"new_price"`
	TimeExtended  bool       `json:"time_extended"`
	NewEndTime    *time.Time `json:"new_end_time,omitempty"`
	NextBidAmount float64    `json:"next_bid_amount"` // The ONLY valid next bid
	NextIncrement float64    `json:"next_increment"`  // The increment for next bid
}

// BidHistory represents bid history list
type BidHistory struct {
	Bids          []Bid   `json:"bids"`
	TotalBids     int     `json:"total_bids"`
	HighestBid    float64 `json:"highest_bid"`
	NextBidAmount float64 `json:"next_bid_amount"` // The ONLY valid next bid
	NextIncrement float64 `json:"next_increment"`  // The increment for next bid
}
