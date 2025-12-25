package models

import (
	"time"

	"github.com/google/uuid"
)

// Category represents an auction category
type Category struct {
	ID          uuid.UUID  `json:"id"`
	Name        string     `json:"name"`
	Icon        *string    `json:"icon,omitempty"`
	Description *string    `json:"description,omitempty"`
	ParentID    *uuid.UUID `json:"parent_id,omitempty"`
	SortOrder   int        `json:"sort_order"`
	IsActive    bool       `json:"is_active"`
	CreatedAt   time.Time  `json:"created_at"`

	// Aggregated fields
	ActiveAuctions int        `json:"active_auctions,omitempty"`
	Children       []Category `json:"children,omitempty"`
}

// CategorySlot represents slot configuration per category per town
type CategorySlot struct {
	ID                   uuid.UUID `json:"id"`
	CategoryID           uuid.UUID `json:"category_id"`
	TownID               uuid.UUID `json:"town_id"`
	MaxActiveAuctions    int       `json:"max_active_auctions"`
	AuctionDurationHours int       `json:"auction_duration_hours"`
	CreatedAt            time.Time `json:"created_at"`

	// Computed fields
	CurrentActive    int  `json:"current_active,omitempty"`
	HasAvailableSlot bool `json:"has_available_slot,omitempty"`
	WaitingCount     int  `json:"waiting_count,omitempty"`
}

// CategoryWithSlots includes slot availability for a town
type CategoryWithSlots struct {
	Category
	SlotInfo *CategorySlot `json:"slot_info,omitempty"`
}
