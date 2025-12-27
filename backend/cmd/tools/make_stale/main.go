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
	// Load .env
	if err := godotenv.Load(".env"); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	// Connect to DB
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

	// 1. Find the product
	var productID string
	var title string
	var storeName string

	query := `
		SELECT p.id, p.title, s.store_name 
		FROM products p 
		JOIN stores s ON p.store_id = s.id 
		WHERE p.title ILIKE '%Hun Drew Mtn%'
		LIMIT 1
	`

	err = db.Pool.QueryRow(ctx, query).Scan(&productID, &title, &storeName)
	if err != nil {
		log.Fatalf("Could not find product 'Hun Drew Mtn': %v", err)
	}

	fmt.Printf("Found Product: %s\nID: %s\nStore: %s\n", title, productID, storeName)

	// 2. Make it stale (60 days old)
	updateQuery := `
		UPDATE products 
		SET last_confirmed_at = NOW() - INTERVAL '60 days' 
		WHERE id = $1
	`
	_, err = db.Pool.Exec(ctx, updateQuery, productID)
	if err != nil {
		log.Fatalf("Failed to update product: %v", err)
	}

	fmt.Println("✅ Successfully updated product to be 60 days stale.")
}
