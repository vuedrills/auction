package router

import (
	"github.com/airmass/backend/internal/config"
	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/email"
	"github.com/airmass/backend/internal/fcm"
	"github.com/airmass/backend/internal/handlers"
	"github.com/airmass/backend/internal/middleware"
	"github.com/airmass/backend/internal/websocket"
	"github.com/airmass/backend/pkg/jwt"
	"github.com/airmass/backend/pkg/storage"
	"github.com/gin-gonic/gin"
)

// SetupRouter configures all routes
func SetupRouter(db *database.DB, jwtService *jwt.Service, hub *websocket.Hub, cfg *config.Config) *gin.Engine {
	r := gin.Default()

	// Middleware
	r.Use(middleware.CORS())

	// Services
	emailService := email.NewEmailService(cfg)
	fcmService, _ := fcm.NewFCMService(cfg) // FCM is optional, continues without it
	storageService := storage.NewSupabaseStorage(cfg.SupabaseURL, cfg.SupabaseServiceKey, cfg.SupabaseBucket)

	// Handlers
	authHandler := handlers.NewAuthHandler(db, jwtService, emailService, fcmService)
	townHandler := handlers.NewTownHandler(db)
	categoryHandler := handlers.NewCategoryHandler(db)
	auctionHandler := handlers.NewAuctionHandler(db, hub, fcmService)
	featuresHandler := handlers.NewFeaturesHandler(db, hub)
	notificationHandler := handlers.NewNotificationHandler(db, hub)
	chatHandler := handlers.NewChatHandler(db, hub, fcmService)
	shopChatHandler := handlers.NewShopChatHandler(db, hub, fcmService)
	badgeHandler := handlers.NewBadgeHandler(db)
	storeHandler := handlers.NewStoreHandler(db)
	productHandler := handlers.NewProductHandler(db)
	settingsHandler := handlers.NewSettingsHandler(db)
	uploadHandler := handlers.NewUploadHandler(storageService)
	wsHandler := websocket.NewHandler(hub, jwtService)

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// Initialize Analytics & Jobs Handlers
	analyticsHandler := handlers.NewAnalyticsHandler(db)
	jobHandler := handlers.NewJobHandler(db)
	adminHandler := handlers.NewAdminHandler(db)

	// API routes
	api := r.Group("/api")
	{
		// File Upload (authenticated)
		upload := api.Group("/upload")
		upload.Use(middleware.Auth(jwtService))
		{
			upload.POST("/image", uploadHandler.UploadImage)
			upload.POST("/images", uploadHandler.UploadMultipleImages)
		}

		// Authentication
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/google", authHandler.GoogleSignIn)

			// Phone authentication (DISABLED by default - set ENABLE_PHONE_AUTH=true to enable)
			// Requires Firebase SMS (paid service after free tier)
			// auth.POST("/phone/verify", middleware.Auth(jwtService), authHandler.VerifyPhone)
			// auth.POST("/phone/signin", authHandler.PhoneSignIn)
			// auth.POST("/phone/register", authHandler.PhoneRegister)

			auth.POST("/refresh-token", middleware.Auth(jwtService), authHandler.RefreshToken)
			auth.POST("/forgot-password", authHandler.ForgotPassword)
			auth.POST("/reset-password", authHandler.ResetPassword)
			auth.POST("/send-verification", middleware.Auth(jwtService), authHandler.SendVerificationEmail)
			auth.POST("/verify-email", middleware.Auth(jwtService), authHandler.VerifyEmail)
		}

		// Users
		users := api.Group("/users")
		{
			users.GET("", middleware.Auth(jwtService), authHandler.GetUsers) // Add this line
			users.GET("/me", middleware.Auth(jwtService), authHandler.GetMe)
			users.PUT("/me", middleware.Auth(jwtService), authHandler.UpdateProfile)
			users.PUT("/me/town", middleware.Auth(jwtService), authHandler.UpdateTown)

			// User ratings & reputation
			users.GET("/:userId/reputation", featuresHandler.GetUserReputation)
			users.GET("/:userId/ratings", featuresHandler.GetUserRatings)
			users.POST("/:userId/ratings", middleware.Auth(jwtService), featuresHandler.RateUser)

			// User Auctions & Bids (NEW)
			users.GET("/me/auctions", middleware.Auth(jwtService), auctionHandler.GetMyAuctions)
			users.GET("/me/bids", middleware.Auth(jwtService), auctionHandler.GetMyBids)
			users.GET("/me/won", middleware.Auth(jwtService), auctionHandler.GetWonAuctions)

			// Watchlist
			users.POST("/me/watchlist/:id", middleware.Auth(jwtService), auctionHandler.AddToWatchlist)
			users.DELETE("/me/watchlist/:id", middleware.Auth(jwtService), auctionHandler.RemoveFromWatchlist)
			users.GET("/me/watchlist", middleware.Auth(jwtService), auctionHandler.GetWatchlist)

			// Public Profile (NEW)
			users.GET("/:userId", authHandler.GetUserProfile)
			users.GET("/:userId/badges", badgeHandler.GetUserBadges)

			// Notification Preferences
			users.GET("/me/notification-preferences", middleware.Auth(jwtService), notificationHandler.GetPreferences)
			users.PUT("/me/notification-preferences", middleware.Auth(jwtService), notificationHandler.UpdatePreferences)

			// Badges & Verification
			users.GET("/me/badges", middleware.Auth(jwtService), badgeHandler.GetMyBadges)
			users.POST("/me/verification", middleware.Auth(jwtService), badgeHandler.SubmitVerification)
			users.GET("/me/verification-status", middleware.Auth(jwtService), badgeHandler.GetMyVerificationStatus)
		}

		// Notifications
		notifications := api.Group("/notifications")
		notifications.Use(middleware.Auth(jwtService))
		{
			notifications.GET("", notificationHandler.GetNotifications)
			notifications.GET("/unread-count", notificationHandler.GetUnreadCount)
			notifications.PUT("/:id/read", notificationHandler.MarkAsRead)
			notifications.PUT("/read-all", notificationHandler.MarkAllAsRead)
		}

		// Chats (Auction-related)
		chats := api.Group("/chats")
		chats.Use(middleware.Auth(jwtService))
		{
			chats.GET("", chatHandler.GetChats)
			chats.POST("/start", chatHandler.StartChatWithUser)
			chats.GET("/:id/messages", chatHandler.GetMessages)
			chats.POST("/:id/messages", chatHandler.SendMessage)
			chats.PUT("/:id/read", chatHandler.MarkAsRead)
			chats.PUT("/read-all", chatHandler.MarkAllAsRead)
		}

		// Shop Chats (Store-related, separate from auctions)
		shopChats := api.Group("/shop-chats")
		shopChats.Use(middleware.Auth(jwtService))
		{
			shopChats.GET("", shopChatHandler.GetShopConversations)
			shopChats.GET("/unread-count", shopChatHandler.GetUnreadShopCount)
			shopChats.POST("/start", shopChatHandler.StartShopConversation)
			shopChats.GET("/:id/messages", shopChatHandler.GetShopMessages)
			shopChats.POST("/:id/messages", shopChatHandler.SendShopMessage)
			shopChats.PUT("/:id/read", shopChatHandler.MarkShopConversationRead)
		}

		// Towns & Suburbs
		towns := api.Group("/towns")
		{
			towns.GET("", townHandler.GetTowns)
			towns.GET("/:id", townHandler.GetTown)
			towns.GET("/:id/suburbs", townHandler.GetSuburbs)

			// Town community features
			towns.GET("/:id/leaderboard", featuresHandler.GetTownLeaderboard)
			towns.GET("/:id/stats", featuresHandler.GetTownStats)
			towns.GET("/:id/top-sellers", featuresHandler.GetTopSellersInTown)
		}
		api.GET("/suburbs/:id", townHandler.GetSuburb)

		// Categories
		categories := api.Group("/categories")
		{
			categories.GET("", categoryHandler.GetCategories)
			categories.GET("/:id", categoryHandler.GetCategory)
			categories.GET("/:id/slots/:townId", categoryHandler.GetCategorySlots)
		}

		// Badges
		badges := api.Group("/badges")
		{
			badges.GET("", badgeHandler.GetBadges)
		}

		// Stores (Seller Storefronts)
		stores := api.Group("/stores")
		{
			stores.GET("", storeHandler.GetStores)
			stores.GET("/categories", storeHandler.GetStoreCategories)
			stores.GET("/featured", storeHandler.GetFeaturedStores)
			stores.GET("/nearby", middleware.Auth(jwtService), storeHandler.GetNearbyStores)
			stores.GET("/:slug", middleware.OptionalAuth(jwtService), storeHandler.GetStore)
			stores.GET("/:slug/products", productHandler.GetStoreProducts)

			// My store management (authenticated)
			stores.POST("", middleware.Auth(jwtService), storeHandler.CreateStore)
			stores.GET("/me", middleware.Auth(jwtService), storeHandler.GetMyStore)
			stores.PUT("/me", middleware.Auth(jwtService), storeHandler.UpdateMyStore)
			stores.DELETE("/me", middleware.Auth(jwtService), storeHandler.DeleteMyStore)
			stores.GET("/me/products", middleware.Auth(jwtService), productHandler.GetMyProducts)
			stores.POST("/me/products", middleware.Auth(jwtService), productHandler.CreateProduct)

			// Follow system
			stores.POST("/:id/follow", middleware.Auth(jwtService), storeHandler.FollowStore)
			stores.DELETE("/:id/follow", middleware.Auth(jwtService), storeHandler.UnfollowStore)

			// Tracking
			stores.POST("/:id/track", storeHandler.TrackEvent)

			// Admin Management
			stores.POST("/:id/verify", middleware.Auth(jwtService), storeHandler.VerifyStore)
			stores.DELETE("/:id", middleware.Auth(jwtService), storeHandler.DeleteStore)
		}

		// Products
		products := api.Group("/products")
		{
			products.GET("/search", productHandler.SearchProducts)
			products.GET("/stale", middleware.Auth(jwtService), productHandler.GetStaleProducts)
			products.GET("/:id", productHandler.GetProduct)
			products.PUT("/:id", middleware.Auth(jwtService), productHandler.UpdateProduct)
			products.DELETE("/:id", middleware.Auth(jwtService), productHandler.DeleteProduct)
			products.POST("/:id/confirm", middleware.Auth(jwtService), productHandler.ConfirmProduct)
		}

		// Following stores
		api.GET("/users/me/following-stores", middleware.Auth(jwtService), storeHandler.GetFollowingStores)

		// Auctions
		auctions := api.Group("/auctions")
		{
			auctions.GET("", middleware.OptionalAuth(jwtService), auctionHandler.GetAuctions)
			auctions.GET("/my-town", middleware.Auth(jwtService), auctionHandler.GetMyTownAuctions)
			auctions.GET("/national", middleware.OptionalAuth(jwtService), auctionHandler.GetNationalAuctions)
			auctions.GET("/:id", middleware.OptionalAuth(jwtService), auctionHandler.GetAuction)
			auctions.POST("", middleware.Auth(jwtService), auctionHandler.CreateAuction)
			auctions.DELETE("/:id", middleware.Auth(jwtService), auctionHandler.CancelAuction)

			// Bidding
			auctions.GET("/:id/bids", auctionHandler.GetBidHistory)
			auctions.POST("/:id/bids", middleware.Auth(jwtService), auctionHandler.PlaceBid)

			// Chat (NEW)
			auctions.POST("/:id/chat", middleware.Auth(jwtService), chatHandler.StartChat)

			// Auto-bid
			auctions.POST("/:id/auto-bid", middleware.Auth(jwtService), featuresHandler.SetAutoBid)
			auctions.DELETE("/:id/auto-bid", middleware.Auth(jwtService), featuresHandler.CancelAutoBid)

			// Promotions
			auctions.POST("/:id/promote", middleware.Auth(jwtService), featuresHandler.PromoteAuction)
		}

		// Saved Searches & Alerts
		searches := api.Group("/saved-searches")
		searches.Use(middleware.Auth(jwtService))
		{
			searches.GET("", featuresHandler.GetMySavedSearches)
			searches.POST("", featuresHandler.CreateSavedSearch)
			searches.DELETE("/:id", featuresHandler.DeleteSavedSearch)
		}

		// Auto-bids management
		autoBids := api.Group("/auto-bids")
		autoBids.Use(middleware.Auth(jwtService))
		{
			autoBids.GET("", featuresHandler.GetMyAutoBids)
		}

		// PROMOTION ENDPOINTS
		promotions := api.Group("/promotions")
		{
			promotions.GET("/pricing", featuresHandler.GetPromotionPricing)
			promotions.POST("/:id", middleware.Auth(jwtService), featuresHandler.PromoteAuction)
		}

		// ANALYTICS ENDPOINTS
		analytics := api.Group("/analytics")
		{
			// Batch track events (impressions, etc)
			// OptionalAuth for now, but could be strictly Auth depending on need.
			// ViewerID logic handles anonymous users.
			analytics.POST("/events/batch", middleware.OptionalAuth(jwtService), analyticsHandler.BatchTrackImpressions)

			// Dashboard stats
			analytics.GET("/store/:id", middleware.OptionalAuth(jwtService), analyticsHandler.GetStoreAnalytics)
		}

		// JOBS (Background Tasks)
		jobs := api.Group("/jobs")
		{
			jobs.POST("/nudge-stale-stores", jobHandler.CheckStaleStores)
		}

		// TEST ENDPOINTS (REMOVE IN PRODUCTION)
		testHandler := handlers.NewTestHandler(db, hub, fcmService)
		api.POST("/test/end-auction/:id", testHandler.EndAuctionTest)
		api.POST("/test/push-notification/:userId", testHandler.TestPushNotification)
		api.POST("/test/set-ending-soon/:id", testHandler.SetAuctionEndingSoon)
		api.POST("/test/update-email", testHandler.UpdateUserEmail)
		api.POST("/test/restale-store/:slug", testHandler.RestaleStore)

		// ADMIN ENDPOINTS (Restricted to dashboard users, though currently using general Auth)
		admin := api.Group("/admin")
		admin.Use(middleware.Auth(jwtService))
		{
			admin.GET("/stats", adminHandler.GetPlatformStats)
			admin.GET("/admins", adminHandler.ListAdmins)
			admin.POST("/admins", adminHandler.AddAdmin)
			admin.DELETE("/admins/:id", adminHandler.RemoveAdmin)
			admin.GET("/bids", auctionHandler.GetAllBids)
			admin.GET("/conversations", chatHandler.GetAllConversations)
			admin.GET("/conversations/:id/messages", chatHandler.GetConversationMessagesAdmin)
			admin.GET("/notifications", notificationHandler.GetAllNotifications)
			admin.POST("/notifications", notificationHandler.SendAdminNotification)

			// Auctions
			admin.GET("/auctions/:id", auctionHandler.GetAdminAuctionDetails)
			admin.DELETE("/auctions/:id", auctionHandler.AdminCancelAuction)
			admin.POST("/auctions/:id/approve", auctionHandler.AdminApproveAuction)
			admin.PUT("/auctions/:id/status", auctionHandler.AdminUpdateAuctionStatus)

			// Users
			admin.GET("/users/search", authHandler.SearchUsers)
			admin.GET("/users/:id", authHandler.GetAdminUserDetails)
			admin.PUT("/users/:id/status", authHandler.UpdateUserStatus)
			admin.PUT("/users/:id/verify", authHandler.VerifyUserByAdmin)

			// Categories
			admin.POST("/categories", categoryHandler.CreateCategory)
			admin.PUT("/categories/:id", categoryHandler.UpdateCategory)
			admin.DELETE("/categories/:id", categoryHandler.DeleteCategory)

			// Stores (Admin)
			admin.GET("/stores/:id", storeHandler.AdminGetStore)
			admin.PUT("/stores/:id", storeHandler.AdminUpdateStore)
			admin.GET("/stores/:id/products", storeHandler.AdminGetStoreProducts)
			admin.POST("/stores/:id/products", productHandler.AdminCreateProduct)

			// Products (Admin)
			admin.PUT("/products/:id", productHandler.AdminUpdateProduct)
			admin.DELETE("/products/:id", productHandler.AdminDeleteProduct)

			// Towns (Admin)
			admin.POST("/towns", townHandler.CreateTown)
			admin.PUT("/towns/:id", townHandler.UpdateTown)
			admin.DELETE("/towns/:id", townHandler.DeleteTown)
			admin.POST("/towns/:id/suburbs", townHandler.CreateSuburb)
			admin.DELETE("/towns/:id/suburbs/:suburbId", townHandler.DeleteSuburb)

			// Settings (Admin)
			admin.GET("/settings", settingsHandler.GetAllSettings)
			admin.PUT("/settings/:key", settingsHandler.UpdateSetting)
		}
	}

	// Public Settings
	api.GET("/settings/:key", settingsHandler.GetSetting)

	// WebSocket
	r.GET("/ws", wsHandler.HandleConnection)

	return r
}
