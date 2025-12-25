package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/websocket"
	"github.com/google/uuid"
)

type NotificationService struct {
	db  *database.DB
	hub *websocket.Hub
}

func NewNotificationService(db *database.DB, hub *websocket.Hub) *NotificationService {
	return &NotificationService{
		db:  db,
		hub: hub,
	}
}

// SendAuctionWonNotification sends notification to auction winner
func (s *NotificationService) SendAuctionWonNotification(ctx context.Context, winnerID, auctionID, conversationID uuid.UUID, auctionTitle string, finalAmount float64) error {
	title := "🎉 You Won!"
	body := fmt.Sprintf("Congratulations! You won '%s' for R%.2f. The seller will contact you soon.", auctionTitle, finalAmount)

	data := map[string]interface{}{
		"chat_id":    conversationID,
		"auction_id": auctionID,
	}
	jsonData, _ := json.Marshal(data)

	notificationID := uuid.New()
	_, err := s.db.Pool.Exec(ctx, `
		INSERT INTO notifications (id, user_id, type, title, body, related_auction_id, data, is_read, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, false, NOW())
	`, notificationID, winnerID, "auction_won", title, body, auctionID, jsonData)

	if err != nil {
		return fmt.Errorf("failed to create winner notification: %w", err)
	}

	// Send real-time notification via WebSocket
	s.hub.BroadcastToUser(winnerID, websocket.MessageTypeNotification, map[string]interface{}{
		"id":                 notificationID,
		"type":               "auction_won",
		"title":              title,
		"body":               body,
		"related_auction_id": auctionID,
		"chat_id":            conversationID,
		"is_read":            false,
		"data":               data,
	})

	log.Printf("✅ Sent 'auction won' notification to user %s for auction %s (chat: %s)", winnerID, auctionID, conversationID)
	return nil
}

// SendAuctionSoldNotification sends notification to auction seller
func (s *NotificationService) SendAuctionSoldNotification(ctx context.Context, sellerID, auctionID, conversationID uuid.UUID, auctionTitle, winnerName string, finalAmount float64) error {
	title := "✅ Auction Sold!"
	body := fmt.Sprintf("Your auction '%s' sold to %s for R%.2f. Start chatting to arrange collection.", auctionTitle, winnerName, finalAmount)

	data := map[string]interface{}{
		"chat_id":    conversationID,
		"auction_id": auctionID,
	}
	jsonData, _ := json.Marshal(data)

	notificationID := uuid.New()
	_, err := s.db.Pool.Exec(ctx, `
		INSERT INTO notifications (id, user_id, type, title, body, related_auction_id, data, is_read, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, false, NOW())
	`, notificationID, sellerID, "auction_sold", title, body, auctionID, jsonData)

	if err != nil {
		return fmt.Errorf("failed to create seller notification: %w", err)
	}

	// Send real-time notification via WebSocket
	s.hub.BroadcastToUser(sellerID, websocket.MessageTypeNotification, map[string]interface{}{
		"id":                 notificationID,
		"type":               "auction_sold",
		"title":              title,
		"body":               body,
		"related_auction_id": auctionID,
		"chat_id":            conversationID,
		"is_read":            false,
		"data":               data,
	})

	log.Printf("✅ Sent 'auction sold' notification to user %s for auction %s (chat: %s)", sellerID, auctionID, conversationID)
	return nil
}

// SendAuctionEndedNotification sends notification when auction ends with no bids
func (s *NotificationService) SendAuctionEndedNotification(ctx context.Context, sellerID, auctionID uuid.UUID, auctionTitle string) error {
	title := "⏰ Auction Ended"
	body := fmt.Sprintf("Your auction '%s' has ended with no bids. You can create a new listing anytime.", auctionTitle)

	notificationID := uuid.New()
	_, err := s.db.Pool.Exec(ctx, `
		INSERT INTO notifications (id, user_id, type, title, body, related_auction_id, is_read, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, false, NOW())
	`, notificationID, sellerID, "auction_ended", title, body, auctionID)

	if err != nil {
		return fmt.Errorf("failed to create auction ended notification: %w", err)
	}

	// Send real-time notification via WebSocket
	s.hub.BroadcastToUser(sellerID, websocket.MessageTypeNotification, map[string]interface{}{
		"id":                 notificationID,
		"type":               "auction_ended",
		"title":              title,
		"body":               body,
		"related_auction_id": auctionID,
		"is_read":            false,
	})

	log.Printf("✅ Sent 'auction ended' notification to user %s for auction %s", sellerID, auctionID)
	return nil
}

// CreateConversation creates a conversation between winner and seller
func (s *NotificationService) CreateConversation(ctx context.Context, auctionID, participant1, participant2 uuid.UUID) (uuid.UUID, error) {
	// Check if conversation already exists
	var existingID uuid.UUID
	err := s.db.Pool.QueryRow(ctx, `
		SELECT id FROM conversations 
		WHERE auction_id = $1 
		AND ((participant_1 = $2 AND participant_2 = $3) OR (participant_1 = $3 AND participant_2 = $2))
	`, auctionID, participant1, participant2).Scan(&existingID)

	if err == nil {
		log.Printf("Conversation already exists: %s", existingID)
		return existingID, nil
	}

	// Create new conversation
	conversationID := uuid.New()
	_, err = s.db.Pool.Exec(ctx, `
		INSERT INTO conversations (id, auction_id, participant_1, participant_2, last_message_at, created_at)
		VALUES ($1, $2, $3, $4, NOW(), NOW())
	`, conversationID, auctionID, participant1, participant2)

	if err != nil {
		return uuid.Nil, fmt.Errorf("failed to create conversation: %w", err)
	}

	log.Printf("✅ Created conversation %s between %s and %s", conversationID, participant1, participant2)
	return conversationID, nil
}
