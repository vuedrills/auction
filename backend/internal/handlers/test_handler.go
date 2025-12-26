package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/models"
	"github.com/airmass/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// TestHandler handles test-only endpoints
type TestHandler struct {
	db  *database.DB
	hub *websocket.Hub
}

// NewTestHandler creates a new test handler
func NewTestHandler(db *database.DB, hub *websocket.Hub) *TestHandler {
	return &TestHandler{db: db, hub: hub}
}

// EndAuctionTest forces an auction to end immediately (FOR TESTING ONLY)
func (h *TestHandler) EndAuctionTest(c *gin.Context) {
	auctionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	// 1. Get auction details to determine winner
	var auction models.Auction
	var winnerID *uuid.UUID
	var currentPrice *float64
	var sellerID uuid.UUID
	var title string

	// Start transaction
	tx, err := h.db.Pool.Begin(context.Background())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}
	defer tx.Rollback(context.Background())

	// Lock auction
	err = tx.QueryRow(context.Background(),
		`SELECT id, title, seller_id, current_price FROM auctions WHERE id = $1 FOR UPDATE`,
		auctionID,
	).Scan(&auction.ID, &title, &sellerID, &currentPrice)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Auction not found"})
		return
	}

	// Find highest bidder
	err = tx.QueryRow(context.Background(),
		`SELECT bidder_id FROM bids WHERE auction_id = $1 AND is_winning = true`,
		auctionID,
	).Scan(&winnerID)
	// It's okay if there are no bids, winnerID will be nil

	// Update auction status
	status := "ended"
	if winnerID != nil {
		status = "sold"
	}

	_, err = tx.Exec(context.Background(),
		`UPDATE auctions 
		 SET status = $1, end_time = NOW(), winner_id = $2, updated_at = NOW() 
		 WHERE id = $3`,
		status, winnerID, auctionID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update auction"})
		return
	}

	if err = tx.Commit(context.Background()); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit"})
		return
	}

	// NOTIFICATIONS

	// 1. Notify Winner
	if winnerID != nil {
		// Include seller ID so winner can rate the seller
		winnerData := map[string]interface{}{
			"related_user_id": sellerID.String(),
		}
		winnerDataJSON, _ := json.Marshal(winnerData)

		h.hub.BroadcastToUser(*winnerID, websocket.MessageTypeAuctionWon, gin.H{
			"auction_id":      auctionID,
			"title":           "You Won!",
			"body":            fmt.Sprintf("You won '%s' for $%.2f", title, *currentPrice),
			"amount":          currentPrice,
			"related_user_id": sellerID.String(),
		})

		h.db.Pool.Exec(context.Background(),
			`INSERT INTO notifications (user_id, type, title, body, related_auction_id, data)
			 VALUES ($1, 'auction_won', 'You won the auction!', $2, $3, $4)`,
			winnerID, fmt.Sprintf("You won '%s'", title), auctionID, winnerDataJSON,
		)
	}

	// 2. Notify Seller
	var sellerData []byte
	if winnerID != nil {
		// Include winner ID so seller can rate the buyer
		sellerDataMap := map[string]interface{}{
			"related_user_id": winnerID.String(),
		}
		sellerData, _ = json.Marshal(sellerDataMap)
	}

	h.hub.BroadcastToUser(sellerID, websocket.MessageTypeAuctionSold, gin.H{
		"auction_id": auctionID,
		"title":      "Your auction ended",
		"body":       fmt.Sprintf("Auction '%s' has ended", title),
		"amount":     currentPrice,
		"related_user_id": func() string {
			if winnerID != nil {
				return winnerID.String()
			} else {
				return ""
			}
		}(),
	})

	h.db.Pool.Exec(context.Background(),
		`INSERT INTO notifications (user_id, type, title, body, related_auction_id, data)
		 VALUES ($1, 'auction_sold', 'Your auction ended', $2, $3, $4)`,
		sellerID, fmt.Sprintf("Auction '%s' has ended", title), auctionID, sellerData,
	)

	c.JSON(http.StatusOK, gin.H{
		"message":   "Auction ended successfully",
		"status":    status,
		"winner_id": winnerID,
	})
}
