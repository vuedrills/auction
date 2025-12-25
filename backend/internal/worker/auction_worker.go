package worker

import (
	"context"
	"log"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/websocket"
	"github.com/google/uuid"
)

type AuctionWorker struct {
	db  *database.DB
	hub *websocket.Hub
}

func NewAuctionWorker(db *database.DB, hub *websocket.Hub) *AuctionWorker {
	return &AuctionWorker{
		db:  db,
		hub: hub,
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
	rows, err := w.db.Pool.Query(ctx,
		"SELECT id, title, town_id, category_id FROM auctions WHERE status IN ('active', 'ending_soon') AND end_time <= NOW()")
	if err != nil {
		return
	}
	defer rows.Close()

	for rows.Next() {
		var id uuid.UUID
		var title string
		var townID, categoryID uuid.UUID
		if err := rows.Scan(&id, &title, &townID, &categoryID); err != nil {
			continue
		}

		// Update status to 'ended'
		w.db.Pool.Exec(ctx, "UPDATE auctions SET status = 'ended' WHERE id = $1", id)

		log.Printf("Auction ended: %s (%s)", title, id)

		// Broadcast update
		w.hub.BroadcastToTown(townID, websocket.MessageTypeAuctionUpdate, map[string]interface{}{
			"action":     "auction_ended",
			"auction_id": id,
			"title":      title,
		})
	}
}

func (w *AuctionWorker) updateEndingSoon(ctx context.Context) {
	// Status -> 'ending_soon' if less than 1 hour left
	w.db.Pool.Exec(ctx,
		"UPDATE auctions SET status = 'ending_soon' WHERE status = 'active' AND end_time <= NOW() + INTERVAL '1 hour'")
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
