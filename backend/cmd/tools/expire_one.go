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
		url = "postgres:///airmass?host=/tmp&port=5433&sslmode=disable"
	}

	db, err := pgxpool.New(context.Background(), url)
	if err != nil {
		fmt.Printf("Unable to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer db.Close()

	var id string
	var title string
	err = db.QueryRow(context.Background(), `
        UPDATE auctions 
        SET end_time = NOW() - interval '1 minute' 
        WHERE id = (
            SELECT id FROM auctions 
            WHERE status = 'active'
            LIMIT 1
        ) 
        RETURNING id, title
    `).Scan(&id, &title)

	if err != nil {
		fmt.Printf("Update failed (maybe no active auctions?): %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Expired auction: %s (%s)\n", title, id)
}
