package models

import (
	"time"

	"github.com/google/uuid"
)

// Badge represents a badge definition
type Badge struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	DisplayName string    `json:"display_name"`
	Description string    `json:"description"`
	Icon        string    `json:"icon"`
	Category    string    `json:"category"` // trust, seller, buyer, community, activity
	Priority    int       `json:"priority"` // higher = more important
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
}

// UserBadge represents a badge earned by a user
type UserBadge struct {
	ID        uuid.UUID  `json:"id"`
	UserID    uuid.UUID  `json:"user_id"`
	BadgeID   uuid.UUID  `json:"badge_id"`
	EarnedAt  time.Time  `json:"earned_at"`
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
	Badge     *Badge     `json:"badge,omitempty"` // Joined field
}

// VerificationStatus enum
type VerificationStatus string

const (
	VerificationPending  VerificationStatus = "pending"
	VerificationApproved VerificationStatus = "approved"
	VerificationRejected VerificationStatus = "rejected"
)

// VerificationRequest represents an ID verification request
type VerificationRequest struct {
	ID            uuid.UUID          `json:"id"`
	UserID        uuid.UUID          `json:"user_id"`
	IDDocumentURL string             `json:"id_document_url"`
	SelfieURL     string             `json:"selfie_url"`
	Status        VerificationStatus `json:"status"`
	ReviewerNotes *string            `json:"reviewer_notes,omitempty"`
	ReviewedAt    *time.Time         `json:"reviewed_at,omitempty"`
	ReviewedBy    *uuid.UUID         `json:"reviewed_by,omitempty"`
	CreatedAt     time.Time          `json:"created_at"`

	// Joined fields
	User *User `json:"user,omitempty"`
}

// SubmitVerificationRequest is the request body for submitting ID verification
type SubmitVerificationRequest struct {
	IDDocumentURL string `json:"id_document_url" binding:"required"`
	SelfieURL     string `json:"selfie_url" binding:"required"`
}

// ReviewVerificationRequest is the request body for reviewing verification
type ReviewVerificationRequest struct {
	Status        VerificationStatus `json:"status" binding:"required"` // approved or rejected
	ReviewerNotes *string            `json:"reviewer_notes"`
}

// BadgeListResponse is the response for listing badges
type BadgeListResponse struct {
	Badges []Badge `json:"badges"`
}

// UserBadgesResponse is the response for user's badges
type UserBadgesResponse struct {
	Badges []UserBadge `json:"badges"`
}
