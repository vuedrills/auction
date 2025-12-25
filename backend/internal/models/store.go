package models

import (
	"time"

	"github.com/google/uuid"
)

// StoreCategory represents a store category for browsing
type StoreCategory struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	DisplayName string    `json:"display_name"`
	Icon        string    `json:"icon"`
	SortOrder   int       `json:"sort_order"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
}

// Store represents a seller's storefront
type Store struct {
	ID                     uuid.UUID  `json:"id"`
	UserID                 uuid.UUID  `json:"user_id"`
	StoreName              string     `json:"store_name"`
	Slug                   string     `json:"slug"`
	Tagline                *string    `json:"tagline,omitempty"`
	About                  *string    `json:"about,omitempty"`
	LogoURL                *string    `json:"logo_url,omitempty"`
	CoverURL               *string    `json:"cover_url,omitempty"`
	CategoryID             *uuid.UUID `json:"category_id,omitempty"`
	WhatsApp               *string    `json:"whatsapp,omitempty"`
	Phone                  *string    `json:"phone,omitempty"`
	DeliveryOptions        []string   `json:"delivery_options"`
	DeliveryRadiusKm       *int       `json:"delivery_radius_km,omitempty"`
	OperatingHours         *string    `json:"operating_hours,omitempty"` // JSON string
	TownID                 *uuid.UUID `json:"town_id,omitempty"`
	SuburbID               *uuid.UUID `json:"suburb_id,omitempty"`
	Address                *string    `json:"address,omitempty"`
	IsActive               bool       `json:"is_active"`
	IsVerified             bool       `json:"is_verified"`
	IsFeatured             bool       `json:"is_featured"`
	TotalProducts          int        `json:"total_products"`
	TotalSales             int        `json:"total_sales"`
	FollowerCount          int        `json:"follower_count"`
	AvgResponseTimeMinutes *int       `json:"avg_response_time_minutes,omitempty"`
	Views                  int        `json:"views"`
	CreatedAt              time.Time  `json:"created_at"`
	UpdatedAt              time.Time  `json:"updated_at"`

	// Joined fields
	Owner         *User          `json:"owner,omitempty"`
	Category      *StoreCategory `json:"category,omitempty"`
	Town          *Town          `json:"town,omitempty"`
	Suburb        *Suburb        `json:"suburb,omitempty"`
	IsFollowing   bool           `json:"is_following,omitempty"`
	ProductsCount int            `json:"products_count,omitempty"`
}

// Product represents a fixed-price product in a store
type Product struct {
	ID             uuid.UUID  `json:"id"`
	StoreID        uuid.UUID  `json:"store_id"`
	Title          string     `json:"title"`
	Description    *string    `json:"description,omitempty"`
	Price          float64    `json:"price"`
	CompareAtPrice *float64   `json:"compare_at_price,omitempty"`
	PricingType    string     `json:"pricing_type"` // fixed, negotiable, service
	CategoryID     *uuid.UUID `json:"category_id,omitempty"`
	Condition      string     `json:"condition"` // new, used, refurbished
	Images         []string   `json:"images"`
	StockQuantity  int        `json:"stock_quantity"`
	IsAvailable    bool       `json:"is_available"`
	IsFeatured     bool       `json:"is_featured"`
	Views          int        `json:"views"`
	Enquiries      int        `json:"enquiries"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`

	// Joined fields
	Store    *Store    `json:"store,omitempty"`
	Category *Category `json:"category,omitempty"`
}

// StoreFollower represents a user following a store
type StoreFollower struct {
	ID         uuid.UUID `json:"id"`
	StoreID    uuid.UUID `json:"store_id"`
	UserID     uuid.UUID `json:"user_id"`
	FollowedAt time.Time `json:"followed_at"`

	// Joined
	User  *User  `json:"user,omitempty"`
	Store *Store `json:"store,omitempty"`
}

// StoreEnquiry represents a customer inquiry about a product
type StoreEnquiry struct {
	ID         uuid.UUID  `json:"id"`
	StoreID    uuid.UUID  `json:"store_id"`
	ProductID  *uuid.UUID `json:"product_id,omitempty"`
	CustomerID uuid.UUID  `json:"customer_id"`
	Message    *string    `json:"message,omitempty"`
	Status     string     `json:"status"` // pending, responded, converted, closed
	CreatedAt  time.Time  `json:"created_at"`
	UpdatedAt  time.Time  `json:"updated_at"`

	// Joined
	Customer *User    `json:"customer,omitempty"`
	Product  *Product `json:"product,omitempty"`
}

// StoreAnalytics represents daily analytics for a store
type StoreAnalytics struct {
	ID             uuid.UUID `json:"id"`
	StoreID        uuid.UUID `json:"store_id"`
	Date           time.Time `json:"date"`
	Views          int       `json:"views"`
	UniqueVisitors int       `json:"unique_visitors"`
	ProductViews   int       `json:"product_views"`
	Enquiries      int       `json:"enquiries"`
	WhatsAppClicks int       `json:"whatsapp_clicks"`
	CallClicks     int       `json:"call_clicks"`
	FollowsGained  int       `json:"follows_gained"`
}

// ============ REQUEST MODELS ============

// CreateStoreRequest represents request to create a store
type CreateStoreRequest struct {
	StoreName        string   `json:"store_name" binding:"required,min=2,max=100"`
	Tagline          string   `json:"tagline" binding:"max=100"`
	About            string   `json:"about"`
	LogoURL          string   `json:"logo_url"`
	CoverURL         string   `json:"cover_url"`
	CategoryID       string   `json:"category_id"`
	WhatsApp         string   `json:"whatsapp"`
	Phone            string   `json:"phone"`
	DeliveryOptions  []string `json:"delivery_options"`
	DeliveryRadiusKm int      `json:"delivery_radius_km"`
	TownID           string   `json:"town_id"`
	SuburbID         string   `json:"suburb_id"`
	Address          string   `json:"address"`
}

// UpdateStoreRequest represents request to update a store
type UpdateStoreRequest struct {
	StoreName        *string  `json:"store_name"`
	Tagline          *string  `json:"tagline"`
	About            *string  `json:"about"`
	LogoURL          *string  `json:"logo_url"`
	CoverURL         *string  `json:"cover_url"`
	CategoryID       *string  `json:"category_id"`
	WhatsApp         *string  `json:"whatsapp"`
	Phone            *string  `json:"phone"`
	DeliveryOptions  []string `json:"delivery_options"`
	DeliveryRadiusKm *int     `json:"delivery_radius_km"`
	OperatingHours   *string  `json:"operating_hours"`
	Address          *string  `json:"address"`
	IsActive         *bool    `json:"is_active"`
}

// CreateProductRequest represents request to create a product
type CreateProductRequest struct {
	Title          string   `json:"title" binding:"required,min=2,max=200"`
	Description    string   `json:"description"`
	Price          float64  `json:"price" binding:"required,gt=0"`
	CompareAtPrice float64  `json:"compare_at_price"`
	PricingType    string   `json:"pricing_type"` // fixed, negotiable, service
	CategoryID     string   `json:"category_id"`
	Condition      string   `json:"condition"` // new, used, refurbished
	Images         []string `json:"images"`
	StockQuantity  int      `json:"stock_quantity"`
}

// UpdateProductRequest represents request to update a product
type UpdateProductRequest struct {
	Title          *string  `json:"title"`
	Description    *string  `json:"description"`
	Price          *float64 `json:"price"`
	CompareAtPrice *float64 `json:"compare_at_price"`
	PricingType    *string  `json:"pricing_type"`
	CategoryID     *string  `json:"category_id"`
	Condition      *string  `json:"condition"`
	Images         []string `json:"images"`
	StockQuantity  *int     `json:"stock_quantity"`
	IsAvailable    *bool    `json:"is_available"`
}

// CreateEnquiryRequest represents request to send an enquiry
type CreateEnquiryRequest struct {
	ProductID string `json:"product_id"`
	Message   string `json:"message" binding:"required"`
}

// ============ RESPONSE MODELS ============

// StoreResponse wraps a single store
type StoreResponse struct {
	Store *Store `json:"store"`
}

// StoresResponse wraps a list of stores
type StoresResponse struct {
	Stores     []Store `json:"stores"`
	TotalCount int     `json:"total_count"`
	Page       int     `json:"page"`
	Limit      int     `json:"limit"`
}

// ProductResponse wraps a single product
type ProductResponse struct {
	Product *Product `json:"product"`
}

// ProductsResponse wraps a list of products
type ProductsResponse struct {
	Products   []Product `json:"products"`
	TotalCount int       `json:"total_count"`
	Page       int       `json:"page"`
	Limit      int       `json:"limit"`
}

// StoreAnalyticsResponse for dashboard
type StoreAnalyticsResponse struct {
	TotalViews     int              `json:"total_views"`
	TotalEnquiries int              `json:"total_enquiries"`
	TotalFollowers int              `json:"total_followers"`
	TotalProducts  int              `json:"total_products"`
	ViewsThisWeek  int              `json:"views_this_week"`
	ViewsThisMonth int              `json:"views_this_month"`
	TopProducts    []Product        `json:"top_products"`
	DailyStats     []StoreAnalytics `json:"daily_stats"`
}

// StoreCategoriesResponse wraps store categories
type StoreCategoriesResponse struct {
	Categories []StoreCategory `json:"categories"`
}
