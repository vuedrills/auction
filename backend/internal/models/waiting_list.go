package models

import (
	"time"

	"github.com/google/uuid"
)

// WaitingListStatus represents waiting list entry state
type WaitingListStatus string

const (
	WaitingStatusWaiting       WaitingListStatus = "waiting"
	WaitingStatusNotified      WaitingListStatus = "notified"
	WaitingStatusSlotAvailable WaitingListStatus = "slot_available"
	WaitingStatusExpired       WaitingListStatus = "expired"
	WaitingStatusCancelled     WaitingListStatus = "cancelled"
)

// WaitingListEntry represents a waiting list entry
type WaitingListEntry struct {
	ID                    uuid.UUID         `json:"id"`
	UserID                uuid.UUID         `json:"user_id"`
	CategoryID            uuid.UUID         `json:"category_id"`
	TownID                uuid.UUID         `json:"town_id"`
	Position              int               `json:"position"`
	Status                WaitingListStatus `json:"status"`
	AuctionTitle          *string           `json:"auction_title,omitempty"`
	AuctionDescription    *string           `json:"auction_description,omitempty"`
	ExpectedStartingPrice *float64          `json:"expected_starting_price,omitempty"`
	NotifiedAt            *time.Time        `json:"notified_at,omitempty"`
	ExpiresAt             *time.Time        `json:"expires_at,omitempty"`
	CreatedAt             time.Time         `json:"created_at"`

	// Joined fields
	User     *User     `json:"user,omitempty"`
	Category *Category `json:"category,omitempty"`
	Town     *Town     `json:"town,omitempty"`
}

// JoinWaitingListRequest represents waiting list join input
type JoinWaitingListRequest struct {
	CategoryID            uuid.UUID `json:"category_id" binding:"required"`
	AuctionTitle          string    `json:"auction_title" binding:"required,min=5,max=200"`
	AuctionDescription    string    `json:"auction_description"`
	ExpectedStartingPrice *float64  `json:"expected_starting_price"`
}

// WaitingListResponse represents waiting list status response
type WaitingListResponse struct {
	Entry         *WaitingListEntry `json:"entry"`
	Position      int               `json:"position"`
	EstimatedWait string            `json:"estimated_wait"`
	AheadOfYou    int               `json:"ahead_of_you"`
}
