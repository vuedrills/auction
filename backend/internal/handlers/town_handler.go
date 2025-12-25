package handlers

import (
	"context"
	"net/http"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// TownHandler handles town and suburb endpoints
type TownHandler struct {
	db *database.DB
}

// NewTownHandler creates a new town handler
func NewTownHandler(db *database.DB) *TownHandler {
	return &TownHandler{db: db}
}

// GetTowns returns all towns
func (h *TownHandler) GetTowns(c *gin.Context) {
	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT t.id, t.name, t.state, t.country, t.timezone, t.created_at,
		(SELECT COUNT(*) FROM auctions a WHERE a.town_id = t.id AND a.status IN ('active', 'ending_soon')) as active_auctions,
		(SELECT COUNT(*) FROM suburbs s WHERE s.town_id = t.id) as total_suburbs
		FROM towns t ORDER BY t.name`,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch towns"})
		return
	}
	defer rows.Close()

	var towns []models.Town
	for rows.Next() {
		var town models.Town
		err := rows.Scan(
			&town.ID, &town.Name, &town.State, &town.Country, &town.Timezone, &town.CreatedAt,
			&town.ActiveAuctions, &town.TotalSuburbs,
		)
		if err != nil {
			continue
		}
		towns = append(towns, town)
	}

	c.JSON(http.StatusOK, gin.H{"towns": towns})
}

// GetTown returns a specific town with its suburbs
func (h *TownHandler) GetTown(c *gin.Context) {
	townID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid town ID"})
		return
	}

	var town models.Town
	err = h.db.Pool.QueryRow(context.Background(),
		`SELECT t.id, t.name, t.state, t.country, t.timezone, t.created_at,
		(SELECT COUNT(*) FROM auctions a WHERE a.town_id = t.id AND a.status IN ('active', 'ending_soon')) as active_auctions
		FROM towns t WHERE t.id = $1`,
		townID,
	).Scan(&town.ID, &town.Name, &town.State, &town.Country, &town.Timezone, &town.CreatedAt, &town.ActiveAuctions)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Town not found"})
		return
	}

	// Get suburbs
	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT s.id, s.name, s.zip_code, s.town_id, s.created_at,
		(SELECT COUNT(*) FROM auctions a WHERE a.suburb_id = s.id AND a.status IN ('active', 'ending_soon')) as active_auctions
		FROM suburbs s WHERE s.town_id = $1 ORDER BY s.name`,
		townID,
	)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var suburb models.Suburb
			rows.Scan(&suburb.ID, &suburb.Name, &suburb.ZipCode, &suburb.TownID, &suburb.CreatedAt, &suburb.ActiveAuctions)
			town.Suburbs = append(town.Suburbs, suburb)
		}
	}

	c.JSON(http.StatusOK, town)
}

// GetSuburbs returns suburbs for a town
func (h *TownHandler) GetSuburbs(c *gin.Context) {
	townID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid town ID"})
		return
	}

	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT s.id, s.name, s.zip_code, s.town_id, s.created_at,
		(SELECT COUNT(*) FROM auctions a WHERE a.suburb_id = s.id AND a.status IN ('active', 'ending_soon')) as active_auctions,
		(SELECT COUNT(*) FROM auctions a WHERE a.suburb_id = s.id AND a.status = 'ending_soon') as ending_soon
		FROM suburbs s WHERE s.town_id = $1 ORDER BY active_auctions DESC, s.name`,
		townID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch suburbs"})
		return
	}
	defer rows.Close()

	var suburbs []models.Suburb
	for rows.Next() {
		var suburb models.Suburb
		rows.Scan(&suburb.ID, &suburb.Name, &suburb.ZipCode, &suburb.TownID, &suburb.CreatedAt,
			&suburb.ActiveAuctions, &suburb.EndingSoon)
		suburbs = append(suburbs, suburb)
	}

	c.JSON(http.StatusOK, gin.H{"suburbs": suburbs})
}

// GetSuburb returns a specific suburb
func (h *TownHandler) GetSuburb(c *gin.Context) {
	suburbID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid suburb ID"})
		return
	}

	var suburb models.Suburb
	err = h.db.Pool.QueryRow(context.Background(),
		`SELECT s.id, s.name, s.zip_code, s.town_id, s.created_at,
		t.name as town_name,
		(SELECT COUNT(*) FROM auctions a WHERE a.suburb_id = s.id AND a.status IN ('active', 'ending_soon')) as active_auctions
		FROM suburbs s
		JOIN towns t ON s.town_id = t.id
		WHERE s.id = $1`,
		suburbID,
	).Scan(&suburb.ID, &suburb.Name, &suburb.ZipCode, &suburb.TownID, &suburb.CreatedAt,
		&suburb.TownName, &suburb.ActiveAuctions)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Suburb not found"})
		return
	}

	c.JSON(http.StatusOK, suburb)
}
