package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/joho/godotenv"
	"github.com/lib/pq"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found in current dir")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL is not set")
	}

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to DB: %v", err)
	}
	defer db.Close()

	// 1. Get Casino Royale Store ID
	var storeID string
	err = db.QueryRow("SELECT id FROM stores WHERE slug = 'casino-royale'").Scan(&storeID)
	if err != nil {
		log.Fatalf("Failed to get store: %v", err)
	}
	fmt.Printf("Found Store ID: %s\n", storeID)

	// 2. Fix Total Products Count
	var actualCount int
	err = db.QueryRow("SELECT COUNT(*) FROM products WHERE store_id = $1 AND is_available = true", storeID).Scan(&actualCount)
	if err != nil {
		log.Fatalf("Failed to count products: %v", err)
	}
	fmt.Printf("Actual Active Product Count: %d\n", actualCount)

	_, err = db.Exec("UPDATE stores SET total_products = $1 WHERE id = $2", actualCount, storeID)
	if err != nil {
		log.Fatalf("Failed to update store total_products: %v", err)
	}
	fmt.Println("Successfully updated total_products column.")

	// 3. Inspect Products Details
	query := `
		SELECT title, images, last_confirmed_at, is_featured, created_at
		FROM products 
		WHERE store_id = $1 AND is_available = true
		ORDER BY is_featured DESC, created_at DESC
	`
	rows, err := db.Query(query, storeID)
	if err != nil {
		log.Fatalf("Failed to query products: %v", err)
	}
	defer rows.Close()

	fmt.Printf("--- Products Details (UI Sort Order) ---\n")
	i := 0
	for rows.Next() {
		var title string
		var images []string
		var lastConfirmed *time.Time
		var isFeatured bool
		var createdAt time.Time

		if err := rows.Scan(&title, pq.Array(&images), &lastConfirmed, &isFeatured, &createdAt); err != nil {
			log.Fatalf("Scan error: %v", err)
		}

		fmt.Printf("[%d] %s\n", i, title)
		fmt.Printf("    Featured: %v\n", isFeatured)
		fmt.Printf("    Created: %v\n", createdAt)
		fmt.Printf("    Images (%d): %v\n", len(images), images)
		fmt.Printf("    Confirmed: %v\n", lastConfirmed)
		i++
	}
}
