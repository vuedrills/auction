package handlers

import (
	"context"
	"net/http"

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
