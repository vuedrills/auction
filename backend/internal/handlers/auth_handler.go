package handlers

import (
	"context"
	"crypto/rand"
	"fmt"
	"net/http"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/email"
	"github.com/airmass/backend/internal/fcm"
	"github.com/airmass/backend/internal/models"
	"github.com/airmass/backend/pkg/jwt"
	"github.com/airmass/backend/pkg/password"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AuthHandler handles authentication endpoints
type AuthHandler struct {
	db           *database.DB
	jwtService   *jwt.Service
	emailService *email.EmailService
	fcmService   *fcm.FCMService
}

// NewAuthHandler creates a new auth handler
func NewAuthHandler(db *database.DB, jwtService *jwt.Service, emailService *email.EmailService, fcmService *fcm.FCMService) *AuthHandler {
	return &AuthHandler{
		db:           db,
		jwtService:   jwtService,
		emailService: emailService,
		fcmService:   fcmService,
	}
}

// Register handles user registration
func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Hash password
	hashedPassword, err := password.Hash(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process password"})
		return
	}

	// Check if email already exists
	var exists bool
	err = h.db.Pool.QueryRow(context.Background(),
		"SELECT EXISTS(SELECT 1 FROM users WHERE email = $1 OR username = $2)",
		req.Email, req.Username).Scan(&exists)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}
	if exists {
		c.JSON(http.StatusConflict, gin.H{"error": "Email or username already exists"})
		return
	}

	// Create user
	var userID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(),
		`INSERT INTO users (email, username, password_hash, full_name, home_town_id, home_suburb_id, phone)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id`,
		req.Email, req.Username, hashedPassword, req.FullName, req.HomeTownID, req.HomeSuburbID, req.Phone,
	).Scan(&userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
		return
	}

	// Generate token
	token, expiresAt, err := h.jwtService.GenerateToken(userID, req.Email, req.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	// Get user with town info
	user := h.getUserByID(userID)

	c.JSON(http.StatusCreated, models.AuthResponse{
		Token:     token,
		ExpiresAt: expiresAt,
		User:      user,
	})
}

// Login handles user login
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find user by email or username
	var user models.User
	err := h.db.Pool.QueryRow(context.Background(),
		`SELECT id, email, username, password_hash, full_name, avatar_url, phone, 
		is_verified, is_active, home_town_id, home_suburb_id, created_at, updated_at
		FROM users WHERE email = $1 OR username = $1`,
		req.Email,
	).Scan(
		&user.ID, &user.Email, &user.Username, &user.PasswordHash, &user.FullName,
		&user.AvatarURL, &user.Phone, &user.IsVerified, &user.IsActive,
		&user.HomeTownID, &user.HomeSuburbID, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// Verify password
	if !password.Verify(req.Password, user.PasswordHash) {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// Check if user is active
	if !user.IsActive {
		c.JSON(http.StatusForbidden, gin.H{"error": "Account is disabled"})
		return
	}

	// Generate token
	token, expiresAt, err := h.jwtService.GenerateToken(user.ID, user.Email, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	// Get user with full info
	fullUser := h.getUserByID(user.ID)

	c.JSON(http.StatusOK, models.AuthResponse{
		Token:     token,
		ExpiresAt: expiresAt,
		User:      fullUser,
	})
}

// RefreshToken handles token refresh
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	userID, _ := c.Get("user_id")
	email, _ := c.Get("user_email")
	username, _ := c.Get("user_username")

	token, expiresAt, err := h.jwtService.GenerateToken(
		userID.(uuid.UUID),
		email.(string),
		username.(string),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	user := h.getUserByID(userID.(uuid.UUID))

	c.JSON(http.StatusOK, models.AuthResponse{
		Token:     token,
		ExpiresAt: expiresAt,
		User:      user,
	})
}

// GetMe returns the current user
func (h *AuthHandler) GetMe(c *gin.Context) {
	userID, _ := c.Get("user_id")
	user := h.getUserByID(userID.(uuid.UUID))
	if user == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	c.JSON(http.StatusOK, user)
}

// UpdateProfile updates user profile
func (h *AuthHandler) UpdateProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req models.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := h.db.Pool.Exec(context.Background(),
		`UPDATE users SET 
			full_name = COALESCE($2, full_name),
			phone = COALESCE($3, phone),
			avatar_url = COALESCE($4, avatar_url),
			updated_at = $5
		WHERE id = $1`,
		userID, req.FullName, req.Phone, req.AvatarURL, time.Now(),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update profile"})
		return
	}

	user := h.getUserByID(userID.(uuid.UUID))
	c.JSON(http.StatusOK, user)
}

// UpdateTown updates user's home town (restricted to once per 30 days)
func (h *AuthHandler) UpdateTown(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req models.UpdateTownRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check last town change
	var lastChange *time.Time
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT last_town_change FROM users WHERE id = $1",
		userID,
	).Scan(&lastChange)

	if err == nil && lastChange != nil {
		if time.Since(*lastChange) < 30*24*time.Hour {
			c.JSON(http.StatusForbidden, gin.H{
				"error":        "You can only change your home town once every 30 days",
				"next_allowed": lastChange.Add(30 * 24 * time.Hour),
			})
			return
		}
	}

	// Update town
	_, err = h.db.Pool.Exec(context.Background(),
		`UPDATE users SET 
			home_town_id = $2,
			home_suburb_id = $3,
			last_town_change = $4,
			updated_at = $4
		WHERE id = $1`,
		userID, req.HomeTownID, req.HomeSuburbID, time.Now(),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update home town"})
		return
	}

	user := h.getUserByID(userID.(uuid.UUID))
	c.JSON(http.StatusOK, user)
}

// GetUserProfile returns a public user profile
func (h *AuthHandler) GetUserProfile(c *gin.Context) {
	idStr := c.Param("userId")
	userID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	user := h.getUserByID(userID)
	if user == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// For public profile, we might want to hide sensitive info like Email/Phone
	// but the mobile app might need them for contact if allowed.
	// For now, return the user object as is, assuming the model controls visibility or the client handles it.

	c.JSON(http.StatusOK, user)
}

func (h *AuthHandler) getUserByID(id uuid.UUID) *models.User {
	var user models.User

	// Temp variables for potentially null fields from LEFT JOIN
	var tID *uuid.UUID
	var tName, tState, tCountry *string
	var sID *uuid.UUID
	var sName, sZip *string
	var storeSlug *string

	err := h.db.Pool.QueryRow(context.Background(),
		`SELECT u.id, u.email, u.username, u.full_name, u.avatar_url, u.phone,
		u.is_verified, u.is_active, u.home_town_id, u.home_suburb_id, 
		u.last_town_change, u.created_at, u.updated_at,
		t.id, t.name, t.state, t.country,
		s.id, s.name, s.zip_code,
		st.slug
		FROM users u
		LEFT JOIN towns t ON u.home_town_id = t.id
		LEFT JOIN suburbs s ON u.home_suburb_id = s.id
		LEFT JOIN stores st ON u.id = st.user_id
		WHERE u.id = $1`,
		id,
	).Scan(
		&user.ID, &user.Email, &user.Username, &user.FullName, &user.AvatarURL, &user.Phone,
		&user.IsVerified, &user.IsActive, &user.HomeTownID, &user.HomeSuburbID,
		&user.LastTownChange, &user.CreatedAt, &user.UpdatedAt,
		&tID, &tName, &tState, &tCountry,
		&sID, &sName, &sZip,
		&storeSlug,
	)

	if err != nil {
		// Fallback to simplified query without joins
		h.db.Pool.QueryRow(context.Background(),
			`SELECT id, email, username, full_name, avatar_url, phone,
			is_verified, is_active, home_town_id, home_suburb_id, 
			last_town_change, created_at, updated_at
			FROM users WHERE id = $1`,
			id,
		).Scan(
			&user.ID, &user.Email, &user.Username, &user.FullName, &user.AvatarURL, &user.Phone,
			&user.IsVerified, &user.IsActive, &user.HomeTownID, &user.HomeSuburbID,
			&user.LastTownChange, &user.CreatedAt, &user.UpdatedAt,
		)
	} else {
		// Construct nested objects if IDs are present
		if tID != nil {
			user.HomeTown = &models.Town{
				ID:      *tID,
				Name:    getString(tName),
				State:   tState,
				Country: getString(tCountry),
			}
		}
		if sID != nil {
			user.HomeSuburb = &models.Suburb{
				ID:      *sID,
				Name:    getString(sName),
				ZipCode: sZip,
				TownID:  *tID,
			}
		}
		user.StoreSlug = storeSlug
	}
	return &user
}

func getString(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

// generateCode generates a random 6-digit code
func generateCode() string {
	b := make([]byte, 3)
	rand.Read(b)
	return fmt.Sprintf("%06d", int(b[0])*10000/256+int(b[1])*100/256+int(b[2])/3)
}

// generateToken generates a secure random token
func generateToken() string {
	b := make([]byte, 32)
	rand.Read(b)
	return fmt.Sprintf("%x", b)
}

// ForgotPassword sends a password reset email
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	var req struct {
		Email string `json:"email" binding:"required,email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find user by email
	var userID uuid.UUID
	var fullName, username string
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT id, full_name, username FROM users WHERE email = $1",
		req.Email,
	).Scan(&userID, &fullName, &username)

	if err != nil {
		// Don't reveal if email exists or not for security
		c.JSON(http.StatusOK, gin.H{"message": "If an account with that email exists, a password reset link has been sent."})
		return
	}

	// Generate reset token
	resetToken := generateToken()
	expiresAt := time.Now().Add(1 * time.Hour)

	// Store reset token in database
	_, err = h.db.Pool.Exec(context.Background(),
		`INSERT INTO password_resets (user_id, token, expires_at) VALUES ($1, $2, $3)
		ON CONFLICT (user_id) DO UPDATE SET token = $2, expires_at = $3`,
		userID, resetToken, expiresAt,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process request"})
		return
	}

	// Send reset email
	userName := fullName
	if userName == "" {
		userName = username
	}

	if h.emailService != nil {
		go h.emailService.SendPasswordReset(req.Email, resetToken, userName)
	}

	c.JSON(http.StatusOK, gin.H{"message": "If an account with that email exists, a password reset link has been sent."})
}

// ResetPassword resets user password with token
func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var req struct {
		Token       string `json:"token" binding:"required"`
		NewPassword string `json:"new_password" binding:"required,min=8"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find reset token
	var userID uuid.UUID
	var expiresAt time.Time
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT user_id, expires_at FROM password_resets WHERE token = $1",
		req.Token,
	).Scan(&userID, &expiresAt)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired reset token"})
		return
	}

	if time.Now().After(expiresAt) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Reset token has expired"})
		return
	}

	// Hash new password
	hashedPassword, err := password.Hash(req.NewPassword)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process password"})
		return
	}

	// Update password
	_, err = h.db.Pool.Exec(context.Background(),
		"UPDATE users SET password_hash = $1, updated_at = $2 WHERE id = $3",
		hashedPassword, time.Now(), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update password"})
		return
	}

	// Delete used reset token
	h.db.Pool.Exec(context.Background(), "DELETE FROM password_resets WHERE user_id = $1", userID)

	c.JSON(http.StatusOK, gin.H{"message": "Password has been reset successfully"})
}

// SendVerificationEmail sends a verification code to user's email
func (h *AuthHandler) SendVerificationEmail(c *gin.Context) {
	userID, _ := c.Get("user_id")

	// Get user details
	var email, fullName, username string
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT email, full_name, username FROM users WHERE id = $1",
		userID,
	).Scan(&email, &fullName, &username)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Generate verification code
	code := generateCode()
	expiresAt := time.Now().Add(15 * time.Minute)

	// Store verification code
	_, err = h.db.Pool.Exec(context.Background(),
		`INSERT INTO email_verifications (user_id, code, expires_at) VALUES ($1, $2, $3)
		ON CONFLICT (user_id) DO UPDATE SET code = $2, expires_at = $3`,
		userID, code, expiresAt,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process request"})
		return
	}

	// Send verification email
	userName := fullName
	if userName == "" {
		userName = username
	}

	if h.emailService != nil {
		go h.emailService.SendEmailVerification(email, code, userName)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Verification code sent to your email"})
}

// VerifyEmail verifies user's email with code
func (h *AuthHandler) VerifyEmail(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		Code string `json:"code" binding:"required,len=6"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find verification code
	var storedCode string
	var expiresAt time.Time
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT code, expires_at FROM email_verifications WHERE user_id = $1",
		userID,
	).Scan(&storedCode, &expiresAt)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No pending verification"})
		return
	}

	if time.Now().After(expiresAt) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Verification code has expired"})
		return
	}

	if req.Code != storedCode {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid verification code"})
		return
	}

	// Mark email as verified
	_, err = h.db.Pool.Exec(context.Background(),
		"UPDATE users SET is_verified = true, updated_at = $1 WHERE id = $2",
		time.Now(), userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to verify email"})
		return
	}

	// Delete used verification code
	h.db.Pool.Exec(context.Background(), "DELETE FROM email_verifications WHERE user_id = $1", userID)

	c.JSON(http.StatusOK, gin.H{"message": "Email verified successfully"})
}
