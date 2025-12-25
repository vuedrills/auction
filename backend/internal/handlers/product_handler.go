package handlers

import (
	"context"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/models"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/lib/pq"
)

// ProductHandler handles product-related endpoints
type ProductHandler struct {
	db *database.DB
}

// NewProductHandler creates a new product handler
func NewProductHandler(db *database.DB) *ProductHandler {
	return &ProductHandler{db: db}
}

// CreateProduct creates a new product in the user's store
func (h *ProductHandler) CreateProduct(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req models.CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get user's store
	var storeID uuid.UUID
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT id FROM stores WHERE user_id = $1", userID).Scan(&storeID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "You don't have a store. Create one first."})
		return
	}

	// Set defaults
	pricingType := req.PricingType
	if pricingType == "" {
		pricingType = "fixed"
	}
	condition := req.Condition
	if condition == "" {
		condition = "new"
	}
	stockQty := req.StockQuantity
	if stockQty == 0 {
		stockQty = 1
	}

	// Parse category ID
	var categoryID *uuid.UUID
	if req.CategoryID != "" {
		if id, err := uuid.Parse(req.CategoryID); err == nil {
			categoryID = &id
		}
	}

	// Insert product
	var product models.Product
	err = h.db.Pool.QueryRow(context.Background(), `
		INSERT INTO products (
			store_id, title, description, price, compare_at_price,
			pricing_type, category_id, condition, images, stock_quantity
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id, store_id, title, description, price, compare_at_price,
			pricing_type, category_id, condition, images, stock_quantity,
			is_available, is_featured, views, enquiries, created_at, updated_at
	`,
		storeID, req.Title, nilIfEmpty(req.Description), req.Price,
		nilIfZeroFloat(req.CompareAtPrice), pricingType, categoryID,
		condition, pq.Array(req.Images), stockQty,
	).Scan(
		&product.ID, &product.StoreID, &product.Title, &product.Description,
		&product.Price, &product.CompareAtPrice, &product.PricingType,
		&product.CategoryID, &product.Condition, &product.Images,
		&product.StockQuantity, &product.IsAvailable, &product.IsFeatured,
		&product.Views, &product.Enquiries, &product.CreatedAt, &product.UpdatedAt,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create product: " + err.Error()})
		return
	}

	// Update store product count
	h.db.Pool.Exec(context.Background(), `
		UPDATE stores SET total_products = (
			SELECT COUNT(*) FROM products WHERE store_id = $1 AND is_available = true
		), updated_at = NOW() WHERE id = $1
	`, storeID)

	c.JSON(http.StatusCreated, models.ProductResponse{Product: &product})
}

// GetProduct returns a single product
func (h *ProductHandler) GetProduct(c *gin.Context) {
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	product, err := h.getProductByID(productID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
		return
	}

	// Increment view count
	h.db.Pool.Exec(context.Background(),
		"UPDATE products SET views = views + 1 WHERE id = $1", productID)

	c.JSON(http.StatusOK, models.ProductResponse{Product: product})
}

// GetStoreProducts returns products for a store
func (h *ProductHandler) GetStoreProducts(c *gin.Context) {
	slug := c.Param("slug")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	pricingType := c.Query("type") // fixed, negotiable, service
	categoryID := c.Query("category")
	sortBy := c.Query("sort") // price_asc, price_desc, newest, popular

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 50 {
		limit = 20
	}
	offset := (page - 1) * limit

	// Get store ID from slug
	var storeID uuid.UUID
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT id FROM stores WHERE slug = $1", slug).Scan(&storeID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Store not found"})
		return
	}

	// Build query
	where := []string{"p.store_id = $1", "p.is_available = true"}
	args := []interface{}{storeID}
	argNum := 2

	if pricingType != "" {
		where = append(where, "p.pricing_type = $"+strconv.Itoa(argNum))
		args = append(args, pricingType)
		argNum++
	}
	if categoryID != "" {
		if id, err := uuid.Parse(categoryID); err == nil {
			where = append(where, "p.category_id = $"+strconv.Itoa(argNum))
			args = append(args, id)
			argNum++
		}
	}

	whereClause := strings.Join(where, " AND ")

	// Determine sort order
	orderBy := "p.created_at DESC" // default: newest
	switch sortBy {
	case "price_asc":
		orderBy = "p.price ASC"
	case "price_desc":
		orderBy = "p.price DESC"
	case "popular":
		orderBy = "p.views DESC"
	}

	// Count total
	var totalCount int
	countQuery := "SELECT COUNT(*) FROM products p WHERE " + whereClause
	h.db.Pool.QueryRow(context.Background(), countQuery, args...).Scan(&totalCount)

	// Get products
	args = append(args, limit, offset)
	query := `
		SELECT p.id, p.store_id, p.title, p.description, p.price,
			p.compare_at_price, p.pricing_type, p.category_id, p.condition,
			p.images, p.stock_quantity, p.is_available, p.is_featured,
			p.views, p.enquiries, p.created_at, p.updated_at,
			c.name as category_name
		FROM products p
		LEFT JOIN categories c ON p.category_id = c.id
		WHERE ` + whereClause + `
		ORDER BY p.is_featured DESC, ` + orderBy + `
		LIMIT $` + strconv.Itoa(argNum) + ` OFFSET $` + strconv.Itoa(argNum+1)

	rows, err := h.db.Pool.Query(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch products"})
		return
	}
	defer rows.Close()

	products := []models.Product{}
	for rows.Next() {
		var product models.Product
		var categoryName *string

		err := rows.Scan(
			&product.ID, &product.StoreID, &product.Title, &product.Description,
			&product.Price, &product.CompareAtPrice, &product.PricingType,
			&product.CategoryID, &product.Condition, &product.Images,
			&product.StockQuantity, &product.IsAvailable, &product.IsFeatured,
			&product.Views, &product.Enquiries, &product.CreatedAt, &product.UpdatedAt,
			&categoryName,
		)
		if err != nil {
			continue
		}

		if categoryName != nil {
			product.Category = &models.Category{Name: *categoryName}
		}
		products = append(products, product)
	}

	c.JSON(http.StatusOK, models.ProductsResponse{
		Products:   products,
		TotalCount: totalCount,
		Page:       page,
		Limit:      limit,
	})
}

// GetMyProducts returns products for the authenticated user's store
func (h *ProductHandler) GetMyProducts(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var slug string
	err := h.db.Pool.QueryRow(context.Background(),
		"SELECT slug FROM stores WHERE user_id = $1", userID).Scan(&slug)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "You don't have a store"})
		return
	}

	c.Params = append(c.Params, gin.Param{Key: "slug", Value: slug})
	h.GetStoreProducts(c)
}

// UpdateProduct updates a product
func (h *ProductHandler) UpdateProduct(c *gin.Context) {
	userID, _ := c.Get("user_id")
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	var req models.UpdateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify ownership
	var storeID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(), `
		SELECT p.store_id FROM products p
		JOIN stores s ON p.store_id = s.id
		WHERE p.id = $1 AND s.user_id = $2
	`, productID, userID).Scan(&storeID)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Product not found or not yours"})
		return
	}

	// Build update query
	updates := []string{}
	args := []interface{}{}
	argNum := 1

	if req.Title != nil {
		updates = append(updates, "title = $"+strconv.Itoa(argNum))
		args = append(args, *req.Title)
		argNum++
	}
	if req.Description != nil {
		updates = append(updates, "description = $"+strconv.Itoa(argNum))
		args = append(args, *req.Description)
		argNum++
	}
	if req.Price != nil {
		updates = append(updates, "price = $"+strconv.Itoa(argNum))
		args = append(args, *req.Price)
		argNum++
	}
	if req.CompareAtPrice != nil {
		updates = append(updates, "compare_at_price = $"+strconv.Itoa(argNum))
		args = append(args, *req.CompareAtPrice)
		argNum++
	}
	if req.PricingType != nil {
		updates = append(updates, "pricing_type = $"+strconv.Itoa(argNum))
		args = append(args, *req.PricingType)
		argNum++
	}
	if req.CategoryID != nil {
		if id, err := uuid.Parse(*req.CategoryID); err == nil {
			updates = append(updates, "category_id = $"+strconv.Itoa(argNum))
			args = append(args, id)
			argNum++
		}
	}
	if req.Condition != nil {
		updates = append(updates, "condition = $"+strconv.Itoa(argNum))
		args = append(args, *req.Condition)
		argNum++
	}
	if len(req.Images) > 0 {
		updates = append(updates, "images = $"+strconv.Itoa(argNum))
		args = append(args, pq.Array(req.Images))
		argNum++
	}
	if req.StockQuantity != nil {
		updates = append(updates, "stock_quantity = $"+strconv.Itoa(argNum))
		args = append(args, *req.StockQuantity)
		argNum++
	}
	if req.IsAvailable != nil {
		updates = append(updates, "is_available = $"+strconv.Itoa(argNum))
		args = append(args, *req.IsAvailable)
		argNum++
	}

	if len(updates) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No updates provided"})
		return
	}

	updates = append(updates, "updated_at = $"+strconv.Itoa(argNum))
	args = append(args, time.Now())
	argNum++

	args = append(args, productID)
	query := "UPDATE products SET " + strings.Join(updates, ", ") +
		" WHERE id = $" + strconv.Itoa(argNum)

	_, err = h.db.Pool.Exec(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update product"})
		return
	}

	// Update store product count
	h.db.Pool.Exec(context.Background(), `
		UPDATE stores SET total_products = (
			SELECT COUNT(*) FROM products WHERE store_id = $1 AND is_available = true
		), updated_at = NOW() WHERE id = $1
	`, storeID)

	product, _ := h.getProductByID(productID)
	c.JSON(http.StatusOK, models.ProductResponse{Product: product})
}

// DeleteProduct deletes a product
func (h *ProductHandler) DeleteProduct(c *gin.Context) {
	userID, _ := c.Get("user_id")
	productID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid product ID"})
		return
	}

	// Verify ownership and get store ID
	var storeID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(), `
		SELECT p.store_id FROM products p
		JOIN stores s ON p.store_id = s.id
		WHERE p.id = $1 AND s.user_id = $2
	`, productID, userID).Scan(&storeID)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Product not found or not yours"})
		return
	}

	// Delete product
	_, err = h.db.Pool.Exec(context.Background(),
		"DELETE FROM products WHERE id = $1", productID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete product"})
		return
	}

	// Update store product count
	h.db.Pool.Exec(context.Background(), `
		UPDATE stores SET total_products = (
			SELECT COUNT(*) FROM products WHERE store_id = $1 AND is_available = true
		), updated_at = NOW() WHERE id = $1
	`, storeID)

	c.JSON(http.StatusOK, gin.H{"message": "Product deleted"})
}

// SearchProducts searches products across all stores
func (h *ProductHandler) SearchProducts(c *gin.Context) {
	search := c.Query("q")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	townID := c.Query("town")
	categoryID := c.Query("category")
	minPrice, _ := strconv.ParseFloat(c.Query("min_price"), 64)
	maxPrice, _ := strconv.ParseFloat(c.Query("max_price"), 64)

	if search == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Search query required"})
		return
	}

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 50 {
		limit = 20
	}
	offset := (page - 1) * limit

	// Build query
	where := []string{
		"p.is_available = true",
		"s.is_active = true",
		"(p.title ILIKE $1 OR p.description ILIKE $1)",
	}
	args := []interface{}{"%" + search + "%"}
	argNum := 2

	if townID != "" {
		if id, err := uuid.Parse(townID); err == nil {
			where = append(where, "s.town_id = $"+strconv.Itoa(argNum))
			args = append(args, id)
			argNum++
		}
	}
	if categoryID != "" {
		if id, err := uuid.Parse(categoryID); err == nil {
			where = append(where, "p.category_id = $"+strconv.Itoa(argNum))
			args = append(args, id)
			argNum++
		}
	}
	if minPrice > 0 {
		where = append(where, "p.price >= $"+strconv.Itoa(argNum))
		args = append(args, minPrice)
		argNum++
	}
	if maxPrice > 0 {
		where = append(where, "p.price <= $"+strconv.Itoa(argNum))
		args = append(args, maxPrice)
		argNum++
	}

	whereClause := strings.Join(where, " AND ")

	// Count
	var totalCount int
	h.db.Pool.QueryRow(context.Background(),
		"SELECT COUNT(*) FROM products p JOIN stores s ON p.store_id = s.id WHERE "+whereClause,
		args...).Scan(&totalCount)

	// Get products
	args = append(args, limit, offset)
	query := `
		SELECT p.id, p.store_id, p.title, p.description, p.price,
			p.compare_at_price, p.pricing_type, p.condition, p.images,
			p.views, p.created_at,
			s.store_name, s.slug, s.logo_url, s.is_verified,
			t.name as town_name
		FROM products p
		JOIN stores s ON p.store_id = s.id
		LEFT JOIN towns t ON s.town_id = t.id
		WHERE ` + whereClause + `
		ORDER BY p.is_featured DESC, p.views DESC, p.created_at DESC
		LIMIT $` + strconv.Itoa(argNum) + ` OFFSET $` + strconv.Itoa(argNum+1)

	rows, err := h.db.Pool.Query(context.Background(), query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search products"})
		return
	}
	defer rows.Close()

	products := []models.Product{}
	for rows.Next() {
		var product models.Product
		var storeName, storeSlug, storeLogo, townName *string
		var storeVerified bool

		err := rows.Scan(
			&product.ID, &product.StoreID, &product.Title, &product.Description,
			&product.Price, &product.CompareAtPrice, &product.PricingType,
			&product.Condition, &product.Images, &product.Views, &product.CreatedAt,
			&storeName, &storeSlug, &storeLogo, &storeVerified, &townName,
		)
		if err != nil {
			continue
		}

		product.Store = &models.Store{
			ID:         product.StoreID,
			StoreName:  *storeName,
			Slug:       *storeSlug,
			LogoURL:    storeLogo,
			IsVerified: storeVerified,
		}
		if townName != nil {
			product.Store.Town = &models.Town{Name: *townName}
		}
		products = append(products, product)
	}

	c.JSON(http.StatusOK, models.ProductsResponse{
		Products:   products,
		TotalCount: totalCount,
		Page:       page,
		Limit:      limit,
	})
}

// ============ HELPERS ============

func (h *ProductHandler) getProductByID(productID uuid.UUID) (*models.Product, error) {
	var product models.Product
	var storeName, storeSlug, storeLogo, categoryName *string
	var storeVerified bool

	err := h.db.Pool.QueryRow(context.Background(), `
		SELECT p.id, p.store_id, p.title, p.description, p.price,
			p.compare_at_price, p.pricing_type, p.category_id, p.condition,
			p.images, p.stock_quantity, p.is_available, p.is_featured,
			p.views, p.enquiries, p.created_at, p.updated_at,
			s.store_name, s.slug, s.logo_url, s.is_verified,
			c.name as category_name
		FROM products p
		JOIN stores s ON p.store_id = s.id
		LEFT JOIN categories c ON p.category_id = c.id
		WHERE p.id = $1
	`, productID).Scan(
		&product.ID, &product.StoreID, &product.Title, &product.Description,
		&product.Price, &product.CompareAtPrice, &product.PricingType,
		&product.CategoryID, &product.Condition, &product.Images,
		&product.StockQuantity, &product.IsAvailable, &product.IsFeatured,
		&product.Views, &product.Enquiries, &product.CreatedAt, &product.UpdatedAt,
		&storeName, &storeSlug, &storeLogo, &storeVerified, &categoryName,
	)

	if err != nil {
		return nil, err
	}

	product.Store = &models.Store{
		ID:         product.StoreID,
		StoreName:  *storeName,
		Slug:       *storeSlug,
		LogoURL:    storeLogo,
		IsVerified: storeVerified,
	}
	if categoryName != nil {
		product.Category = &models.Category{Name: *categoryName}
	}

	return &product, nil
}

func nilIfZeroFloat(f float64) *float64 {
	if f == 0 {
		return nil
	}
	return &f
}
