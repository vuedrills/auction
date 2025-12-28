package models

import (
	"time"

	"github.com/google/uuid"
)

// Town represents a town/city
type Town struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	State     *string   `json:"state,omitempty"`
	Country   string    `json:"country"`
	Timezone  *string   `json:"timezone,omitempty"`
	Latitude  *float64  `json:"latitude,omitempty"`
	Longitude *float64  `json:"longitude,omitempty"`
	CreatedAt time.Time `json:"created_at"`

	// Aggregated fields
	ActiveAuctions int      `json:"active_auctions,omitempty"`
	TotalSuburbs   int      `json:"total_suburbs,omitempty"`
	UserCount      int      `json:"user_count,omitempty"`
	Suburbs        []Suburb `json:"suburbs,omitempty"`
}

// Suburb represents a suburb/neighborhood within a town
type Suburb struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	ZipCode   *string   `json:"zip_code,omitempty"`
	TownID    uuid.UUID `json:"town_id"`
	Latitude  *float64  `json:"latitude,omitempty"`
	Longitude *float64  `json:"longitude,omitempty"`
	CreatedAt time.Time `json:"created_at"`

	// Aggregated fields
	ActiveAuctions int    `json:"active_auctions,omitempty"`
	EndingSoon     int    `json:"ending_soon,omitempty"`
	TownName       string `json:"town_name,omitempty"`
}

// SuburbWithStats includes auction statistics
type SuburbWithStats struct {
	Suburb
	LiveAuctions int    `json:"live_auctions"`
	NextEndingIn string `json:"next_ending_in,omitempty"`
}
