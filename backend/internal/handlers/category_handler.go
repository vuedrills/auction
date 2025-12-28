package handlers

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"strings"

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

// CreateCategory creates a new category (Admin)
func (h *CategoryHandler) CreateCategory(c *gin.Context) {
	var req struct {
		Name        string  `json:"name" binding:"required"`
		Icon        *string `json:"icon"`
		Description string  `json:"description"`
		ParentID    *string `json:"parent_id"`
		SortOrder   int     `json:"sort_order"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var parentID *uuid.UUID
	if req.ParentID != nil && *req.ParentID != "" {
		id, err := uuid.Parse(*req.ParentID)
		if err == nil {
			parentID = &id
		}
	}

	_, err := h.db.Pool.Exec(context.Background(), `
		INSERT INTO categories (name, icon, description, parent_id, sort_order)
		VALUES ($1, $2, $3, $4, $5)
	`, req.Name, req.Icon, req.Description, parentID, req.SortOrder)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create category"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Category created successfully"})
}

// UpdateCategory updates an existing category (Admin)
func (h *CategoryHandler) UpdateCategory(c *gin.Context) {
	categoryID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid category ID"})
		return
	}

	var req struct {
		Name        *string `json:"name"`
		Icon        *string `json:"icon"`
		Description *string `json:"description"`
		ParentID    *string `json:"parent_id"`
		SortOrder   *int    `json:"sort_order"`
		IsActive    *bool   `json:"is_active"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Build dynamic update query
	updates := []string{}
	args := []interface{}{}
	argNum := 1

	if req.Name != nil {
		updates = append(updates, "name = $"+strconv.Itoa(argNum))
		args = append(args, *req.Name)
		argNum++
	}
	if req.Icon != nil {
		updates = append(updates, "icon = $"+strconv.Itoa(argNum))
		args = append(args, *req.Icon)
		argNum++
	}
	if req.Description != nil {
		updates = append(updates, "description = $"+strconv.Itoa(argNum))
		args = append(args, *req.Description)
		argNum++
	}
	if req.ParentID != nil && *req.ParentID != "" {
		parentID, err := uuid.Parse(*req.ParentID)
		if err == nil {
			updates = append(updates, "parent_id = $"+strconv.Itoa(argNum))
			args = append(args, parentID)
			argNum++
		}
	}
	if req.SortOrder != nil {
		updates = append(updates, "sort_order = $"+strconv.Itoa(argNum))
		args = append(args, *req.SortOrder)
		argNum++
	}
	if req.IsActive != nil {
		updates = append(updates, "is_active = $"+strconv.Itoa(argNum))
		args = append(args, *req.IsActive)
		argNum++
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No fields to update"})
		return
	}

	updates = append(updates, "updated_at = NOW()")
	args = append(args, categoryID)

	query := fmt.Sprintf("UPDATE categories SET %s WHERE id = $%d", strings.Join(updates, ", "), argNum)

	result, err := h.db.Pool.Exec(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update category"})
		return
	}

	if result.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Category not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Category updated successfully"})
}

// DeleteCategory deletes a category (Admin)
func (h *CategoryHandler) DeleteCategory(c *gin.Context) {
	categoryID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid category ID"})
		return
	}

	_, err = h.db.Pool.Exec(context.Background(), "DELETE FROM categories WHERE id = $1", categoryID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete category"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Category deleted successfully"})
}
