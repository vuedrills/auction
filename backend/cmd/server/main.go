package main

import (
	"log"
	"os"

	"context"

	"github.com/airmass/backend/internal/config"
	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/router"
	"github.com/airmass/backend/internal/websocket"
	"github.com/airmass/backend/internal/worker"
	"github.com/airmass/backend/pkg/jwt"
	"github.com/gin-gonic/gin"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Set Gin mode
	gin.SetMode(cfg.GinMode)

	// Connect to database
	db, err := database.New(cfg.DatabaseURL)
	if err != nil {
		log.Printf("Warning: Failed to connect to database: %v", err)
		log.Println("Continuing without database connection...")
		db = &database.DB{}
	} else {
		defer db.Close()
		log.Println("Connected to PostgreSQL database")
	}

	// Create upload directory
	os.MkdirAll(cfg.UploadDir, 0755)

	// Initialize services
	jwtService := jwt.NewService(cfg.JWTSecret, cfg.JWTExpiryHours)

	// Initialize WebSocket hub
	hub := websocket.NewHub()
	go hub.Run()

	// Initialize and start background workers
	auctionWorker := worker.NewAuctionWorker(db, hub)
	go auctionWorker.Start(ctx)

	badgeWorker := worker.NewBadgeWorker(db)
	go badgeWorker.Start(ctx)

	// Setup router
	r := router.SetupRouter(db, jwtService, hub, cfg)

	// Start server
	log.Printf("🚀 AirMass API Server starting on port %s", cfg.Port)
	log.Printf("📍 WebSocket endpoint: ws://localhost:%s/ws", cfg.Port)

	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
