package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		url = "postgres://postgres:postgres@localhost:5432/airmass"
	}

	db, err := pgxpool.New(context.Background(), url)
	if err != nil {
		fmt.Printf("Unable to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer db.Close()

	winnerID := "3fccc72c-ba24-4964-be04-fcedc9f64c9b" // From logs

	var username string
	var email string
	err = db.QueryRow(context.Background(), `SELECT username, email FROM users WHERE id = $1`, winnerID).Scan(&username, &email)
	if err != nil {
		fmt.Printf("Failed to find winner: %v\n", err)
		// continue?
	} else {
		fmt.Printf("Winner is: %s (%s)\n", username, email)
	}

	var notifCount int
	err = db.QueryRow(context.Background(), `SELECT COUNT(*) FROM notifications WHERE user_id = $1`, winnerID).Scan(&notifCount)
	fmt.Printf("Notification count for winner: %d\n", notifCount)

	// Check specifically for auction_won
	var wonNotifCount int
	err = db.QueryRow(context.Background(), `SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND type = 'auction_won'`, winnerID).Scan(&wonNotifCount)
	fmt.Printf("Auction Won notifications for winner: %d\n", wonNotifCount)

	// Check most recent notification
	var title, body, nType string
	err = db.QueryRow(context.Background(), `SELECT title, body, type FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1`, winnerID).Scan(&title, &body, &nType)
	if err == nil {
		fmt.Printf("Most recent notification: [%s] %s - %s\n", nType, title, body)
	}
}
