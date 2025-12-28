package handlers

import (
	"context"
	"log"
	"net/http"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AdminHandler struct {
	db *database.DB
}

func NewAdminHandler(db *database.DB) *AdminHandler {
	return &AdminHandler{db: db}
}

// ListAdmins returns all users with is_admin = true
func (h *AdminHandler) ListAdmins(c *gin.Context) {
	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT id, email, username, full_name, is_active, created_at
		FROM users
		WHERE is_admin = TRUE
		ORDER BY created_at DESC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch admins"})
		return
	}
	defer rows.Close()

	var admins []models.User
	for rows.Next() {
		var u models.User
		err := rows.Scan(&u.ID, &u.Email, &u.Username, &u.FullName, &u.IsActive, &u.CreatedAt)
		if err != nil {
			log.Printf("Error scanning admin: %v", err)
			continue
		}
		admins = append(admins, u)
	}

	c.JSON(http.StatusOK, gin.H{"admins": admins})
}

// AddAdmin elevates a user to admin status
func (h *AdminHandler) AddAdmin(c *gin.Context) {
	var req struct {
		UserID string `json:"user_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User ID is required"})
		return
	}

	uid, err := uuid.Parse(req.UserID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid User ID"})
		return
	}

	_, err = h.db.Pool.Exec(context.Background(),
		"UPDATE users SET is_admin = TRUE WHERE id = $1", uid,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User elevated to admin"})
}

// RemoveAdmin demotes an admin to regular user
func (h *AdminHandler) RemoveAdmin(c *gin.Context) {
	userID := c.Param("id")
	uid, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid User ID"})
		return
	}

	_, err = h.db.Pool.Exec(context.Background(),
		"UPDATE users SET is_admin = FALSE WHERE id = $1", uid,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Admin rights removed"})
}

// GetPlatformStats returns overall system statistics for the admin dashboard
func (h *AdminHandler) GetPlatformStats(c *gin.Context) {
	var totalUsers int
	var activeAuctions int
	var totalAuctions int
	var totalSales float64
	var activeStores int
	var totalBids int

	// Get total users
	h.db.Pool.QueryRow(context.Background(), "SELECT COUNT(*) FROM users").Scan(&totalUsers)

	// Get active auctions
	h.db.Pool.QueryRow(context.Background(), "SELECT COUNT(*) FROM auctions WHERE status = 'active' OR status = 'ending_soon'").Scan(&activeAuctions)

	// Get total auctions (all statuses)
	h.db.Pool.QueryRow(context.Background(), "SELECT COUNT(*) FROM auctions").Scan(&totalAuctions)

	// Get total sales (sum of winning bid amounts)
	h.db.Pool.QueryRow(context.Background(), "SELECT COALESCE(SUM(current_price), 0) FROM auctions WHERE status = 'sold'").Scan(&totalSales)

	// Get active stores
	h.db.Pool.QueryRow(context.Background(), "SELECT COUNT(*) FROM stores").Scan(&activeStores)

	// Get total bids
	h.db.Pool.QueryRow(context.Background(), "SELECT COUNT(*) FROM bids").Scan(&totalBids)

	c.JSON(http.StatusOK, gin.H{
		"total_users":     totalUsers,
		"active_auctions": activeAuctions,
		"total_auctions":  totalAuctions,
		"total_sales":     totalSales,
		"active_stores":   activeStores,
		"total_bids":      totalBids,
	})
}
