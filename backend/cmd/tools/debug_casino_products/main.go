package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL is not set")
	}

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// 1. Get Store ID for Casino Royale
	var storeID string
	err = db.QueryRow("SELECT id FROM stores WHERE slug = 'casino-royale'").Scan(&storeID)
	if err != nil {
		log.Fatalf("Could not find store: %v", err)
	}
	fmt.Printf("Store ID: %s\n", storeID)

	// 2. Count products
	var total, available int
	db.QueryRow("SELECT COUNT(*), COUNT(CASE WHEN is_available THEN 1 END) FROM products WHERE store_id = $1", storeID).Scan(&total, &available)
	fmt.Printf("Total DB Products: %d, Available: %d\n", total, available)

	// 3. List products
	rows, err := db.Query("SELECT title, is_available, last_confirmed_at FROM products WHERE store_id = $1", storeID)
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	fmt.Println("\nProduct List:")
	for rows.Next() {
		var title string
		var isAvail bool
		var lastConf *string
		rows.Scan(&title, &isAvail, &lastConf)
		confStr := "nil"
		if lastConf != nil {
			confStr = *lastConf
		}
		fmt.Printf("- %s | Available: %v | Confirmed: %s\n", title, isAvail, confStr)
	}
}
