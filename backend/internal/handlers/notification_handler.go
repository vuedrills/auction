package handlers

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/middleware"
	"github.com/airmass/backend/internal/models"
	"github.com/airmass/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type NotificationHandler struct {
	db  *database.DB
	hub *websocket.Hub
}

func NewNotificationHandler(db *database.DB, hub *websocket.Hub) *NotificationHandler {
	return &NotificationHandler{db: db, hub: hub}
}

func (h *NotificationHandler) GetNotifications(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	// Query notifications - include data field for chat_id etc.
	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT n.id, n.user_id, n.type, n.title, n.body, n.related_auction_id, n.data, n.is_read, n.created_at,
		       CASE WHEN n.related_auction_id IS NOT NULL THEN 
		           EXISTS(SELECT 1 FROM user_ratings r WHERE r.auction_id = n.related_auction_id AND r.rater_id = n.user_id) 
		       ELSE FALSE END
		FROM notifications n
		WHERE n.user_id = $1
		ORDER BY n.created_at DESC
		LIMIT 50
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch notifications"})
		return
	}
	defer rows.Close()

	notifications := []models.Notification{}
	for rows.Next() {
		var n models.Notification
		if err := rows.Scan(&n.ID, &n.UserID, &n.Type, &n.Title, &n.Body, &n.RelatedAuctionID, &n.Data, &n.IsRead, &n.CreatedAt, &n.HasRated); err != nil {
			continue // Skip malformed rows
		}
		notifications = append(notifications, n)
	}

	c.JSON(http.StatusOK, gin.H{"notifications": notifications})
}

func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	notifID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	_, err = h.db.Pool.Exec(context.Background(),
		"UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2",
		notifID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update notification"})
		return
	}

	c.Status(http.StatusOK)
}

func (h *NotificationHandler) MarkAllAsRead(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	_, err := h.db.Pool.Exec(context.Background(),
		"UPDATE notifications SET is_read = true WHERE user_id = $1",
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update notifications"})
		return
	}

	c.Status(http.StatusOK)
}

func (h *NotificationHandler) GetUnreadCount(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	var count int
	h.db.Pool.QueryRow(context.Background(),
		"SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = false",
		userID,
	).Scan(&count)

	c.JSON(http.StatusOK, gin.H{"count": count})
}

func (h *NotificationHandler) GetPreferences(c *gin.Context) {
	// Stub implementation - return default
	c.JSON(http.StatusOK, gin.H{
		"push_enabled":  true,
		"email_enabled": true,
	})
}

func (h *NotificationHandler) UpdatePreferences(c *gin.Context) {
	// Stub implementation
	c.Status(http.StatusOK)
}

// GetAllNotifications returns all notifications in the system (Admin)
func (h *NotificationHandler) GetAllNotifications(c *gin.Context) {
	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT n.id, n.user_id, n.type, n.title, n.body, n.is_read, n.created_at,
		u.username, COUNT(*) OVER() as total_count
		FROM notifications n
		LEFT JOIN users u ON n.user_id = u.id
		ORDER BY n.created_at DESC
		LIMIT 100
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch notifications"})
		return
	}
	defer rows.Close()

	var notifs []gin.H
	totalCount := 0
	for rows.Next() {
		var id, userID uuid.UUID
		var nType, title string
		var body *string
		var isRead bool
		var createdAt time.Time
		var username string

		rows.Scan(&id, &userID, &nType, &title, &body, &isRead, &createdAt, &username, &totalCount)
		notifs = append(notifs, gin.H{
			"id":         id,
			"user_id":    userID,
			"username":   username,
			"type":       nType,
			"title":      title,
			"body":       body,
			"is_read":    isRead,
			"created_at": createdAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"notifications": notifs, "total": totalCount})
}

// SendAdminNotification sends a notification from admin to users
func (h *NotificationHandler) SendAdminNotification(c *gin.Context) {
	var req struct {
		UserIDs  []string `json:"user_ids"` // specific users
		Category string   `json:"category"` // "everyone", "store_owners", "verified_users", "by_town"
		TownID   *string  `json:"town_id"`
		Title    string   `json:"title" binding:"required"`
		Body     string   `json:"body" binding:"required"`
		Type     string   `json:"type"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	nType := req.Type
	if nType == "" {
		nType = "system_announcement"
	}

	var targetIDs []uuid.UUID

	if len(req.UserIDs) > 0 {
		for _, idStr := range req.UserIDs {
			uid, err := uuid.Parse(idStr)
			if err == nil {
				targetIDs = append(targetIDs, uid)
			}
		}
	} else {
		// Filter by category
		query := "SELECT id FROM users WHERE is_active = true"
		var args []interface{}
		argNum := 1

		switch req.Category {
		case "store_owners":
			query = "SELECT owner_id FROM stores s JOIN users u ON s.owner_id = u.id WHERE u.is_active = true"
			if req.TownID != nil && *req.TownID != "" {
				query += fmt.Sprintf(" AND s.town_id = $%d", argNum)
				args = append(args, *req.TownID)
				argNum++
			}
		case "verified_users":
			query += " AND is_verified = true"
			if req.TownID != nil && *req.TownID != "" {
				query += fmt.Sprintf(" AND home_town_id = $%d", argNum)
				args = append(args, *req.TownID)
				argNum++
			}
		case "by_town":
			if req.TownID != nil && *req.TownID != "" {
				query += fmt.Sprintf(" AND home_town_id = $%d", argNum)
				args = append(args, *req.TownID)
				argNum++
			}
			// Support suburb if provided in req (need to add to struct)
		case "everyone":
			if req.TownID != nil && *req.TownID != "" {
				query += fmt.Sprintf(" AND home_town_id = $%d", argNum)
				args = append(args, *req.TownID)
				argNum++
			}
		}

		rows, err := h.db.Pool.Query(context.Background(), query, args...)
		if err == nil && rows != nil {
			defer rows.Close()
			for rows.Next() {
				var uid uuid.UUID
				rows.Scan(&uid)
				targetIDs = append(targetIDs, uid)
			}
		}
	}

	// Send to all targets
	for _, targetID := range targetIDs {
		h.db.Pool.Exec(context.Background(),
			"INSERT INTO notifications (user_id, type, title, body) VALUES ($1, $2, $3, $4)",
			targetID, nType, req.Title, req.Body,
		)
		h.hub.BroadcastToUser(targetID, websocket.MessageTypeNotification, gin.H{
			"title": req.Title,
			"body":  req.Body,
			"type":  nType,
		})
	}

	c.JSON(http.StatusOK, gin.H{"message": fmt.Sprintf("Notification sent successfully to %d users", len(targetIDs))})
}
