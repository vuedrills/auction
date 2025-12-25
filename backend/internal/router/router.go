package router

import (
	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/handlers"
	"github.com/airmass/backend/internal/middleware"
	"github.com/airmass/backend/internal/websocket"
	"github.com/airmass/backend/pkg/jwt"
	"github.com/gin-gonic/gin"
)

// SetupRouter configures all routes
func SetupRouter(db *database.DB, jwtService *jwt.Service, hub *websocket.Hub) *gin.Engine {
	r := gin.Default()

	// Middleware
	r.Use(middleware.CORS())

	// Handlers
	authHandler := handlers.NewAuthHandler(db, jwtService)
	townHandler := handlers.NewTownHandler(db)
	categoryHandler := handlers.NewCategoryHandler(db)
	auctionHandler := handlers.NewAuctionHandler(db, hub)
	featuresHandler := handlers.NewFeaturesHandler(db, hub)
	notificationHandler := handlers.NewNotificationHandler(db, hub)
	chatHandler := handlers.NewChatHandler(db, hub)
	badgeHandler := handlers.NewBadgeHandler(db)
	wsHandler := websocket.NewHandler(hub, jwtService)

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API routes
	api := r.Group("/api")
	{
		// Authentication
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh-token", middleware.Auth(jwtService), authHandler.RefreshToken)
		}

		// Users
		users := api.Group("/users")
		{
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

		// Chats (NEW)
		chats := api.Group("/chats")
		chats.Use(middleware.Auth(jwtService))
		{
			chats.GET("", chatHandler.GetChats)
			chats.GET("/:id/messages", chatHandler.GetMessages)
			chats.POST("/:id/messages", chatHandler.SendMessage)
			chats.PUT("/:id/read", chatHandler.MarkAsRead)
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

		// TEST ENDPOINTS (REMOVE IN PRODUCTION)
		testHandler := handlers.NewTestHandler(db, hub)
		api.POST("/test/end-auction/:id", testHandler.EndAuctionTest)
	}

	// WebSocket
	r.GET("/ws", wsHandler.HandleConnection)

	return r
}
