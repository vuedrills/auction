package worker

import (
	"context"
	"log"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/fcm"
	"github.com/airmass/backend/internal/services"
	"github.com/airmass/backend/internal/websocket"
	"github.com/google/uuid"
)

type AuctionWorker struct {
	db              *database.DB
	hub             *websocket.Hub
	fcmService      *fcm.FCMService
	notificationSvc *services.NotificationService
	badgeWorker     *BadgeWorker
}

func NewAuctionWorker(db *database.DB, hub *websocket.Hub, fcmService *fcm.FCMService) *AuctionWorker {
	return &AuctionWorker{
		db:              db,
		hub:             hub,
		fcmService:      fcmService,
		notificationSvc: services.NewNotificationService(db, hub, fcmService),
		badgeWorker:     NewBadgeWorker(db),
	}
}

func (w *AuctionWorker) Start(ctx context.Context) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	log.Println("🛠️ Auction Worker started")

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			w.processAuctions()
		}
	}
}

func (w *AuctionWorker) processAuctions() {
	ctx := context.Background()

	// 1. End expired auctions
	w.endExpiredAuctions(ctx)

	// 2. Transition auctions to 'ending_soon' (e.g. 1 hour left)
	w.updateEndingSoon(ctx)

	// 3. Process waiting list (pending -> active)
	w.processWaitingList(ctx)
}

func (w *AuctionWorker) endExpiredAuctions(ctx context.Context) {
	rows, err := w.db.Pool.Query(ctx, `
		SELECT id, title, seller_id, town_id, category_id 
		FROM auctions 
		WHERE status IN ('active', 'ending_soon') AND end_time <= NOW()
	`)
	if err != nil {
		return
	}
	defer rows.Close()

	for rows.Next() {
		var auctionID, sellerID, townID, categoryID uuid.UUID
		var title string
		if err := rows.Scan(&auctionID, &title, &sellerID, &townID, &categoryID); err != nil {
			continue
		}

		// Find highest bidder
		var winnerID uuid.UUID
		var winnerName string
		var finalAmount float64
		err := w.db.Pool.QueryRow(ctx, `
			SELECT b.bidder_id, u.full_name, b.amount
			FROM bids b
			JOIN users u ON u.id = b.bidder_id
			WHERE b.auction_id = $1
			ORDER BY b.amount DESC
			LIMIT 1
		`, auctionID).Scan(&winnerID, &winnerName, &finalAmount)

		if err != nil {
			// No bids - just end the auction
			w.db.Pool.Exec(ctx, "UPDATE auctions SET status = 'ended' WHERE id = $1", auctionID)

			// Notify seller that auction ended with no bids
			w.notificationSvc.SendAuctionEndedNotification(ctx, sellerID, auctionID, title)

			log.Printf("⏰ Auction ended with no bids: %s (%s)", title, auctionID)
		} else {
			// Update auction with winner
			_, err = w.db.Pool.Exec(ctx, `
				UPDATE auctions 
				SET status = 'ended', winner_id = $1, final_amount = $2 
				WHERE id = $3
			`, winnerID, finalAmount, auctionID)

			if err != nil {
				log.Printf("Error updating auction winner: %v", err)
				continue
			}

			// Create conversation between winner and seller first
			conversationID, err := w.notificationSvc.CreateConversation(ctx, auctionID, sellerID, winnerID)
			if err != nil {
				log.Printf("Error creating conversation: %v", err)
			} else {
				log.Printf("💬 Created conversation %s for auction %s", conversationID, auctionID)
			}

			// Send notification to winner
			w.notificationSvc.SendAuctionWonNotification(ctx, winnerID, auctionID, conversationID, title, finalAmount)

			// Send notification to seller
			w.notificationSvc.SendAuctionSoldNotification(ctx, sellerID, auctionID, conversationID, title, winnerName, finalAmount)

			// Evaluate badges for seller and winner
			go w.badgeWorker.EvaluateUserBadges(sellerID)
			go w.badgeWorker.EvaluateUserBadges(winnerID)

			log.Printf("🏆 Auction won: %s (%s) by %s for R%.2f", title, auctionID, winnerName, finalAmount)
		}

		// Broadcast update to town
		w.hub.BroadcastToTown(townID, websocket.MessageTypeAuctionUpdate, map[string]interface{}{
			"action":     "auction_ended",
			"auction_id": auctionID,
			"title":      title,
		})
	}
}

func (w *AuctionWorker) updateEndingSoon(ctx context.Context) {
	// Find auctions that just switched to 'ending_soon' (less than 1 hour left)
	rows, err := w.db.Pool.Query(ctx, `
		UPDATE auctions 
		SET status = 'ending_soon' 
		WHERE status = 'active' AND end_time <= NOW() + INTERVAL '1 hour'
		RETURNING id, title
	`)
	if err != nil {
		return
	}
	defer rows.Close()

	for rows.Next() {
		var auctionID uuid.UUID
		var title string
		if err := rows.Scan(&auctionID, &title); err != nil {
			continue
		}

		// Send push notification to all bidders on this auction
		go func(auctionID uuid.UUID, title string) {
			bidderRows, err := w.db.Pool.Query(ctx, `
				SELECT DISTINCT u.fcm_token 
				FROM bids b 
				JOIN users u ON u.id = b.bidder_id 
				WHERE b.auction_id = $1 AND u.fcm_token IS NOT NULL
			`, auctionID)
			if err != nil {
				return
			}
			defer bidderRows.Close()

			for bidderRows.Next() {
				var fcmToken *string
				if err := bidderRows.Scan(&fcmToken); err != nil || fcmToken == nil {
					continue
				}
				err := w.fcmService.SendAuctionEndingNotification(*fcmToken, title, "less than 1 hour", auctionID.String())
				if err != nil {
					log.Printf("Failed to send ending soon push: %v", err)
				}
			}
		}(auctionID, title)
	}
}

func (w *AuctionWorker) processWaitingList(ctx context.Context) {
	// Get all categories/towns that have pending auctions
	rows, err := w.db.Pool.Query(ctx,
		"SELECT DISTINCT category_id, town_id FROM auctions WHERE status = 'pending'")
	if err != nil {
		return
	}
	defer rows.Close()

	for rows.Next() {
		var catID, townID uuid.UUID
		if err := rows.Scan(&catID, &townID); err != nil {
			continue
		}

		// Check available slots
		var maxActive, currentActive int
		w.db.Pool.QueryRow(ctx,
			"SELECT COALESCE(max_active_auctions, 10) FROM category_slots WHERE category_id = $1 AND town_id = $2",
			catID, townID,
		).Scan(&maxActive)
		if maxActive == 0 {
			maxActive = 10
		}

		w.db.Pool.QueryRow(ctx,
			"SELECT COUNT(*) FROM auctions WHERE category_id = $1 AND town_id = $2 AND status IN ('active', 'ending_soon')",
			catID, townID,
		).Scan(&currentActive)

		if currentActive < maxActive {
			slotsAvailable := maxActive - currentActive

			// Find oldest pending auctions
			pendingRows, err := w.db.Pool.Query(ctx,
				"SELECT id, title FROM auctions WHERE category_id = $1 AND town_id = $2 AND status = 'pending' ORDER BY created_at ASC LIMIT $3",
				catID, townID, slotsAvailable)
			if err != nil {
				continue
			}

			var activatedIDs []uuid.UUID
			for pendingRows.Next() {
				var pID uuid.UUID
				var pTitle string
				pendingRows.Scan(&pID, &pTitle)

				// Activate: reset start/end time
				// original duration is usually 7 days (168h)
				duration := 168 * time.Hour
				startTime := time.Now()
				endTime := startTime.Add(duration)

				_, err := w.db.Pool.Exec(ctx,
					"UPDATE auctions SET status = 'active', start_time = $1, end_time = $2, original_end_time = $2 WHERE id = $3",
					startTime, endTime, pID)

				if err == nil {
					activatedIDs = append(activatedIDs, pID)
					log.Printf("Auction activated from waiting list: %s (%s)", pTitle, pID)

					w.hub.BroadcastToTown(townID, websocket.MessageTypeAuctionUpdate, map[string]interface{}{
						"action":     "new_auction",
						"auction_id": pID,
						"title":      pTitle,
					})
				}
			}
			pendingRows.Close()
		}
	}
}
