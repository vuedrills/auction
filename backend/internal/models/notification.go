package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// NotificationType represents notification category
type NotificationType string

const (
	NotificationOutbid          NotificationType = "outbid"
	NotificationAuctionWon      NotificationType = "auction_won"
	NotificationAuctionEnded    NotificationType = "auction_ended"
	NotificationAuctionStarting NotificationType = "auction_starting"
	NotificationNewBid          NotificationType = "new_bid"
	NotificationPaymentReminder NotificationType = "payment_reminder"
	NotificationSlotAvailable   NotificationType = "slot_available"
	NotificationNewAuction      NotificationType = "new_auction_in_town"
	NotificationSystemAnnounce  NotificationType = "system_announcement"
	NotificationMessage         NotificationType = "new_message"
)

// Notification represents a user notification
type Notification struct {
	ID               uuid.UUID        `json:"id"`
	UserID           uuid.UUID        `json:"user_id"`
	Type             NotificationType `json:"type"`
	Title            string           `json:"title"`
	Body             *string          `json:"body,omitempty"`
	Data             json.RawMessage  `json:"data,omitempty"`
	RelatedAuctionID *uuid.UUID       `json:"auction_id,omitempty"`
	IsRead           bool             `json:"is_read"`
	IsPushSent       bool             `json:"is_push_sent"`
	CreatedAt        time.Time        `json:"created_at"`

	// Joined fields
	RelatedAuction *Auction `json:"related_auction,omitempty"`
}

// NotificationListResponse represents paginated notifications
type NotificationListResponse struct {
	Notifications []Notification `json:"notifications"`
	UnreadCount   int            `json:"unread_count"`
	Total         int            `json:"total"`
	Page          int            `json:"page"`
	Limit         int            `json:"limit"`
}
