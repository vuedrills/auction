package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"os"
	"time"

	"github.com/airmass/backend/pkg/password"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	// Try loading .env from various locations
	locations := []string{"../../.env", "../../../.env", ".env"}
	for _, loc := range locations {
		if err := godotenv.Load(loc); err == nil {
			fmt.Printf("Loaded .env from %s\n", loc)
			break
		}
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Println("DATABASE_URL is not set, checking default...")
		dbURL = "postgres://postgres:postgres@localhost:5432/airmass?sslmode=disable"
	}

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer pool.Close()

	log.Println("Connected to database")

	// 1. Clean Database
	cleanDatabase(ctx, pool)

	// 2. Get Town and Suburb (Harare, Avondale)
	var townId, suburbId string
	err = pool.QueryRow(ctx, "SELECT id FROM towns WHERE name = 'Harare' LIMIT 1").Scan(&townId)
	if err != nil {
		log.Fatalf("Harare town not found - did you run migrations (002)? %v", err)
	}

	err = pool.QueryRow(ctx, "SELECT id FROM suburbs WHERE name = 'Avondale' AND town_id = $1 LIMIT 1", townId).Scan(&suburbId)
	if err != nil {
		// Fallback to any suburb if Avondale missing
		log.Println("Avondale not found, using any suburb in Harare")
		err = pool.QueryRow(ctx, "SELECT id FROM suburbs WHERE town_id = $1 LIMIT 1", townId).Scan(&suburbId)
		if err != nil {
			log.Fatalf("No suburbs found for Harare: %v", err)
		}
	}

	// 3. Create Users
	aliceId := createUser(ctx, pool, "alice@example.com", "Alice Test", "alice", townId, suburbId)
	bobId := createUser(ctx, pool, "bob@example.com", "Bob Test", "bob", townId, suburbId)

	fmt.Printf("User Credentials:\n")
	fmt.Printf("1. Alice: alice@example.com / password123 (ID: %s)\n", aliceId)
	fmt.Printf("2. Bob:   bob@example.com   / password123 (ID: %s)\n", bobId)

	// 4. Create Auctions
	electronicsId := "11111111-1111-1111-1111-111111111111"
	furnitureId := "22222222-2222-2222-2222-222222222222"

	// Auction 1: iPhone 13 (Active) by Alice
	auction1Id := createAuction(ctx, pool, "iPhone 13 Pro Max", "Great condition, 256GB, Sierra Blue. Comes with box and cable.",
		600.00, aliceId, electronicsId, townId, suburbId, "active")

	// Auction 2: Sofa (Ending Soon) by Bob
	auction2Id := createAuction(ctx, pool, "Comfortable Grey Sectional", "Large grey sectional sofa, very comfortable. Must pick up.",
		250.00, bobId, furnitureId, townId, suburbId, "ending_soon")

	// Auction 3: Macbook Pro (Active) by Alice
	createAuction(ctx, pool, "Macbook Pro M1", "16GB RAM, 512GB SSD. Barely used.",
		1200.00, aliceId, electronicsId, townId, suburbId, "active")

	// 5. Create Bids
	// Bob bids on Alice's iPhone
	createBid(ctx, pool, auction1Id, bobId, 610.00)

	// Alice bids on Bob's Sofa
	createBid(ctx, pool, auction2Id, aliceId, 260.00)

	// 6. Create Conversations & Messages
	createConversation(ctx, pool, auction1Id, bobId, aliceId, "Is this still available? Can I see more photos?")

	// 7. Bulk Data
	seedBulkData(ctx, pool)

	log.Println("Seeding complete!")
}

func cleanDatabase(ctx context.Context, pool *pgxpool.Pool) {
	log.Println("Cleaning database...")
	queries := []string{
		"TRUNCATE TABLE messages CASCADE",
		"TRUNCATE TABLE conversations CASCADE",
		"TRUNCATE TABLE bids CASCADE",
		"TRUNCATE TABLE auctions CASCADE",
		"DELETE FROM users WHERE email NOT LIKE '%@example.com'", // Keep existing seeded users if any, or just wipe all? Let's wipe all for safety but Alice/Bob are re-created
		"TRUNCATE TABLE users CASCADE",
	}
	for _, q := range queries {
		_, err := pool.Exec(ctx, q)
		if err != nil {
			log.Printf("Warning cleaning db: %v", err)
		}
	}
	log.Println("Database cleaned.")
}

func seedBulkData(ctx context.Context, pool *pgxpool.Pool) {
	// 1. Fetch Metadata
	var categoryIds []string
	rows, _ := pool.Query(ctx, "SELECT id FROM categories")
	for rows.Next() {
		var id string
		rows.Scan(&id)
		categoryIds = append(categoryIds, id)
	}
	rows.Close()

	type Location struct {
		TownID   string
		SuburbID string
		IsHarare bool
	}
	var locations []Location

	rows, _ = pool.Query(ctx, `
        SELECT s.id, t.id, t.name = 'Harare' 
        FROM suburbs s 
        JOIN towns t ON s.town_id = t.id
    `)
	for rows.Next() {
		var l Location
		rows.Scan(&l.SuburbID, &l.TownID, &l.IsHarare)
		locations = append(locations, l)
	}
	rows.Close()

	if len(locations) == 0 {
		log.Println("No suburbs found, skipping bulk auction generation")
		return
	}

	// 2. Create Bulk Users (User 1 - User 50)
	var userIds []string
	for i := 1; i <= 50; i++ {
		email := fmt.Sprintf("user%d@example.com", i)
		name := fmt.Sprintf("User %d", i)
		username := fmt.Sprintf("user%d", i)

		loc := locations[i%len(locations)]

		uid := createUser(ctx, pool, email, name, username, loc.TownID, loc.SuburbID)
		userIds = append(userIds, uid)
	}

	// 3. Create Auctions (150 auctions)
	titles := []string{
		"Vintage Camera", "Mountain Bike", "Leather Jacket", "Dining Table", "Gaming PC",
		"Acoustic Guitar", "Smart Watch", "Camping Tent", "Bookshelf", "Microwave",
		"Coffee Maker", "Office Chair", "Running Shoes", "Laptop Stand", "Bluetooth Speaker",
		"Garden Tools", "Baby Stroller", "DSLR Lens", "Yoga Mat", "Desk Lamp",
	}

	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	for i := 0; i < 150; i++ {
		sellerId := userIds[i%len(userIds)]
		catId := categoryIds[i%len(categoryIds)]

		var loc Location
		if i%10 < 7 { // 70% chance Harare
			for {
				l := locations[r.Intn(len(locations))]
				if l.IsHarare {
					loc = l
					break
				}
			}
		} else {
			for {
				l := locations[r.Intn(len(locations))]
				if !l.IsHarare {
					loc = l
					break
				}
			}
		}

		title := fmt.Sprintf("%s %d", titles[i%len(titles)], i)
		desc := fmt.Sprintf("Great condition %s. Selling because I moved. Pick up in %s.", title, "town")
		price := float64(10 + (i * 5))

		status := "active"
		if i%10 == 0 {
			status = "ending_soon"
		}
		if i%20 == 0 {
			status = "sold"
		}

		auctionId := createAuction(ctx, pool, title, desc, price, sellerId, catId, loc.TownID, loc.SuburbID, status)

		if status == "active" || status == "ending_soon" {
			numBids := i % 5
			currentPrice := price
			for b := 0; b < numBids; b++ {
				bidderId := userIds[(i+b+1)%len(userIds)]
				bidAmount := currentPrice + 5.0
				createBid(ctx, pool, auctionId, bidderId, bidAmount)
				currentPrice = bidAmount
			}
		}
	}
}

func createUser(ctx context.Context, pool *pgxpool.Pool, email, name, username, townId, suburbId string) string {
	var id string
	err := pool.QueryRow(ctx, "SELECT id FROM users WHERE email = $1", email).Scan(&id)
	if err == nil {
		return id
	}

	hashed, _ := password.Hash("password123")
	err = pool.QueryRow(ctx, `
        INSERT INTO users (email, username, password_hash, full_name, is_verified, home_town_id, home_suburb_id)
        VALUES ($1, $2, $3, $4, true, $5, $6)
        RETURNING id
    `, email, username, hashed, name, townId, suburbId).Scan(&id)
	if err != nil {
		log.Printf("Failed to create user %s: %v", email, err)
		// Try fetch again
		pool.QueryRow(ctx, "SELECT id FROM users WHERE email = $1", email).Scan(&id)
		return id
	}
	log.Printf("Created user %s", email)
	return id
}

func createAuction(ctx context.Context, pool *pgxpool.Pool, title, desc string, price float64, sellerId, catId, townId, suburbId, status string) string {
	var id string
	endTime := time.Now().Add(48 * time.Hour)
	if status == "ending_soon" {
		endTime = time.Now().Add(30 * time.Minute)
	}

	// Varied Images using Picsum ID
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	// Pick random IDs to ensure uniqueness
	id1 := r.Intn(500) + 1
	id2 := r.Intn(500) + 501
	images := []string{
		fmt.Sprintf("https://picsum.photos/id/%d/400/300", id1),
		fmt.Sprintf("https://picsum.photos/id/%d/400/300", id2),
	}

	err := pool.QueryRow(ctx, `
        INSERT INTO auctions (title, description, starting_price, current_price, seller_id, category_id, town_id, suburb_id, status, start_time, end_time, images)
        VALUES ($1, $2, $3, $3, $4, $5, $6, $7, $8, NOW(), $9, $10)
        RETURNING id
    `, title, desc, price, sellerId, catId, townId, suburbId, status, endTime, images).Scan(&id)
	if err != nil {
		log.Printf("Failed to create auction %s: %v", title, err)
	} else {
		log.Printf("Created auction: %s", title)
	}
	return id
}

func createBid(ctx context.Context, pool *pgxpool.Pool, auctionId, bidderId string, amount float64) {
	if auctionId == "" {
		return
	}
	_, err := pool.Exec(ctx, `
        INSERT INTO bids (auction_id, bidder_id, amount)
        VALUES ($1, $2, $3)
    `, auctionId, bidderId, amount)

	if err == nil {
		pool.Exec(ctx, "UPDATE auctions SET current_price = $1, total_bids = total_bids + 1 WHERE id = $2", amount, auctionId)
		log.Printf("Placed bid of %.2f on auction %s", amount, auctionId)
	}
}

func createConversation(ctx context.Context, pool *pgxpool.Pool, auctionId, senderId, receiverId, initialMessage string) {
	if auctionId == "" {
		return
	}
	var convId string
	err := pool.QueryRow(ctx, `SELECT id FROM conversations WHERE auction_id = $1 AND ((participant_1 = $2 AND participant_2 = $3) OR (participant_1 = $3 AND participant_2 = $2))`, auctionId, senderId, receiverId).Scan(&convId)

	if err != nil {
		err = pool.QueryRow(ctx, `
			INSERT INTO conversations (auction_id, participant_1, participant_2, last_message_preview, last_message_at)
			VALUES ($1, $2, $3, $4, NOW())
			RETURNING id
		`, auctionId, senderId, receiverId, initialMessage).Scan(&convId)

		if err != nil {
			log.Printf("Failed to create conversation: %v", err)
			return
		}
	}

	pool.Exec(ctx, `
        INSERT INTO messages (conversation_id, sender_id, content)
        VALUES ($1, $2, $3)
    `, convId, senderId, initialMessage)

	log.Printf("Created conversation/message between %s and %s", senderId, receiverId)
}
