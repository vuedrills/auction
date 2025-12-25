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

	// Query notifications
	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT id, user_id, type, title, body, related_auction_id, is_read, created_at
		FROM notifications
		WHERE user_id = $1
		ORDER BY created_at DESC
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
		if err := rows.Scan(&n.ID, &n.UserID, &n.Type, &n.Title, &n.Body, &n.RelatedAuctionID, &n.IsRead, &n.CreatedAt); err != nil {
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
