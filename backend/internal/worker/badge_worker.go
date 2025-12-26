package worker

import (
	"context"
	"log"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/google/uuid"
)

// BadgeWorker handles automatic badge awarding based on user activity
type BadgeWorker struct {
	db *database.DB
}

// NewBadgeWorker creates a new badge worker
func NewBadgeWorker(db *database.DB) *BadgeWorker {
	return &BadgeWorker{db: db}
}

// Start begins the badge evaluation loop
func (w *BadgeWorker) Start(ctx context.Context) {
	log.Println("🏅 Badge Worker started")

	// Run immediately on startup
	w.evaluateAllBadges()

	// Then run every 5 minutes
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Println("🏅 Badge Worker stopped")
			return
		case <-ticker.C:
			w.evaluateAllBadges()
		}
	}
}

// evaluateAllBadges runs all badge evaluation functions
func (w *BadgeWorker) evaluateAllBadges() {
	log.Println("🏅 Evaluating badges for all users...")

	// Seller badges
	w.awardFirstSaleBadges()
	w.awardTrustedSellerBadges()
	w.awardSuperSellerBadges()
	w.awardPowerSellerBadges()
	w.awardQuickShipperBadges()
	w.awardActiveSellerBadges()

	// Buyer badges
	w.awardFirstWinBadges()
	w.awardPowerBuyerBadges()

	// Activity badges
	w.awardBidMasterBadges()
	w.awardWatchlistProBadges()

	// Community badges
	w.awardFiveStarBadges()
	w.awardTopRatedBadges()
	w.awardOGMemberBadges()
	w.awardOneYearBadges()

	// Verification badges
	w.awardPhoneVerifiedBadges()

	log.Println("🏅 Badge evaluation complete")
}

// Helper to award a badge to a user
func (w *BadgeWorker) awardBadge(userID uuid.UUID, badgeName string) {
	_, err := w.db.Pool.Exec(context.Background(), `
		INSERT INTO user_badges (user_id, badge_id, earned_at)
		SELECT $1, id, NOW()
		FROM badges
		WHERE name = $2 AND is_active = true
		ON CONFLICT (user_id, badge_id) DO NOTHING
	`, userID, badgeName)
	if err != nil {
		log.Printf("Failed to award badge %s to user %s: %v", badgeName, userID, err)
	}
}

// ============ SELLER BADGES ============

// awardFirstSaleBadges awards "First Sale" to users who completed 1 sale
func (w *BadgeWorker) awardFirstSaleBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT DISTINCT a.seller_id
		FROM auctions a
		WHERE a.status = 'ended'
		  AND a.winner_id IS NOT NULL
		  AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = a.seller_id AND b.name = 'first_sale'
		  )
	`)
	if err != nil {
		log.Printf("Error fetching first sale candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}
		w.awardBadge(userID, "first_sale")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'First Sale' badge to %d users", count)
	}
}

// awardTrustedSellerBadges awards to users with 5+ sales and good rating
func (w *BadgeWorker) awardTrustedSellerBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT a.seller_id, COUNT(*) as sales
		FROM auctions a
		WHERE a.status = 'ended' AND a.winner_id IS NOT NULL
		GROUP BY a.seller_id
		HAVING COUNT(*) >= 5
		AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = a.seller_id AND b.name = 'trusted_seller'
		)
	`)
	if err != nil {
		log.Printf("Error fetching trusted seller candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		var sales int
		if err := rows.Scan(&userID, &sales); err != nil {
			continue
		}
		w.awardBadge(userID, "trusted_seller")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Trusted Seller' badge to %d users", count)
	}
}

// awardSuperSellerBadges awards to users with 10+ sales and 4.5+ rating
func (w *BadgeWorker) awardSuperSellerBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT u.id
		FROM users u
		WHERE u.completed_auctions >= 10
		  AND u.rating >= 4.5
		  AND u.rating_count >= 5
		  AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = u.id AND b.name = 'super_seller'
		  )
	`)
	if err != nil {
		log.Printf("Error fetching super seller candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}
		w.awardBadge(userID, "super_seller")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Super Seller' badge to %d users", count)
	}
}

// awardPowerSellerBadges awards to users with 50+ sales and 4.8+ rating
func (w *BadgeWorker) awardPowerSellerBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT u.id
		FROM users u
		WHERE u.completed_auctions >= 50
		  AND u.rating >= 4.8
		  AND u.rating_count >= 20
		  AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = u.id AND b.name = 'power_seller'
		  )
	`)
	if err != nil {
		log.Printf("Error fetching power seller candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}
		w.awardBadge(userID, "power_seller")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Power Seller' badge to %d users", count)
	}
}

// awardQuickShipperBadges awards to sellers with consistent fast shipping
// (This would normally check shipping records, but we'll use a placeholder)
func (w *BadgeWorker) awardQuickShipperBadges() {
	// Placeholder: In production, this would check shipping confirmation times
	// For now, we skip this badge as it requires additional tracking
}

// awardActiveSellerBadges awards to users with 3+ active auctions
func (w *BadgeWorker) awardActiveSellerBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT seller_id, COUNT(*) as active_count
		FROM auctions
		WHERE status = 'active'
		GROUP BY seller_id
		HAVING COUNT(*) >= 3
		AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = auctions.seller_id AND b.name = 'active_seller'
		)
	`)
	if err != nil {
		log.Printf("Error fetching active seller candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		var activeCount int
		if err := rows.Scan(&userID, &activeCount); err != nil {
			continue
		}
		w.awardBadge(userID, "active_seller")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Active Seller' badge to %d users", count)
	}
}

// ============ BUYER BADGES ============

// awardFirstWinBadges awards "First Win" to users who won 1 auction
func (w *BadgeWorker) awardFirstWinBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT DISTINCT winner_id
		FROM auctions
		WHERE winner_id IS NOT NULL
		  AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = auctions.winner_id AND b.name = 'first_win'
		  )
	`)
	if err != nil {
		log.Printf("Error fetching first win candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}
		w.awardBadge(userID, "first_win")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'First Win' badge to %d users", count)
	}
}

// awardPowerBuyerBadges awards to users with 10+ auction wins
func (w *BadgeWorker) awardPowerBuyerBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT winner_id, COUNT(*) as wins
		FROM auctions
		WHERE winner_id IS NOT NULL
		GROUP BY winner_id
		HAVING COUNT(*) >= 10
		AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = auctions.winner_id AND b.name = 'power_buyer'
		)
	`)
	if err != nil {
		log.Printf("Error fetching power buyer candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		var wins int
		if err := rows.Scan(&userID, &wins); err != nil {
			continue
		}
		w.awardBadge(userID, "power_buyer")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Power Buyer' badge to %d users", count)
	}
}

// ============ ACTIVITY BADGES ============

// awardBidMasterBadges awards to users with 100+ bids placed
func (w *BadgeWorker) awardBidMasterBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT bidder_id, COUNT(*) as bid_count
		FROM bids
		GROUP BY bidder_id
		HAVING COUNT(*) >= 100
		AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = bids.bidder_id AND b.name = 'bid_master'
		)
	`)
	if err != nil {
		log.Printf("Error fetching bid master candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		var bidCount int
		if err := rows.Scan(&userID, &bidCount); err != nil {
			continue
		}
		w.awardBadge(userID, "bid_master")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Bid Master' badge to %d users", count)
	}
}

// awardWatchlistProBadges awards to users with 20+ items on watchlist
func (w *BadgeWorker) awardWatchlistProBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT user_id, COUNT(*) as watchlist_count
		FROM watchlist
		GROUP BY user_id
		HAVING COUNT(*) >= 20
		AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = watchlist.user_id AND b.name = 'watchlist_pro'
		)
	`)
	if err != nil {
		log.Printf("Error fetching watchlist pro candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		var watchlistCount int
		if err := rows.Scan(&userID, &watchlistCount); err != nil {
			continue
		}
		w.awardBadge(userID, "watchlist_pro")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Watchlist Pro' badge to %d users", count)
	}
}

// ============ COMMUNITY BADGES ============

// awardFiveStarBadges awards to users with 5.0 rating and 10+ reviews
func (w *BadgeWorker) awardFiveStarBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT id FROM users
		WHERE rating = 5.0
		  AND rating_count >= 10
		  AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = users.id AND b.name = 'five_star'
		  )
	`)
	if err != nil {
		log.Printf("Error fetching five star candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}
		w.awardBadge(userID, "five_star")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Five Star' badge to %d users", count)
	}
}

// awardTopRatedBadges awards to users with 4.9+ rating and 50+ reviews
func (w *BadgeWorker) awardTopRatedBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT id FROM users
		WHERE rating >= 4.9
		  AND rating_count >= 50
		  AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = users.id AND b.name = 'top_rated'
		  )
	`)
	if err != nil {
		log.Printf("Error fetching top rated candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}
		w.awardBadge(userID, "top_rated")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Top Rated' badge to %d users", count)
	}
}

// awardOGMemberBadges awards to users who joined in first 3 months
// This should be set manually or based on a launch date constant
func (w *BadgeWorker) awardOGMemberBadges() {
	// Define the OG cutoff date (3 months from launch)
	// For now, let's assume launch was Dec 1, 2025
	ogCutoff := time.Date(2026, 3, 1, 0, 0, 0, 0, time.UTC)

	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT id FROM users
		WHERE created_at < $1
		  AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = users.id AND b.name = 'og_member'
		  )
	`, ogCutoff)
	if err != nil {
		log.Printf("Error fetching OG member candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}
		w.awardBadge(userID, "og_member")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'OG Member' badge to %d users", count)
	}
}

// awardOneYearBadges awards to users who have been members for 1 year
func (w *BadgeWorker) awardOneYearBadges() {
	oneYearAgo := time.Now().AddDate(-1, 0, 0)

	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT id FROM users
		WHERE created_at < $1
		  AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = users.id AND b.name = 'one_year'
		  )
	`, oneYearAgo)
	if err != nil {
		log.Printf("Error fetching one year candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}
		w.awardBadge(userID, "one_year")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded '1 Year Member' badge to %d users", count)
	}
}

// ============ VERIFICATION BADGES ============

// awardPhoneVerifiedBadges awards to users who have verified their phone number
func (w *BadgeWorker) awardPhoneVerifiedBadges() {
	rows, err := w.db.Pool.Query(context.Background(), `
		SELECT id FROM users
		WHERE phone_verified = TRUE
		  AND NOT EXISTS (
			SELECT 1 FROM user_badges ub
			JOIN badges b ON ub.badge_id = b.id
			WHERE ub.user_id = users.id AND b.name = 'phone_verified'
		  )
	`)
	if err != nil {
		log.Printf("Error fetching phone verified candidates: %v", err)
		return
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}
		w.awardBadge(userID, "phone_verified")
		count++
	}
	if count > 0 {
		log.Printf("🏅 Awarded 'Phone Verified' badge to %d users", count)
	}
}

// EvaluateUserBadges evaluates and awards badges for a specific user (call after activity)
func (w *BadgeWorker) EvaluateUserBadges(userID uuid.UUID) {
	// Get user stats
	var completedSales, wins, bidCount, watchlistCount, ratingCount int
	var rating float64

	// Count completed sales
	w.db.Pool.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM auctions WHERE seller_id = $1 AND status = 'ended' AND winner_id IS NOT NULL
	`, userID).Scan(&completedSales)

	// Count wins
	w.db.Pool.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM auctions WHERE winner_id = $1
	`, userID).Scan(&wins)

	// Count bids
	w.db.Pool.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM bids WHERE bidder_id = $1
	`, userID).Scan(&bidCount)

	// Count watchlist
	w.db.Pool.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM watchlist WHERE user_id = $1
	`, userID).Scan(&watchlistCount)

	// Get rating
	w.db.Pool.QueryRow(context.Background(), `
		SELECT COALESCE(rating, 0), COALESCE(rating_count, 0) FROM users WHERE id = $1
	`, userID).Scan(&rating, &ratingCount)

	// Award badges based on stats
	if completedSales >= 1 {
		w.awardBadge(userID, "first_sale")
	}
	if completedSales >= 5 {
		w.awardBadge(userID, "trusted_seller")
	}
	if completedSales >= 10 && rating >= 4.5 && ratingCount >= 5 {
		w.awardBadge(userID, "super_seller")
	}
	if completedSales >= 50 && rating >= 4.8 && ratingCount >= 20 {
		w.awardBadge(userID, "power_seller")
	}

	if wins >= 1 {
		w.awardBadge(userID, "first_win")
	}
	if wins >= 10 {
		w.awardBadge(userID, "power_buyer")
	}

	if bidCount >= 100 {
		w.awardBadge(userID, "bid_master")
	}

	if watchlistCount >= 20 {
		w.awardBadge(userID, "watchlist_pro")
	}

	if rating == 5.0 && ratingCount >= 10 {
		w.awardBadge(userID, "five_star")
	}
	if rating >= 4.9 && ratingCount >= 50 {
		w.awardBadge(userID, "top_rated")
	}

	// Count active auctions
	var activeAuctions int
	w.db.Pool.QueryRow(context.Background(), `
		SELECT COUNT(*) FROM auctions WHERE seller_id = $1 AND status = 'active'
	`, userID).Scan(&activeAuctions)

	if activeAuctions >= 3 {
		w.awardBadge(userID, "active_seller")
	}
}
