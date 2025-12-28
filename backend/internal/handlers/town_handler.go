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
		(SELECT COUNT(*) FROM suburbs s WHERE s.town_id = t.id) as total_suburbs,
		(SELECT COUNT(*) FROM users u WHERE u.home_town_id = t.id) as user_count
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
			&town.ActiveAuctions, &town.TotalSuburbs, &town.UserCount,
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

// ============ ADMIN CRUD OPERATIONS ============

// CreateTown creates a new town (Admin)
func (h *TownHandler) CreateTown(c *gin.Context) {
	var req struct {
		Name     string `json:"name" binding:"required"`
		State    string `json:"state"`
		Country  string `json:"country"`
		Timezone string `json:"timezone"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var townID uuid.UUID
	err := h.db.Pool.QueryRow(context.Background(),
		`INSERT INTO towns (name, state, country, timezone) VALUES ($1, $2, $3, $4) RETURNING id`,
		req.Name, req.State, req.Country, req.Timezone,
	).Scan(&townID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create town"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"id": townID, "message": "Town created successfully"})
}

// UpdateTown updates an existing town (Admin)
func (h *TownHandler) UpdateTown(c *gin.Context) {
	townID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid town ID"})
		return
	}

	var req struct {
		Name     *string `json:"name"`
		State    *string `json:"state"`
		Country  *string `json:"country"`
		Timezone *string `json:"timezone"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.db.Pool.Exec(context.Background(),
		`UPDATE towns SET 
			name = COALESCE($1, name),
			state = COALESCE($2, state),
			country = COALESCE($3, country),
			timezone = COALESCE($4, timezone)
		WHERE id = $5`,
		req.Name, req.State, req.Country, req.Timezone, townID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update town"})
		return
	}

	if result.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Town not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Town updated successfully"})
}

// DeleteTown deletes a town (Admin)
func (h *TownHandler) DeleteTown(c *gin.Context) {
	townID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid town ID"})
		return
	}

	// Check if town has active auctions
	var activeCount int
	h.db.Pool.QueryRow(context.Background(),
		`SELECT COUNT(*) FROM auctions WHERE town_id = $1 AND status IN ('active', 'ending_soon')`,
		townID,
	).Scan(&activeCount)

	if activeCount > 0 {
		c.JSON(http.StatusConflict, gin.H{"error": "Cannot delete town with active auctions"})
		return
	}

	// Delete suburbs first
	h.db.Pool.Exec(context.Background(), `DELETE FROM suburbs WHERE town_id = $1`, townID)

	result, err := h.db.Pool.Exec(context.Background(), `DELETE FROM towns WHERE id = $1`, townID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete town"})
		return
	}

	if result.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Town not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Town deleted successfully"})
}

// CreateSuburb creates a new suburb (Admin)
func (h *TownHandler) CreateSuburb(c *gin.Context) {
	townID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid town ID"})
		return
	}

	var req struct {
		Name    string `json:"name" binding:"required"`
		ZipCode string `json:"zip_code"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var suburbID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(),
		`INSERT INTO suburbs (name, zip_code, town_id) VALUES ($1, $2, $3) RETURNING id`,
		req.Name, req.ZipCode, townID,
	).Scan(&suburbID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create suburb"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"id": suburbID, "message": "Suburb created successfully"})
}

// DeleteSuburb deletes a suburb (Admin)
func (h *TownHandler) DeleteSuburb(c *gin.Context) {
	suburbID, err := uuid.Parse(c.Param("suburbId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid suburb ID"})
		return
	}

	// Check if suburb has active auctions
	var activeCount int
	h.db.Pool.QueryRow(context.Background(),
		`SELECT COUNT(*) FROM auctions WHERE suburb_id = $1 AND status IN ('active', 'ending_soon')`,
		suburbID,
	).Scan(&activeCount)

	if activeCount > 0 {
		c.JSON(http.StatusConflict, gin.H{"error": "Cannot delete suburb with active auctions"})
		return
	}

	result, err := h.db.Pool.Exec(context.Background(), `DELETE FROM suburbs WHERE id = $1`, suburbID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete suburb"})
		return
	}

	if result.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Suburb not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Suburb deleted successfully"})
}
