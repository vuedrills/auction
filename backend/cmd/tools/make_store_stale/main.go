package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/airmass/backend/internal/database"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(".env"); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL is not set")
	}

	db, err := database.New(dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	ctx := context.Background()

	// 1. Find the Store "Casino Royale"
	var storeID string
	err = db.Pool.QueryRow(ctx, "SELECT id FROM stores WHERE store_name ILIKE '%Casino Royale%' LIMIT 1").Scan(&storeID)
	if err != nil {
		log.Fatalf("Could not find store 'Casino Royale': %v", err)
	}
	fmt.Printf("Found Store ID: %s\n", storeID)

	// 2. Make ALL its products stale
	res, err := db.Pool.Exec(ctx, `
		UPDATE products 
		SET last_confirmed_at = NOW() - INTERVAL '60 days' 
		WHERE store_id = $1
	`, storeID)
	if err != nil {
		log.Fatalf("Failed to update products: %v", err)
	}

	fmt.Printf("✅ Updated %d products to be stale for store 'Casino Royale'.\n", res.RowsAffected())
}
