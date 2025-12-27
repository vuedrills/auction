package models

import (
	"time"
)

// ShopConversation represents a chat thread between a customer and a store
type ShopConversation struct {
	ID                  string     `json:"id" db:"id"`
	StoreID             string     `json:"store_id" db:"store_id"`
	CustomerID          string     `json:"customer_id" db:"customer_id"`
	ProductID           *string    `json:"product_id,omitempty" db:"product_id"`
	LastMessagePreview  *string    `json:"last_message_preview,omitempty" db:"last_message_preview"`
	LastMessageAt       *time.Time `json:"last_message_at,omitempty" db:"last_message_at"`
	UnreadCountStore    int        `json:"unread_count_store" db:"unread_count_store"`
	UnreadCountCustomer int        `json:"unread_count_customer" db:"unread_count_customer"`
	Status              string     `json:"status" db:"status"`
	CreatedAt           time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at" db:"updated_at"`

	// Joined fields (optional, populated by handler)
	StoreName      string  `json:"store_name,omitempty"`
	StoreLogo      *string `json:"store_logo,omitempty"`
	CustomerName   string  `json:"customer_name,omitempty"`
	CustomerAvatar *string `json:"customer_avatar,omitempty"`
	ProductTitle   *string `json:"product_title,omitempty"`
}

// ShopMessage represents a single message in a shop conversation
type ShopMessage struct {
	ID             string    `json:"id" db:"id"`
	ConversationID string    `json:"conversation_id" db:"conversation_id"`
	SenderID       string    `json:"sender_id" db:"sender_id"`
	Content        string    `json:"content" db:"content"`
	MessageType    string    `json:"message_type" db:"message_type"`
	ProductID      *string   `json:"product_id,omitempty" db:"product_id"`
	AttachmentURL  *string   `json:"attachment_url,omitempty" db:"attachment_url"`
	IsRead         bool      `json:"is_read" db:"is_read"`
	CreatedAt      time.Time `json:"created_at" db:"created_at"`
}

// CreateShopConversationRequest is the request to start a new shop conversation
type CreateShopConversationRequest struct {
	StoreID   string  `json:"store_id" binding:"required"`
	ProductID *string `json:"product_id,omitempty"`
	Message   string  `json:"message" binding:"required"`
}

// SendShopMessageRequest is the request to send a message in a shop conversation
type SendShopMessageRequest struct {
	Content       string  `json:"content" binding:"required"`
	MessageType   string  `json:"message_type,omitempty"`
	ProductID     *string `json:"product_id,omitempty"`
	AttachmentURL *string `json:"attachment_url,omitempty"`
}
