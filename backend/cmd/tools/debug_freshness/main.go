package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(".env"); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	dbURL := os.Getenv("DATABASE_URL")
	db, err := database.New(dbURL)
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer db.Close()
	ctx := context.Background()

	storeID := "b4cad616-7783-4f17-98c6-98439c6222ce"

	// 1. Check Store Status
	var isActive, isVerified bool
	var storeName string
	err = db.Pool.QueryRow(ctx, "SELECT store_name, is_active, is_verified FROM stores WHERE id = $1", storeID).
		Scan(&storeName, &isActive, &isVerified)
	if err != nil {
		log.Fatalf("Err querying store: %v", err)
	}
	fmt.Printf("Store: %s | Active: %v | Verified: %v\n", storeName, isActive, isVerified)

	// 2. Check Products
	rows, err := db.Pool.Query(ctx,
		"SELECT id, title, is_available, last_confirmed_at FROM products WHERE store_id = $1", storeID)
	if err != nil {
		log.Fatalf("Err querying products: %v", err)
	}
	defer rows.Close()

	fmt.Println("--- Products ---")
	for rows.Next() {
		var id, title string
		var isAvail bool
		var lastConf *time.Time
		rows.Scan(&id, &title, &isAvail, &lastConf)
		fmt.Printf("ID: %s | %s | Avail: %v | LastConf: %v\n", id, title, isAvail, lastConf)
	}

	// 3. Test the Job Query directly
	fmt.Println("--- Testing Job Query ---")
	jobQuery := `
		SELECT s.id, MAX(p.last_confirmed_at) as last_activity
		FROM stores s
		JOIN products p ON s.id = p.store_id
		WHERE s.id = $1 AND s.is_active = true AND p.is_available = true
		GROUP BY s.id
		HAVING MAX(p.last_confirmed_at) < NOW() - INTERVAL '30 days'
	`
	var foundID string
	var maxTime *time.Time
	err = db.Pool.QueryRow(ctx, jobQuery, storeID).Scan(&foundID, &maxTime)
	if err != nil {
		fmt.Printf("Query returned error (or no rows): %v\n", err)
	} else {
		fmt.Printf("Job Query MATCHED! StoreID: %s, MaxTime: %v\n", foundID, maxTime)
	}

	// 4. Check Notifications
	fmt.Println("--- Notifications ---")
	rowsNotif, err := db.Pool.Query(ctx,
		"SELECT id, title, created_at FROM notifications WHERE type = 'system' ORDER BY created_at DESC LIMIT 5")
	if err != nil {
		log.Fatalf("Err querying notifications: %v", err)
	}
	defer rowsNotif.Close()

	for rowsNotif.Next() {
		var nid, ntitle string
		var ncreated time.Time
		rowsNotif.Scan(&nid, &ntitle, &ncreated)
		fmt.Printf("Notif: %s | %s | %s\n", nid, ntitle, ncreated)
	}
}
