package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/middleware"
	"github.com/airmass/backend/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// BadgeHandler handles badge-related endpoints
type BadgeHandler struct {
	db *database.DB
}

// NewBadgeHandler creates a new badge handler
func NewBadgeHandler(db *database.DB) *BadgeHandler {
	return &BadgeHandler{db: db}
}

// GetBadges returns all available badges
func (h *BadgeHandler) GetBadges(c *gin.Context) {
	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT id, name, display_name, description, icon, category, priority, is_active, created_at
		FROM badges
		WHERE is_active = true
		ORDER BY priority DESC, display_name ASC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch badges"})
		return
	}
	defer rows.Close()

	var badges []models.Badge
	for rows.Next() {
		var b models.Badge
		if err := rows.Scan(&b.ID, &b.Name, &b.DisplayName, &b.Description, &b.Icon, &b.Category, &b.Priority, &b.IsActive, &b.CreatedAt); err != nil {
			continue
		}
		badges = append(badges, b)
	}

	c.JSON(http.StatusOK, models.BadgeListResponse{Badges: badges})
}

// GetUserBadges returns badges for a specific user
func (h *BadgeHandler) GetUserBadges(c *gin.Context) {
	userID, err := uuid.Parse(c.Param("userId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT ub.id, ub.user_id, ub.badge_id, ub.earned_at, ub.expires_at,
		       b.id, b.name, b.display_name, b.description, b.icon, b.category, b.priority
		FROM user_badges ub
		JOIN badges b ON ub.badge_id = b.id
		WHERE ub.user_id = $1 
		  AND b.is_active = true
		  AND (ub.expires_at IS NULL OR ub.expires_at > NOW())
		ORDER BY b.priority DESC
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user badges"})
		return
	}
	defer rows.Close()

	var badges []models.UserBadge
	for rows.Next() {
		var ub models.UserBadge
		var b models.Badge
		if err := rows.Scan(
			&ub.ID, &ub.UserID, &ub.BadgeID, &ub.EarnedAt, &ub.ExpiresAt,
			&b.ID, &b.Name, &b.DisplayName, &b.Description, &b.Icon, &b.Category, &b.Priority,
		); err != nil {
			continue
		}
		ub.Badge = &b
		badges = append(badges, ub)
	}

	c.JSON(http.StatusOK, models.UserBadgesResponse{Badges: badges})
}

// GetMyBadges returns badges for the current user
func (h *BadgeHandler) GetMyBadges(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT ub.id, ub.user_id, ub.badge_id, ub.earned_at, ub.expires_at,
		       b.id, b.name, b.display_name, b.description, b.icon, b.category, b.priority
		FROM user_badges ub
		JOIN badges b ON ub.badge_id = b.id
		WHERE ub.user_id = $1 
		  AND b.is_active = true
		  AND (ub.expires_at IS NULL OR ub.expires_at > NOW())
		ORDER BY b.priority DESC
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch badges"})
		return
	}
	defer rows.Close()

	var badges []models.UserBadge
	for rows.Next() {
		var ub models.UserBadge
		var b models.Badge
		if err := rows.Scan(
			&ub.ID, &ub.UserID, &ub.BadgeID, &ub.EarnedAt, &ub.ExpiresAt,
			&b.ID, &b.Name, &b.DisplayName, &b.Description, &b.Icon, &b.Category, &b.Priority,
		); err != nil {
			continue
		}
		ub.Badge = &b
		badges = append(badges, ub)
	}

	c.JSON(http.StatusOK, models.UserBadgesResponse{Badges: badges})
}

// SubmitVerification submits an ID verification request
func (h *BadgeHandler) SubmitVerification(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	var req models.SubmitVerificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if user already has a pending request
	var existingCount int
	h.db.Pool.QueryRow(context.Background(),
		"SELECT COUNT(*) FROM verification_requests WHERE user_id = $1 AND status = 'pending'",
		userID,
	).Scan(&existingCount)

	if existingCount > 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You already have a pending verification request"})
		return
	}

	// Check if user is already verified
	var hasVerifiedBadge bool
	h.db.Pool.QueryRow(context.Background(), `
		SELECT EXISTS(
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = $1 AND b.name = 'id_verified'
		)
	`, userID).Scan(&hasVerifiedBadge)

	if hasVerifiedBadge {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You are already verified"})
		return
	}

	// Create verification request
	var requestID uuid.UUID
	err := h.db.Pool.QueryRow(context.Background(), `
		INSERT INTO verification_requests (user_id, id_document_url, selfie_url, status, created_at)
		VALUES ($1, $2, $3, 'pending', $4)
		RETURNING id
	`, userID, req.IDDocumentURL, req.SelfieURL, time.Now()).Scan(&requestID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to submit verification request"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":    "Verification request submitted successfully",
		"request_id": requestID,
		"status":     "pending",
	})
}

// GetMyVerificationStatus gets the current user's verification status
func (h *BadgeHandler) GetMyVerificationStatus(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	// Check if already verified
	var isVerified bool
	h.db.Pool.QueryRow(context.Background(), `
		SELECT EXISTS(
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = $1 AND b.name = 'id_verified'
		)
	`, userID).Scan(&isVerified)

	if isVerified {
		c.JSON(http.StatusOK, gin.H{
			"is_verified":     true,
			"pending_request": false,
			"status":          "approved",
		})
		return
	}

	// Check for pending request
	var status string
	var createdAt time.Time
	err := h.db.Pool.QueryRow(context.Background(), `
		SELECT status, created_at FROM verification_requests 
		WHERE user_id = $1 
		ORDER BY created_at DESC 
		LIMIT 1
	`, userID).Scan(&status, &createdAt)

	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"is_verified":     false,
			"pending_request": false,
			"status":          "not_submitted",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"is_verified":     status == "approved",
		"pending_request": status == "pending",
		"status":          status,
		"submitted_at":    createdAt,
	})
}

// AwardBadge awards a badge to a user (internal/admin use)
func (h *BadgeHandler) AwardBadge(userID uuid.UUID, badgeName string) error {
	_, err := h.db.Pool.Exec(context.Background(), `
		INSERT INTO user_badges (user_id, badge_id, earned_at)
		SELECT $1, id, NOW()
		FROM badges
		WHERE name = $2
		ON CONFLICT (user_id, badge_id) DO NOTHING
	`, userID, badgeName)
	return err
}

// RevokeBadge removes a badge from a user (internal/admin use)
func (h *BadgeHandler) RevokeBadge(userID uuid.UUID, badgeName string) error {
	_, err := h.db.Pool.Exec(context.Background(), `
		DELETE FROM user_badges
		WHERE user_id = $1 AND badge_id = (SELECT id FROM badges WHERE name = $2)
	`, userID, badgeName)
	return err
}

// ReviewVerification reviews a verification request (admin only)
func (h *BadgeHandler) ReviewVerification(c *gin.Context) {
	requestID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

	reviewerID, _ := middleware.GetUserID(c)

	var req models.ReviewVerificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get the verification request
	var userID uuid.UUID
	var currentStatus string
	err = h.db.Pool.QueryRow(context.Background(),
		"SELECT user_id, status FROM verification_requests WHERE id = $1",
		requestID,
	).Scan(&userID, &currentStatus)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Verification request not found"})
		return
	}

	if currentStatus != "pending" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Request has already been reviewed"})
		return
	}

	// Update the request
	now := time.Now()
	_, err = h.db.Pool.Exec(context.Background(), `
		UPDATE verification_requests 
		SET status = $2, reviewer_notes = $3, reviewed_at = $4, reviewed_by = $5
		WHERE id = $1
	`, requestID, req.Status, req.ReviewerNotes, now, reviewerID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update verification request"})
		return
	}

	// If approved, award the ID verified badge
	if req.Status == models.VerificationApproved {
		h.AwardBadge(userID, "id_verified")

		// Also mark user as verified in users table
		h.db.Pool.Exec(context.Background(),
			"UPDATE users SET is_verified = true WHERE id = $1",
			userID,
		)
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Verification request reviewed",
		"status":  req.Status,
		"user_id": userID,
	})
}

// GetPendingVerifications gets all pending verification requests (admin)
func (h *BadgeHandler) GetPendingVerifications(c *gin.Context) {
	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT vr.id, vr.user_id, vr.id_document_url, vr.selfie_url, vr.status, vr.created_at,
		       u.username, u.full_name, u.email
		FROM verification_requests vr
		JOIN users u ON vr.user_id = u.id
		WHERE vr.status = 'pending'
		ORDER BY vr.created_at ASC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch verification requests"})
		return
	}
	defer rows.Close()

	var requests []models.VerificationRequest
	for rows.Next() {
		var vr models.VerificationRequest
		var u models.User
		if err := rows.Scan(
			&vr.ID, &vr.UserID, &vr.IDDocumentURL, &vr.SelfieURL, &vr.Status, &vr.CreatedAt,
			&u.Username, &u.FullName, &u.Email,
		); err != nil {
			continue
		}
		vr.User = &u
		requests = append(requests, vr)
	}

	c.JSON(http.StatusOK, gin.H{"requests": requests, "total": len(requests)})
}
