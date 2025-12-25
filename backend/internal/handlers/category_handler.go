package handlers

import (
	"context"
	"net/http"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CategoryHandler handles category endpoints
type CategoryHandler struct {
	db *database.DB
}

// NewCategoryHandler creates a new category handler
func NewCategoryHandler(db *database.DB) *CategoryHandler {
	return &CategoryHandler{db: db}
}

// GetCategories returns all categories
func (h *CategoryHandler) GetCategories(c *gin.Context) {
	townIDStr := c.Query("town_id")
	var townID *uuid.UUID
	if townIDStr != "" {
		id, err := uuid.Parse(townIDStr)
		if err == nil {
			townID = &id
		}
	}

	rows, err := h.db.Pool.Query(context.Background(),
		`SELECT c.id, c.name, c.icon, c.description, c.parent_id, c.sort_order, c.is_active, c.created_at
		FROM categories c WHERE c.is_active = true ORDER BY c.sort_order, c.name`,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}
	defer rows.Close()

	var categories []models.Category
	for rows.Next() {
		var cat models.Category
		err := rows.Scan(&cat.ID, &cat.Name, &cat.Icon, &cat.Description, &cat.ParentID,
			&cat.SortOrder, &cat.IsActive, &cat.CreatedAt)
		if err != nil {
			continue
		}

		// Get active auction count
		if townID != nil {
			h.db.Pool.QueryRow(context.Background(),
				`SELECT COUNT(*) FROM auctions WHERE category_id = $1 AND town_id = $2 AND status IN ('active', 'ending_soon')`,
				cat.ID, townID,
			).Scan(&cat.ActiveAuctions)
		} else {
			h.db.Pool.QueryRow(context.Background(),
				`SELECT COUNT(*) FROM auctions WHERE category_id = $1 AND status IN ('active', 'ending_soon')`,
				cat.ID,
			).Scan(&cat.ActiveAuctions)
		}

		categories = append(categories, cat)
	}

	c.JSON(http.StatusOK, gin.H{"categories": categories})
}

// GetCategory returns a specific category
func (h *CategoryHandler) GetCategory(c *gin.Context) {
	categoryID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid category ID"})
		return
	}

	var cat models.Category
	err = h.db.Pool.QueryRow(context.Background(),
		`SELECT id, name, icon, description, parent_id, sort_order, is_active, created_at
		FROM categories WHERE id = $1`,
		categoryID,
	).Scan(&cat.ID, &cat.Name, &cat.Icon, &cat.Description, &cat.ParentID,
		&cat.SortOrder, &cat.IsActive, &cat.CreatedAt)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Category not found"})
		return
	}

	// Get active auction count
	h.db.Pool.QueryRow(context.Background(),
		`SELECT COUNT(*) FROM auctions WHERE category_id = $1 AND status IN ('active', 'ending_soon')`,
		cat.ID,
	).Scan(&cat.ActiveAuctions)

	c.JSON(http.StatusOK, cat)
}

// GetCategorySlots returns slot availability for a category in a town
func (h *CategoryHandler) GetCategorySlots(c *gin.Context) {
	categoryID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid category ID"})
		return
	}

	townID, err := uuid.Parse(c.Param("townId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid town ID"})
		return
	}

	var slot models.CategorySlot
	err = h.db.Pool.QueryRow(context.Background(),
		`SELECT cs.id, cs.category_id, cs.town_id, cs.max_active_auctions, cs.auction_duration_hours, cs.created_at
		FROM category_slots cs WHERE cs.category_id = $1 AND cs.town_id = $2`,
		categoryID, townID,
	).Scan(&slot.ID, &slot.CategoryID, &slot.TownID, &slot.MaxActiveAuctions,
		&slot.AuctionDurationHours, &slot.CreatedAt)

	if err != nil {
		// No custom slots, use defaults
		slot.CategoryID = categoryID
		slot.TownID = townID
		slot.MaxActiveAuctions = 10
		slot.AuctionDurationHours = 168
	}

	// Get current active count
	h.db.Pool.QueryRow(context.Background(),
		`SELECT COUNT(*) FROM auctions 
		WHERE category_id = $1 AND town_id = $2 AND status IN ('active', 'ending_soon', 'pending')`,
		categoryID, townID,
	).Scan(&slot.CurrentActive)

	// Get waiting count
	h.db.Pool.QueryRow(context.Background(),
		`SELECT COUNT(*) FROM waiting_list 
		WHERE category_id = $1 AND town_id = $2 AND status = 'waiting'`,
		categoryID, townID,
	).Scan(&slot.WaitingCount)

	slot.HasAvailableSlot = slot.CurrentActive < slot.MaxActiveAuctions

	c.JSON(http.StatusOK, slot)
}
