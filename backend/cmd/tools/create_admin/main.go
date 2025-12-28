package main

import (
	"context"
	"fmt"
	"log"

	"github.com/airmass/backend/internal/config"
	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/pkg/password"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	db, err := database.New(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	email := "admin@trabab.com"
	username := "admin"
	pass := "password"
	fullName := "System Administrator"

	// Hash password
	hashedPassword, err := password.Hash(pass)
	if err != nil {
		log.Fatalf("Failed to hash password: %v", err)
	}

	// Check if user exists
	var exists bool
	err = db.Pool.QueryRow(context.Background(),
		"SELECT EXISTS(SELECT 1 FROM users WHERE email = $1 OR username = $2)",
		email, username).Scan(&exists)
	if err != nil {
		log.Fatalf("Database error: %v", err)
	}

	if exists {
		fmt.Printf("User with email %s or username %s already exists. Updating password...\n", email, username)
		_, err = db.Pool.Exec(context.Background(),
			"UPDATE users SET password_hash = $1 WHERE email = $2",
			hashedPassword, email)
		if err != nil {
			log.Fatalf("Failed to update user: %v", err)
		}
	} else {
		fmt.Printf("Creating admin user: %s (password: %s)...\n", email, pass)
		_, err = db.Pool.Exec(context.Background(),
			`INSERT INTO users (email, username, password_hash, full_name, is_verified, is_active)
			VALUES ($1, $2, $3, $4, true, true)`,
			email, username, hashedPassword, fullName)
		if err != nil {
			log.Fatalf("Failed to create user: %v", err)
		}
	}

	fmt.Println("Done!")
}
