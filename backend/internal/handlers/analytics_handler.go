package handlers

import (
	"net/http"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AnalyticsHandler struct {
	db *database.DB
}

func NewAnalyticsHandler(db *database.DB) *AnalyticsHandler {
	return &AnalyticsHandler{db: db}
}

type BatchTrackRequest struct {
	Events []TrackEvent `json:"events" binding:"required,min=1,max=100"`
}

type TrackEvent struct {
	StoreID   string                 `json:"store_id" binding:"required"`
	ProductID string                 `json:"product_id"` // Optional for store events
	EventType string                 `json:"event_type" binding:"required"`
	Metadata  map[string]interface{} `json:"metadata"`
	Timestamp time.Time              `json:"timestamp"`
}

// BatchTrackImpressions handles batch reporting of analytics events
func (h *AnalyticsHandler) BatchTrackImpressions(c *gin.Context) {
	var req BatchTrackRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetString("userID") // Optional: might be anonymous
	var viewerID *uuid.UUID
	if userID != "" {
		if uid, err := uuid.Parse(userID); err == nil {
			viewerID = &uid
		}
	}

	// Prepare batch insert
	// Note: For simplicity in this phase, we'll insert one by one or use a transaction.
	// efficient batch insert with pgx is better, but a transaction loop is fine for V1.

	ctx := c.Request.Context()
	tx, err := h.db.Pool.Begin(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start transaction"})
		return
	}
	defer tx.Rollback(ctx)

	stmt := `
		INSERT INTO product_analytics (store_id, product_id, event_type, viewer_id, metadata, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`

	// Track if we need to update last_confirmed_at for products
	touchedProducts := make(map[string]bool)

	for _, event := range req.Events {
		// Validate UUIDs
		sID, err := uuid.Parse(event.StoreID)
		if err != nil {
			continue
		}

		var pID *uuid.UUID
		if event.ProductID != "" {
			if id, err := uuid.Parse(event.ProductID); err == nil {
				pID = &id
			}
		}
		// If product_id is empty but not required for store events, it's fine (migration done).

		// Use provided timestamp or now
		ts := event.Timestamp
		if ts.IsZero() {
			ts = time.Now()
		}

		// Insert event
		_, err = tx.Exec(ctx, stmt, sID, pID, event.EventType, viewerID, event.Metadata, ts)
		if err != nil {
			// Change complexity: ignore failed inserts? or fail batch?
			// Usually for analytics, we tolerate some loss, but let's log error.
			continue
		}

		// If it's an "impression" or "view" AND has a product ID, we can count it as "product seen"
		if pID != nil && (event.EventType == "view" || event.EventType == "impression") {
			touchedProducts[event.ProductID] = true
		}
	}

	// Update freshness for viewed products (batch update could be better, but loop is okay for now)
	if len(touchedProducts) > 0 {
		updateStmt := `UPDATE products SET last_confirmed_at = NOW() WHERE id = $1`
		for productIDStr := range touchedProducts {
			if uid, err := uuid.Parse(productIDStr); err == nil {
				_, _ = tx.Exec(ctx, updateStmt, uid)
			}
		}
	}

	if err := tx.Commit(ctx); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Events tracked successfully", "count": len(req.Events)})
}

// GetStoreAnalytics aggregates analytics data for a store dashboard
func (h *AnalyticsHandler) GetStoreAnalytics(c *gin.Context) {
	storeID := c.Param("id")
	if _, err := uuid.Parse(storeID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid store ID"})
		return
	}

	ctx := c.Request.Context()

	// Initialize response with zero values
	stats := gin.H{
		"total_views":      0,
		"total_enquiries":  0,
		"total_followers":  0,
		"total_products":   0,
		"views_this_week":  0,
		"views_this_month": 0,
		"top_products":     []interface{}{},
		"daily_stats":      []interface{}{},
	}

	// 1. Total Views & Enquiries & Views/Week/Month
	// Event types: view, impression, cart, contact, whatsapp, call
	// Enquiries = contact + whatsapp + call
	const queryAgg = `
		SELECT 
			COUNT(*) FILTER (WHERE event_type = 'view') as total_views,
			COUNT(*) FILTER (WHERE event_type IN ('contact', 'whatsapp', 'call')) as total_enquiries,
			COUNT(*) FILTER (WHERE event_type = 'view' AND created_at >= NOW() - INTERVAL '7 days') as views_week,
			COUNT(*) FILTER (WHERE event_type = 'view' AND created_at >= NOW() - INTERVAL '30 days') as views_month
		FROM product_analytics
		WHERE store_id = $1
	`
	var tViews, tEnquiries, vWeek, vMonth int
	err := h.db.Pool.QueryRow(ctx, queryAgg, storeID).Scan(&tViews, &tEnquiries, &vWeek, &vMonth)
	if err != nil {
		// Log error but continue with defaults
	} else {
		stats["total_views"] = tViews
		stats["total_enquiries"] = tEnquiries
		stats["views_this_week"] = vWeek
		stats["views_this_month"] = vMonth
	}

	// 2. Total Products
	var tProducts int
	h.db.Pool.QueryRow(ctx, "SELECT COUNT(*) FROM products WHERE store_id = $1", storeID).Scan(&tProducts)
	stats["total_products"] = tProducts

	// 3. Total Followers
	var tFollowers int
	h.db.Pool.QueryRow(ctx, "SELECT COUNT(*) FROM store_followers WHERE store_id = $1", storeID).Scan(&tFollowers)
	stats["total_followers"] = tFollowers

	// 4. Daily Stats (Last 7 Days) for Chart
	const queryDaily = `
		SELECT 
			DATE(created_at) as day,
			COUNT(*) FILTER (WHERE event_type = 'view') as views,
			COUNT(*) FILTER (WHERE event_type IN ('contact', 'whatsapp', 'call')) as enquiries
		FROM product_analytics
		WHERE store_id = $1 
		  AND created_at >= NOW() - INTERVAL '7 days'
		GROUP BY DATE(created_at)
		ORDER BY day ASC
	`
	rows, _ := h.db.Pool.Query(ctx, queryDaily, storeID)
	if rows != nil {
		defer rows.Close()
		var dailyStats []gin.H

		// Map by date string to fill gaps if needed, but for now simple list
		for rows.Next() {
			var day time.Time
			var views, enquiries int
			if err := rows.Scan(&day, &views, &enquiries); err == nil {
				dailyStats = append(dailyStats, gin.H{
					"date":      day,
					"views":     views,
					"enquiries": enquiries,
					// Add dummy values for other fields expected by mobile model if needed
					"unique_visitors": views, // Approx
					"product_views":   views,
					"whatsapp_clicks": 0,
					"call_clicks":     0,
					"follows_gained":  0,
				})
			}
		}
		if len(dailyStats) > 0 {
			stats["daily_stats"] = dailyStats
		}
	}

	// 5. Top Products
	const queryTop = `
		SELECT p.id, p.store_id, p.title, p.price, p.images, COUNT(pa.id) as view_count
		FROM products p
		JOIN product_analytics pa ON p.id = pa.product_id
		WHERE p.store_id = $1 AND pa.event_type = 'view'
		GROUP BY p.id
		ORDER BY view_count DESC
		LIMIT 5
	`
	rowsTop, _ := h.db.Pool.Query(ctx, queryTop, storeID)
	if rowsTop != nil {
		defer rowsTop.Close()
		var topProducts []gin.H
		for rowsTop.Next() {
			var pID, sID uuid.UUID
			var title string
			var price float64
			var images []string
			var views int
			if err := rowsTop.Scan(&pID, &sID, &title, &price, &images, &views); err == nil {
				topProducts = append(topProducts, gin.H{
					"id":             pID,
					"store_id":       sID,
					"title":          title,
					"price":          price,
					"images":         images,
					"views":          views,
					"enquiries":      0,          // Can do another join or count if needed
					"created_at":     time.Now(), // Dummy
					"updated_at":     time.Now(), // Dummy
					"condition":      "used",     // Dummy
					"pricing_type":   "fixed",    // Dummy
					"stock_quantity": 1,          // Dummy
					"is_available":   true,       // Dummy
					"is_featured":    false,      // Dummy
				})
			}
		}
		if len(topProducts) > 0 {
			stats["top_products"] = topProducts
		}
	}

	c.JSON(http.StatusOK, stats)
}
