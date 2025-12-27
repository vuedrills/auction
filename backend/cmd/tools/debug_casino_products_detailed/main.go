package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"github.com/lib/pq/hstore"
)

// Minimal struct for debug
type Product struct {
	ID              string
	Title           string
	Images          []string
	LastConfirmedAt sql.NullTime
}

func main() {
	if err := godotenv.Load("../../../.env"); err != nil {
		log.Println("Warning: .env file not found")
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

	// 2. Get Products with detailed info
	query := `
		SELECT title, images, last_confirmed_at 
		FROM products 
		WHERE store_id = $1 AND is_available = true
		ORDER BY created_at DESC
	`
	rows, err := db.Query(query, storeID)
	if err != nil {
		log.Fatalf("Failed to query products: %v", err)
	}
	defer rows.Close()

	fmt.Printf("--- Products for Store %s ---\n", storeID)
	for rows.Next() {
		var title string
		var images []string // pq scan requires pq.Array or similar for []string
		var lastConfirmed sql.NullTime

		// In pure pq, we use pq.Array(&images)
		// But let's check what the driver expects.
		// Actually, let's just get the raw bytes for images if it's tricky,
		// but pq.Array is standard.
		// Wait, the column type is text[]?
		// We need to import "github.com/lib/pq"

		// Using a simplified scan for debugging
		var imgArray []string
		if err := rows.Scan(&title, (*hstore.StringArray)(&imgArray), &lastConfirmed); err != nil {
			// Try pq.Array
			// Actually, I'll essentially re-write this file using the existing models if possible,
			// but the models are internal.
			// Let's just try to scan images as string for now if it fails.
			// Actually, I will use a CTE or just ignore images validation for a sec,
			// or use specific pq.Array.
		}
		// Let's skip the complexity and just use specific tool to read the file first to see imports.
	}
}
