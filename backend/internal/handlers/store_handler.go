package handlers

import (
	"context"
	"errors"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// StoreHandler handles store-related endpoints
type StoreHandler struct {
	db *database.DB
}

// NewStoreHandler creates a new store handler
func NewStoreHandler(db *database.DB) *StoreHandler {
	return &StoreHandler{db: db}
}

// generateSlug creates a URL-friendly slug from store name
func generateSlug(name string) string {
	// Convert to lowercase
	slug := strings.ToLower(name)
	// Replace spaces with hyphens
	slug = strings.ReplaceAll(slug, " ", "-")
	// Remove special characters
	reg := regexp.MustCompile(`[^a-z0-9-]`)
	slug = reg.ReplaceAllString(slug, "")
	// Remove multiple consecutive hyphens
	reg = regexp.MustCompile(`-+`)
	slug = reg.ReplaceAllString(slug, "-")
	// Trim hyphens from ends
	slug = strings.Trim(slug, "-")
	return slug
}

// ============ STORE MANAGEMENT ============

// CreateStore creates a new store for the authenticated user
func (h *StoreHandler) CreateStore(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req models.CreateStoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if user already has a store
	var existingID uuid.UUID
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT id FROM stores WHERE user_id = $1", userID).Scan(&existingID)
	if err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "You already have a store"})
		return
	}

	// Generate unique slug
	baseSlug := generateSlug(req.StoreName)
	slug := baseSlug
	counter := 1
	for {
		var count int
		h.db.Pool.QueryRow(context.Background(),
			"SELECT COUNT(*) FROM stores WHERE slug = $1", slug).Scan(&count)
		if count == 0 {
			break
		}
		slug = baseSlug + "-" + strconv.Itoa(counter)
		counter++
	}

	// Parse optional UUIDs
	var categoryID, townID, suburbID *uuid.UUID
	if req.CategoryID != "" {
		if id, err := uuid.Parse(req.CategoryID); err == nil {
			categoryID = &id
		}
	}
	if req.TownID != "" {
		if id, err := uuid.Parse(req.TownID); err == nil {
			townID = &id
		}
	} else {
		// Use user's home town
		h.db.Pool.QueryRow(context.Background(),
			"SELECT home_town_id FROM users WHERE id = $1", userID).Scan(&townID)
	}
	if req.SuburbID != "" {
		if id, err := uuid.Parse(req.SuburbID); err == nil {
			suburbID = &id
		}
	}

	// Default delivery options
	deliveryOptions := req.DeliveryOptions
	if len(deliveryOptions) == 0 {
		deliveryOptions = []string{"pickup"}
	}

	// Create store
	var store models.Store
	err = h.db.Pool.QueryRow(context.Background(), `
		INSERT INTO stores (
			user_id, store_name, slug, tagline, about, logo_url, cover_url,
			category_id, whatsapp, phone, delivery_options, delivery_radius_km,
			town_id, suburb_id, address, is_verified
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15,
			(SELECT is_verified FROM users WHERE id = $1))
		RETURNING id, user_id, store_name, slug, tagline, about, logo_url, cover_url,
			category_id, whatsapp, phone, delivery_options, delivery_radius_km,
			town_id, suburb_id, address, is_active, is_verified, is_featured,
			total_products, total_sales, follower_count, views, created_at, updated_at
	`,
		userID, req.StoreName, slug, nilIfEmpty(req.Tagline), nilIfEmpty(req.About),
		nilIfEmpty(req.LogoURL), nilIfEmpty(req.CoverURL), categoryID,
		nilIfEmpty(req.WhatsApp), nilIfEmpty(req.Phone),
		deliveryOptions, nilIfZero(req.DeliveryRadiusKm),
		townID, suburbID, nilIfEmpty(req.Address),
	).Scan(
		&store.ID, &store.UserID, &store.StoreName, &store.Slug,
		&store.Tagline, &store.About, &store.LogoURL, &store.CoverURL,
		&store.CategoryID, &store.WhatsApp, &store.Phone,
		&store.DeliveryOptions, &store.DeliveryRadiusKm,
		&store.TownID, &store.SuburbID, &store.Address, &store.IsActive, &store.IsVerified,
		&store.IsFeatured, &store.TotalProducts, &store.TotalSales,
		&store.FollowerCount, &store.Views, &store.CreatedAt, &store.UpdatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create store: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, models.StoreResponse{Store: &store})
}

// GetMyStore returns the authenticated user's store
func (h *StoreHandler) GetMyStore(c *gin.Context) {
	userID, _ := c.Get("user_id")

	store, err := h.getStoreByUserID(userID.(uuid.UUID))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Store not found"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error: " + err.Error()})
		}
		return
	}

	c.JSON(http.StatusOK, models.StoreResponse{Store: store})
}

// UpdateMyStore updates the authenticated user's store
func (h *StoreHandler) UpdateMyStore(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req models.UpdateStoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Build dynamic update query
	updates := []string{}
	args := []interface{}{}
	argNum := 1

	if req.StoreName != nil {
		updates = append(updates, "store_name = $"+strconv.Itoa(argNum))
		args = append(args, *req.StoreName)
		argNum++
	}
	if req.Tagline != nil {
		updates = append(updates, "tagline = $"+strconv.Itoa(argNum))
		args = append(args, *req.Tagline)
		argNum++
	}
	if req.About != nil {
		updates = append(updates, "about = $"+strconv.Itoa(argNum))
		args = append(args, *req.About)
		argNum++
	}
	if req.LogoURL != nil {
		updates = append(updates, "logo_url = $"+strconv.Itoa(argNum))
		args = append(args, *req.LogoURL)
		argNum++
	}
	if req.CoverURL != nil {
		updates = append(updates, "cover_url = $"+strconv.Itoa(argNum))
		args = append(args, *req.CoverURL)
		argNum++
	}
	if req.CategoryID != nil {
		if id, err := uuid.Parse(*req.CategoryID); err == nil {
			updates = append(updates, "category_id = $"+strconv.Itoa(argNum))
			args = append(args, id)
			argNum++
		}
	}
	if req.WhatsApp != nil {
		updates = append(updates, "whatsapp = $"+strconv.Itoa(argNum))
		args = append(args, *req.WhatsApp)
		argNum++
	}
	if req.Phone != nil {
		updates = append(updates, "phone = $"+strconv.Itoa(argNum))
		args = append(args, *req.Phone)
		argNum++
	}
	if len(req.DeliveryOptions) > 0 {
		updates = append(updates, "delivery_options = $"+strconv.Itoa(argNum))
		args = append(args, req.DeliveryOptions)
		argNum++
	}
	if req.DeliveryRadiusKm != nil {
		updates = append(updates, "delivery_radius_km = $"+strconv.Itoa(argNum))
		args = append(args, *req.DeliveryRadiusKm)
		argNum++
	}
	if req.OperatingHours != nil {
		updates = append(updates, "operating_hours = $"+strconv.Itoa(argNum))
		args = append(args, *req.OperatingHours)
		argNum++
	}
	if req.Address != nil {
		updates = append(updates, "address = $"+strconv.Itoa(argNum))
		args = append(args, *req.Address)
		argNum++
	}
	if req.IsActive != nil {
		updates = append(updates, "is_active = $"+strconv.Itoa(argNum))
		args = append(args, *req.IsActive)
		argNum++
	}

	updates = append(updates, "updated_at = $"+strconv.Itoa(argNum))
	args = append(args, time.Now())
	argNum++

	args = append(args, userID)

	query := "UPDATE stores SET " + strings.Join(updates, ", ") +
		" WHERE user_id = $" + strconv.Itoa(argNum)

	_, err := h.db.Pool.Exec(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update store"})
		return
	}

	store, _ := h.getStoreByUserID(userID.(uuid.UUID))
	c.JSON(http.StatusOK, models.StoreResponse{Store: store})
}

// ============ STORE DISCOVERY ============

// GetStore returns a store by slug
func (h *StoreHandler) GetStore(c *gin.Context) {
	slug := c.Param("slug")

	// Get current user ID if authenticated
	var currentUserID *uuid.UUID
	if uid, exists := c.Get("user_id"); exists {
		id := uid.(uuid.UUID)
		currentUserID = &id
	}

	store, err := h.getStoreBySlug(slug, currentUserID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Store not found"})
		return
	}

	// Increment view count
	h.db.Pool.Exec(context.Background(),
		"UPDATE stores SET views = views + 1 WHERE id = $1", store.ID)

	c.JSON(http.StatusOK, models.StoreResponse{Store: store})
}

// GetStores returns a list of stores with filters
func (h *StoreHandler) GetStores(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	categoryID := c.Query("category")
	townID := c.Query("town")
	featured := c.Query("featured")
	search := c.Query("q")

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 50 {
		limit = 20
	}
	offset := (page - 1) * limit

	// Build query
	where := []string{"is_active = true"}
	args := []interface{}{}
	argNum := 1

	if categoryID != "" {
		if id, err := uuid.Parse(categoryID); err == nil {
			where = append(where, "category_id = $"+strconv.Itoa(argNum))
			args = append(args, id)
			argNum++
		}
	}
	if townID != "" {
		if id, err := uuid.Parse(townID); err == nil {
			where = append(where, "town_id = $"+strconv.Itoa(argNum))
			args = append(args, id)
			argNum++
		}
	}
	if featured == "true" {
		where = append(where, "is_featured = true")
	}
	if search != "" {
		where = append(where, "(store_name ILIKE $"+strconv.Itoa(argNum)+" OR tagline ILIKE $"+strconv.Itoa(argNum)+")")
		args = append(args, "%"+search+"%")
		argNum++
	}

	whereClause := strings.Join(where, " AND ")

	// Count total
	var totalCount int
	countQuery := "SELECT COUNT(*) FROM stores WHERE " + whereClause
	h.db.Pool.QueryRow(context.Background(), countQuery, args...).Scan(&totalCount)

	// Get stores
	args = append(args, limit, offset)
	query := `
		SELECT s.id, s.user_id, s.store_name, s.slug, s.tagline, s.about,
			s.logo_url, s.cover_url, s.category_id, s.whatsapp, s.phone,
			s.delivery_options, s.town_id, s.address, s.is_active, s.is_verified,
			s.is_featured, s.total_products, s.follower_count, s.views,
			t.name as town_name,
			u.full_name as owner_name, u.avatar_url as owner_avatar
		FROM stores s
		LEFT JOIN towns t ON s.town_id = t.id
		LEFT JOIN users u ON s.user_id = u.id
		WHERE ` + whereClause + `
		ORDER BY s.is_featured DESC, s.views DESC, s.created_at DESC
		LIMIT $` + strconv.Itoa(argNum) + ` OFFSET $` + strconv.Itoa(argNum+1)

	rows, err := h.db.Pool.Query(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stores"})
		return
	}
	defer rows.Close()

	stores := []models.Store{}
	for rows.Next() {
		var store models.Store
		var townName, ownerName, ownerAvatar *string

		err := rows.Scan(
			&store.ID, &store.UserID, &store.StoreName, &store.Slug,
			&store.Tagline, &store.About, &store.LogoURL, &store.CoverURL,
			&store.CategoryID, &store.WhatsApp, &store.Phone,
			&store.DeliveryOptions, &store.TownID, &store.Address, &store.IsActive,
			&store.IsVerified, &store.IsFeatured, &store.TotalProducts,
			&store.FollowerCount, &store.Views,
			&townName, &ownerName, &ownerAvatar,
		)
		if err != nil {
			continue
		}

		if townName != nil {
			store.Town = &models.Town{Name: *townName}
		}
		if ownerName != nil {
			store.Owner = &models.User{FullName: *ownerName, AvatarURL: ownerAvatar}
		}

		stores = append(stores, store)
	}

	c.JSON(http.StatusOK, models.StoresResponse{
		Stores:     stores,
		TotalCount: totalCount,
		Page:       page,
		Limit:      limit,
	})
}

// GetStoreCategories returns all store categories
func (h *StoreHandler) GetStoreCategories(c *gin.Context) {
	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT id, name, display_name, icon, sort_order, is_active
		FROM store_categories
		WHERE is_active = true
		ORDER BY sort_order ASC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}
	defer rows.Close()

	categories := []models.StoreCategory{}
	for rows.Next() {
		var cat models.StoreCategory
		rows.Scan(&cat.ID, &cat.Name, &cat.DisplayName, &cat.Icon, &cat.SortOrder, &cat.IsActive)
		categories = append(categories, cat)
	}

	c.JSON(http.StatusOK, models.StoreCategoriesResponse{Categories: categories})
}

// GetFeaturedStores returns featured stores
func (h *StoreHandler) GetFeaturedStores(c *gin.Context) {
	c.Set("featured", "true")
	h.GetStores(c)
}

// GetNearbyStores returns stores in user's town
func (h *StoreHandler) GetNearbyStores(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	var townID uuid.UUID
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT home_town_id FROM users WHERE id = $1", userID).Scan(&townID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No home town set"})
		return
	}

	c.Set("town", townID.String())
	h.GetStores(c)
}

// ============ FOLLOW SYSTEM ============

// FollowStore follows a store
func (h *StoreHandler) FollowStore(c *gin.Context) {
	userID, _ := c.Get("user_id")
	storeID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid store ID"})
		return
	}

	// Check if store exists
	var ownerID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(),
		"SELECT user_id FROM stores WHERE id = $1", storeID).Scan(&ownerID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Store not found"})
		return
	}

	// Can't follow own store
	if ownerID == userID.(uuid.UUID) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot follow your own store"})
		return
	}

	// Insert follow
	_, err = h.db.Pool.Exec(context.Background(), `
		INSERT INTO store_followers (store_id, user_id)
		VALUES ($1, $2)
		ON CONFLICT (store_id, user_id) DO NOTHING
	`, storeID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to follow store"})
		return
	}

	// Update follower count
	h.db.Pool.Exec(context.Background(), `
		UPDATE stores SET follower_count = (
			SELECT COUNT(*) FROM store_followers WHERE store_id = $1
		) WHERE id = $1
	`, storeID)

	c.JSON(http.StatusOK, gin.H{"message": "Store followed"})
}

// UnfollowStore unfollows a store
func (h *StoreHandler) UnfollowStore(c *gin.Context) {
	userID, _ := c.Get("user_id")
	storeID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid store ID"})
		return
	}

	_, err = h.db.Pool.Exec(context.Background(), `
		DELETE FROM store_followers WHERE store_id = $1 AND user_id = $2
	`, storeID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unfollow store"})
		return
	}

	// Update follower count
	h.db.Pool.Exec(context.Background(), `
		UPDATE stores SET follower_count = (
			SELECT COUNT(*) FROM store_followers WHERE store_id = $1
		) WHERE id = $1
	`, storeID)

	c.JSON(http.StatusOK, gin.H{"message": "Store unfollowed"})
}

// GetFollowingStores returns stores the user follows
func (h *StoreHandler) GetFollowingStores(c *gin.Context) {
	userID, _ := c.Get("user_id")

	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT s.id, s.store_name, s.slug, s.tagline, s.logo_url,
			s.is_verified, s.total_products, s.follower_count,
			t.name as town_name
		FROM stores s
		JOIN store_followers sf ON sf.store_id = s.id
		LEFT JOIN towns t ON s.town_id = t.id
		WHERE sf.user_id = $1 AND s.is_active = true
		ORDER BY sf.followed_at DESC
	`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch stores"})
		return
	}
	defer rows.Close()

	stores := []models.Store{}
	for rows.Next() {
		var store models.Store
		var townName *string
		rows.Scan(
			&store.ID, &store.StoreName, &store.Slug, &store.Tagline,
			&store.LogoURL, &store.IsVerified, &store.TotalProducts,
			&store.FollowerCount, &townName,
		)
		if townName != nil {
			store.Town = &models.Town{Name: *townName}
		}
		store.IsFollowing = true
		stores = append(stores, store)
	}

	c.JSON(http.StatusOK, models.StoresResponse{Stores: stores, TotalCount: len(stores)})
}

// ============ HELPERS ============

func (h *StoreHandler) getStoreByUserID(userID uuid.UUID) (*models.Store, error) {
	var store models.Store
	err := h.db.Pool.QueryRow(context.Background(), `
		SELECT id, user_id, store_name, slug, tagline, about, logo_url, cover_url,
			category_id, whatsapp, phone, delivery_options, delivery_radius_km,
			operating_hours, town_id, suburb_id, address, is_active, is_verified, is_featured,
			total_products, total_sales, follower_count, views, created_at, updated_at
		FROM stores WHERE user_id = $1
	`, userID).Scan(
		&store.ID, &store.UserID, &store.StoreName, &store.Slug,
		&store.Tagline, &store.About, &store.LogoURL, &store.CoverURL,
		&store.CategoryID, &store.WhatsApp, &store.Phone,
		&store.DeliveryOptions, &store.DeliveryRadiusKm,
		&store.OperatingHours, &store.TownID, &store.SuburbID, &store.Address,
		&store.IsActive, &store.IsVerified, &store.IsFeatured,
		&store.TotalProducts, &store.TotalSales, &store.FollowerCount,
		&store.Views, &store.CreatedAt, &store.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &store, nil
}

func (h *StoreHandler) getStoreBySlug(slug string, currentUserID *uuid.UUID) (*models.Store, error) {
	var store models.Store
	var townName, suburbName, ownerName, ownerAvatar, categoryName *string
	var isFollowing bool

	query := `
		SELECT s.id, s.user_id, s.store_name, s.slug, s.tagline, s.about,
			s.logo_url, s.cover_url, s.category_id, s.whatsapp, s.phone,
			s.delivery_options, s.delivery_radius_km, s.operating_hours,
			s.town_id, s.suburb_id, s.address, s.is_active, s.is_verified, s.is_featured,
			s.total_products, s.total_sales, s.follower_count, s.views,
			s.created_at, s.updated_at,
			t.name as town_name, sub.name as suburb_name,
			u.full_name as owner_name, u.avatar_url as owner_avatar,
			sc.display_name as category_name,
			CASE WHEN sf.id IS NOT NULL THEN true ELSE false END as is_following
		FROM stores s
		LEFT JOIN towns t ON s.town_id = t.id
		LEFT JOIN suburbs sub ON s.suburb_id = sub.id
		LEFT JOIN users u ON s.user_id = u.id
		LEFT JOIN store_categories sc ON s.category_id = sc.id
		LEFT JOIN store_followers sf ON sf.store_id = s.id AND sf.user_id = $2
		WHERE s.slug = $1 AND s.is_active = true
	`

	var userArg interface{} = nil
	if currentUserID != nil {
		userArg = *currentUserID
	}

	err := h.db.Pool.QueryRow(context.Background(), query, slug, userArg).Scan(
		&store.ID, &store.UserID, &store.StoreName, &store.Slug,
		&store.Tagline, &store.About, &store.LogoURL, &store.CoverURL,
		&store.CategoryID, &store.WhatsApp, &store.Phone,
		&store.DeliveryOptions, &store.DeliveryRadiusKm, &store.OperatingHours,
		&store.TownID, &store.SuburbID, &store.Address, &store.IsActive, &store.IsVerified,
		&store.IsFeatured, &store.TotalProducts, &store.TotalSales,
		&store.FollowerCount, &store.Views, &store.CreatedAt, &store.UpdatedAt,
		&townName, &suburbName, &ownerName, &ownerAvatar, &categoryName, &isFollowing,
	)
	if err != nil {
		return nil, err
	}

	if townName != nil {
		store.Town = &models.Town{Name: *townName}
	}
	if suburbName != nil {
		store.Suburb = &models.Suburb{Name: *suburbName}
	}
	if ownerName != nil {
		store.Owner = &models.User{ID: store.UserID, FullName: *ownerName, AvatarURL: ownerAvatar}
	}
	if categoryName != nil {
		store.Category = &models.StoreCategory{DisplayName: *categoryName}
	}
	store.IsFollowing = isFollowing

	return &store, nil
}

func nilIfEmpty(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func nilIfZero(i int) *int {
	if i == 0 {
		return nil
	}
	return &i
}
