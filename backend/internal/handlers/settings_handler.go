package handlers

import (
	"context"
	"net/http"

	"github.com/airmass/backend/internal/database"
	"github.com/gin-gonic/gin"
)

type SettingsHandler struct {
	db *database.DB
}

func NewSettingsHandler(db *database.DB) *SettingsHandler {
	return &SettingsHandler{db: db}
}

// GetSetting returns a specific setting value
func (h *SettingsHandler) GetSetting(c *gin.Context) {
	key := c.Param("key")

	var value string
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT value FROM app_settings WHERE key = $1", key,
	).Scan(&value)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Setting not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"key": key, "value": value})
}

// GetAllSettings returns all settings
func (h *SettingsHandler) GetAllSettings(c *gin.Context) {
	rows, err := h.db.Pool.Query(context.Background(),
		"SELECT key, value FROM app_settings",
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch settings"})
		return
	}
	defer rows.Close()

	settings := make(map[string]string)
	for rows.Next() {
		var k, v string
		if err := rows.Scan(&k, &v); err == nil {
			settings[k] = v
		}
	}

	c.JSON(http.StatusOK, settings)
}

// UpdateSetting updates a setting value (Admin)
func (h *SettingsHandler) UpdateSetting(c *gin.Context) {
	key := c.Param("key")
	var req struct {
		Value string `json:"value" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Value is required"})
		return
	}

	_, err := h.db.Pool.Exec(context.Background(),
		`INSERT INTO app_settings (key, value, updated_at) 
		 VALUES ($1, $2, NOW()) 
		 ON CONFLICT (key) DO UPDATE SET value = $2, updated_at = NOW()`,
		key, req.Value,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update setting"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Setting updated", "key": key})
}
