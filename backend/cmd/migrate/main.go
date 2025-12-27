package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

func main() {
	if err := godotenv.Load(".env"); err != nil {
		log.Println("Warning: .env file not found")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL not set")
	}

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatal(err)
	}

	fmt.Println("Connected to DB")

	// Read migration file
	content, err := os.ReadFile("internal/database/migrations/012_make_product_id_nullable.sql")
	if err != nil {
		log.Fatal(err)
	}

	_, err = db.ExecContext(context.Background(), string(content))
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Migration 012 applied successfully")
}
