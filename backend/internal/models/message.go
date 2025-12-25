package models

import (
	"time"

	"github.com/google/uuid"
)

// Conversation represents a chat conversation
type Conversation struct {
	ID                 uuid.UUID  `json:"id"`
	AuctionID          *uuid.UUID `json:"auction_id,omitempty"`
	Participant1       uuid.UUID  `json:"participant_1"`
	Participant2       uuid.UUID  `json:"participant_2"`
	LastMessagePreview *string    `json:"last_message_preview,omitempty"`
	LastMessageAt      *time.Time `json:"last_message_at,omitempty"`
	UnreadCount1       int        `json:"unread_count_1"`
	UnreadCount2       int        `json:"unread_count_2"`
	CreatedAt          time.Time  `json:"created_at"`

	// Joined fields
	Auction     *Auction `json:"auction,omitempty"`
	OtherUser   *User    `json:"other_user,omitempty"`
	UnreadCount int      `json:"unread_count,omitempty"`
}

// MessageType represents message content type
type MessageType string

const (
	MessageTypeText   MessageType = "text"
	MessageTypeImage  MessageType = "image"
	MessageTypeSystem MessageType = "system"
)

// Message represents a chat message
type Message struct {
	ID             uuid.UUID   `json:"id"`
	ConversationID uuid.UUID   `json:"conversation_id"`
	SenderID       uuid.UUID   `json:"sender_id"`
	Content        string      `json:"content"`
	MessageType    MessageType `json:"message_type"`
	AttachmentURL  *string     `json:"attachment_url,omitempty"`
	IsRead         bool        `json:"is_read"`
	CreatedAt      time.Time   `json:"created_at"`

	// Joined fields
	Sender *User `json:"sender,omitempty"`
}

// SendMessageRequest represents message sending input
type SendMessageRequest struct {
	Content       string      `json:"content" binding:"required,min=1,max=5000"`
	MessageType   MessageType `json:"message_type"`
	AttachmentURL *string     `json:"attachment_url"`
}

// CreateConversationRequest represents conversation creation input
type CreateConversationRequest struct {
	RecipientID uuid.UUID  `json:"recipient_id" binding:"required"`
	AuctionID   *uuid.UUID `json:"auction_id"`
	Message     string     `json:"message" binding:"required,min=1"`
}

// ConversationListResponse represents paginated conversations
type ConversationListResponse struct {
	Conversations []Conversation `json:"conversations"`
	Total         int            `json:"total"`
	Page          int            `json:"page"`
	Limit         int            `json:"limit"`
}

// MessageListResponse represents paginated messages
type MessageListResponse struct {
	Messages []Message `json:"messages"`
	Total    int       `json:"total"`
	Page     int       `json:"page"`
	Limit    int       `json:"limit"`
}
