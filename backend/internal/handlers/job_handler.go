package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type JobHandler struct {
	db *database.DB
}

func NewJobHandler(db *database.DB) *JobHandler {
	return &JobHandler{db: db}
}

// CheckStaleStores identifies stores with active products that haven't been confirmed in 30 days
// and sends them a notification.
func (h *JobHandler) CheckStaleStores(c *gin.Context) {
	ctx := context.Background()

	// 1. Find stores where ALL active products are stale (> 30 days old confirmation)
	// We want stores that HAVE products, but none are fresh.
	query := `
		SELECT s.id, s.user_id, s.store_name, MAX(p.last_confirmed_at) as last_activity
		FROM stores s
		JOIN products p ON s.id = p.store_id
		WHERE s.is_active = true AND p.is_available = true
		GROUP BY s.id
		HAVING MAX(p.last_confirmed_at) < NOW() - INTERVAL '30 days'
	`

	rows, err := h.db.Pool.Query(ctx, query)
	if err != nil {
		fmt.Printf("Job Query Error: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query stale stores"})
		return
	}
	defer rows.Close()

	fmt.Println("Job Query Executed. Iterating rows...")
	nudgedCount := 0
	for rows.Next() {
		fmt.Println("Row found!")
		var storeID, userID uuid.UUID
		var storeName string
		var lastActivity time.Time

		if err := rows.Scan(&storeID, &userID, &storeName, &lastActivity); err != nil {
			fmt.Printf("Error scanning row: %v\n", err)
			continue
		}
		fmt.Printf("Processing stale store: %s (%s)\n", storeName, storeID)

		// 2. Check if we already sent a notification recently...

		// 2. Check if we already sent a notification recently (e.g., in last 7 days)
		// We use the notifications table. We'll look for a specific type/content.
		// For simplicity, we can just check if *any* notification of type 'system_alert'
		// with metadata={'type': 'freshness_nudge'} exists in last 7 days.
		// Since we don't have rich metadata filtering efficiently, we might just insert and
		// rely on the user clearing it, OR we'll skip complex dedup for this MVP step.

		// Let's send the notification.
		message := fmt.Sprintf("Your store '%s' is looking dusty! View your dashboard to boost visibility.", storeName)

		// JSON marshal metadata
		metaJSON, _ := json.Marshal(map[string]string{"type": "freshness_nudge", "store_id": storeID.String()})

		// Insert notification
		_, err := h.db.Pool.Exec(ctx, `
			INSERT INTO notifications (user_id, type, title, body, data)
			VALUES ($1, 'system', 'Boost Your Visibility', $2, $3)
		`, userID, message, metaJSON)

		if err == nil {
			nudgedCount++
		} else {
			fmt.Printf("Error inserting notification: %v\n", err)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      "Stale store check completed",
		"stores_found": nudgedCount, // This is technically stores nudged
	})
}
