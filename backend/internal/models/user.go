package models

import (
	"time"

	"github.com/google/uuid"
)

// User represents a user account
type User struct {
	ID             uuid.UUID  `json:"id"`
	Email          string     `json:"email"`
	Username       string     `json:"username"`
	PasswordHash   string     `json:"-"`
	FullName       string     `json:"full_name"`
	AvatarURL      *string    `json:"avatar_url,omitempty"`
	Phone          *string    `json:"phone,omitempty"`
	IsVerified     bool       `json:"is_verified"`
	IsActive       bool       `json:"is_active"`
	HomeTownID     *uuid.UUID `json:"home_town_id,omitempty"`
	HomeSuburbID   *uuid.UUID `json:"home_suburb_id,omitempty"`
	LastTownChange *time.Time `json:"last_town_change,omitempty"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`

	// Reputation fields
	Rating            float64   `json:"rating"`
	RatingCount       int       `json:"rating_count"`
	CompletedAuctions int       `json:"completed_auctions"`
	TotalSales        float64   `json:"total_sales"`
	IsTrustedSeller   bool      `json:"is_trusted_seller"`
	Badges            []string  `json:"badges,omitempty"`
	MemberSince       time.Time `json:"member_since"`

	// Joined fields
	HomeTown   *Town   `json:"home_town,omitempty"`
	HomeSuburb *Suburb `json:"home_suburb,omitempty"`
}

// UserWithStats includes user statistics
type UserWithStats struct {
	User
	TotalAuctions int     `json:"total_auctions"`
	TotalBids     int     `json:"total_bids"`
	TotalWins     int     `json:"total_wins"`
	TotalSales    int     `json:"total_sales"`
	AverageRating float64 `json:"average_rating"`
	TotalReviews  int     `json:"total_reviews"`
}

// RegisterRequest represents registration input
type RegisterRequest struct {
	Email        string     `json:"email" binding:"required,email"`
	Username     string     `json:"username" binding:"required,min=3,max=50"`
	Password     string     `json:"password" binding:"required,min=8"`
	FullName     string     `json:"full_name" binding:"required,min=2,max=100"`
	HomeTownID   uuid.UUID  `json:"home_town_id" binding:"required"`
	HomeSuburbID *uuid.UUID `json:"home_suburb_id"`
	Phone        *string    `json:"phone"`
}

// LoginRequest represents login input
type LoginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// AuthResponse represents authentication response
type AuthResponse struct {
	Token     string `json:"token"`
	ExpiresAt int64  `json:"expires_at"`
	User      *User  `json:"user"`
}

// UpdateProfileRequest represents profile update input
type UpdateProfileRequest struct {
	FullName  *string `json:"full_name"`
	Phone     *string `json:"phone"`
	AvatarURL *string `json:"avatar_url"`
}

// UpdateTownRequest represents home town change request
type UpdateTownRequest struct {
	HomeTownID   uuid.UUID  `json:"home_town_id" binding:"required"`
	HomeSuburbID *uuid.UUID `json:"home_suburb_id"`
}
