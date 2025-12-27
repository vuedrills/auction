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

	// 1. Get Store Owner
	var storeID, userID, storeName string
	var email, username string

	err = db.Pool.QueryRow(ctx, `
		SELECT s.id, s.store_name, s.user_id, u.email, u.username 
		FROM stores s
		JOIN users u ON s.user_id = u.id
		WHERE s.store_name ILIKE '%Casino Royale%'
	`).Scan(&storeID, &storeName, &userID, &email, &username)

	if err != nil {
		log.Fatalf("Err finding store: %v", err)
	}

	fmt.Printf("Store: %s\nOwner: %s (%s)\nUserID: %s\n", storeName, username, email, userID)

	// 2. Check for Start Notifications for this User
	fmt.Println("--- Recent Notifications for User ---")
	rows, err := db.Pool.Query(ctx, `
		SELECT id, type, title, body, created_at, is_read 
		FROM notifications 
		WHERE user_id = $1 
		ORDER BY created_at DESC 
		LIMIT 5
	`, userID)
	if err != nil {
		log.Fatalf("Err querying notifications: %v", err)
	}
	defer rows.Close()

	found := false
	for rows.Next() {
		var nid, ntype, ntitle, nbody string
		var ncreated time.Time
		var nread bool
		rows.Scan(&nid, &ntype, &ntitle, &nbody, &ncreated, &nread)
		fmt.Printf("[%v] %s | %s | %s | Read: %v\n", ncreated.Format(time.RFC3339), ntype, ntitle, nbody, nread)
		if ntitle == "Boost Your Visibility" {
			found = true
		}
	}

	if found {
		fmt.Println("✅ SUCCESS: Notification found in DB.")
	} else {
		fmt.Println("❌ FAILURE: Notification NOT found in DB.")
	}
}
