package handlers

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/fcm"
	"github.com/airmass/backend/internal/middleware"
	"github.com/airmass/backend/internal/models"
	"github.com/airmass/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ChatHandler struct {
	db         *database.DB
	hub        *websocket.Hub
	fcmService *fcm.FCMService
}

func NewChatHandler(db *database.DB, hub *websocket.Hub, fcmService *fcm.FCMService) *ChatHandler {
	return &ChatHandler{db: db, hub: hub, fcmService: fcmService}
}

// GetChats returns the user's conversations
func (h *ChatHandler) GetChats(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT c.id, c.auction_id, c.participant_1, c.participant_2, 
			   c.last_message_preview, c.last_message_at, c.unread_count_1, c.unread_count_2,
			   COALESCE(a.title, ''), a.images,
			   COALESCE(NULLIF(u1.full_name, ''), u1.username, 'Unknown'), u1.avatar_url,
			   COALESCE(NULLIF(u2.full_name, ''), u2.username, 'Unknown'), u2.avatar_url
		FROM conversations c
		LEFT JOIN auctions a ON c.auction_id = a.id
		LEFT JOIN users u1 ON c.participant_1 = u1.id
		LEFT JOIN users u2 ON c.participant_2 = u2.id
		WHERE c.participant_1 = $1 OR c.participant_2 = $1
		ORDER BY c.last_message_at DESC NULLS LAST
	`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch chats"})
		return
	}
	defer rows.Close()

	var chats []gin.H
	for rows.Next() {
		var id, auctionID uuid.UUID
		var p1, p2 uuid.UUID
		var lastMsg *string
		var lastMsgAt *time.Time
		var unread1, unread2 int
		var auctionTitle string
		var auctionImages []string
		var u1Name, u2Name string
		var u1Avatar, u2Avatar *string

		rows.Scan(&id, &auctionID, &p1, &p2, &lastMsg, &lastMsgAt, &unread1, &unread2,
			&auctionTitle, &auctionImages, &u1Name, &u1Avatar, &u2Name, &u2Avatar)

		// Determine other participant
		var otherID uuid.UUID
		var otherName string
		var otherAvatar *string
		var unread int

		if p1 == userID {
			otherID = p2
			otherName = u2Name
			otherAvatar = u2Avatar
			unread = unread1
		} else {
			otherID = p1
			otherName = u1Name
			otherAvatar = u1Avatar
			unread = unread2
		}

		img := ""
		if len(auctionImages) > 0 {
			img = auctionImages[0]
		}

		var lastMsgObj interface{}
		if lastMsg != nil {
			lastMsgObj = gin.H{
				"content":    lastMsg,
				"created_at": lastMsgAt,
			}
		}

		updatedAt := time.Now()
		if lastMsgAt != nil {
			updatedAt = *lastMsgAt
		}

		chats = append(chats, gin.H{
			"id":                 id,
			"auction_id":         auctionID,
			"auction_title":      auctionTitle,
			"auction_image":      img,
			"participant_id":     otherID,
			"participant_name":   otherName,
			"participant_avatar": otherAvatar,
			"last_message":       lastMsgObj,
			"unread_count":       unread,
			"updated_at":         updatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"chats": chats})
}

// GetMessages returns messages for a chat
func (h *ChatHandler) GetMessages(c *gin.Context) {
	idStr := c.Param("id")
	chatID, err := uuid.Parse(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chat ID"})
		return
	}

	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT id, conversation_id, sender_id, content, message_type, attachment_url, is_read, created_at
		FROM messages
		WHERE conversation_id = $1
		ORDER BY created_at DESC
		LIMIT 50
	`, chatID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch messages"})
		return
	}
	defer rows.Close()

	var messages []gin.H
	for rows.Next() {
		var m models.Message
		rows.Scan(&m.ID, &m.ConversationID, &m.SenderID, &m.Content, &m.MessageType, &m.AttachmentURL, &m.IsRead, &m.CreatedAt)

		messages = append(messages, gin.H{
			"id":         m.ID,
			"chat_id":    m.ConversationID,
			"sender_id":  m.SenderID,
			"content":    m.Content,
			"image_url":  m.AttachmentURL,
			"is_read":    m.IsRead,
			"created_at": m.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"messages": messages})
}

// SendMessage sends a message
func (h *ChatHandler) SendMessage(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	chatID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chat ID"})
		return
	}

	var req struct {
		Content  string `json:"content"`
		ImageURL string `json:"image_url"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var msgID uuid.UUID
	createdAt := time.Now()

	err = h.db.Pool.QueryRow(context.Background(), `
		INSERT INTO messages (conversation_id, sender_id, content, message_type, attachment_url, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id
	`, chatID, userID, req.Content, "text", req.ImageURL, createdAt).Scan(&msgID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	// Fetch other participant to broadcast
	var p1, p2 uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(), "SELECT participant_1, participant_2 FROM conversations WHERE id = $1", chatID).Scan(&p1, &p2)
	if err == nil {
		otherID := p1
		if p1 == userID {
			otherID = p2
		}

		// Update conversation last message and increment recipient's unread count
		h.db.Pool.Exec(context.Background(), `
			UPDATE conversations 
			SET last_message_preview = $2, last_message_at = $3,
				unread_count_1 = CASE WHEN participant_1 = $4 THEN unread_count_1 + 1 ELSE unread_count_1 END,
				unread_count_2 = CASE WHEN participant_2 = $4 THEN unread_count_2 + 1 ELSE unread_count_2 END
			WHERE id = $1
		`, chatID, req.Content, createdAt, otherID)

		// Broadcast to sender (marked as read since they sent it)
		h.hub.BroadcastToUser(userID, websocket.MessageTypeMessage, gin.H{
			"id":         msgID,
			"chat_id":    chatID,
			"sender_id":  userID,
			"content":    req.Content,
			"image_url":  req.ImageURL,
			"is_read":    true,
			"created_at": createdAt,
		})

		// Broadcast to recipient (marked as unread)
		h.hub.BroadcastToUser(otherID, websocket.MessageTypeMessage, gin.H{
			"id":         msgID,
			"chat_id":    chatID,
			"sender_id":  userID,
			"content":    req.Content,
			"image_url":  req.ImageURL,
			"is_read":    false,
			"created_at": createdAt,
		})

		// Send push notification to recipient
		go func() {
			// Get recipient's FCM token and sender's name
			var fcmToken *string
			var senderName string
			h.db.Pool.QueryRow(context.Background(),
				"SELECT fcm_token FROM users WHERE id = $1", otherID).Scan(&fcmToken)
			h.db.Pool.QueryRow(context.Background(),
				"SELECT COALESCE(NULLIF(full_name, ''), username) FROM users WHERE id = $1", userID).Scan(&senderName)

			if fcmToken != nil && *fcmToken != "" {
				// Truncate message preview
				preview := req.Content
				if len(preview) > 50 {
					preview = preview[:47] + "..."
				}
				err := h.fcmService.SendNewMessageNotification(*fcmToken, senderName, preview, chatID.String())
				if err != nil {
					log.Printf("Failed to send message push notification: %v", err)
				}
			}
		}()
	}

	c.JSON(http.StatusOK, gin.H{
		"id":         msgID,
		"chat_id":    chatID,
		"sender_id":  userID,
		"content":    req.Content,
		"image_url":  req.ImageURL,
		"is_read":    false,
		"created_at": createdAt,
	})
}

// StartChat creates a new chat or returns existing one (Auction context)
func (h *ChatHandler) StartChat(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	auctionID, err := uuid.Parse(c.Param("id")) // auction ID
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	var req struct {
		Message string `json:"message"`
	}
	c.ShouldBindJSON(&req)

	// Fetch auction to find seller
	var sellerID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(), "SELECT seller_id FROM auctions WHERE id = $1", auctionID).Scan(&sellerID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Auction not found"})
		return
	}

	// Check for existing conversation
	var chatID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(), `
		SELECT id FROM conversations 
		WHERE auction_id = $1 AND ((participant_1 = $2 AND participant_2 = $3) OR (participant_1 = $3 AND participant_2 = $2))
	`, auctionID, userID, sellerID).Scan(&chatID)

	if err != nil {
		// Create new
		err = h.db.Pool.QueryRow(context.Background(), `
			INSERT INTO conversations (auction_id, participant_1, participant_2, created_at, last_message_at)
			VALUES ($1, $2, $3, $4, $4)
			RETURNING id
		`, auctionID, userID, sellerID, time.Now()).Scan(&chatID)

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create chat"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"id":         chatID,
		"auction_id": auctionID,
	})
}

// StartChatWithUser creates a new chat or returns existing one for an auction
func (h *ChatHandler) StartChatWithUser(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	var req struct {
		TargetUserID string `json:"target_user_id" binding:"required"`
		AuctionID    string `json:"auction_id" binding:"required"` // Now required - all chats must be auction-related
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	targetID, err := uuid.Parse(req.TargetUserID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid target user ID"})
		return
	}

	if targetID == userID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot chat with yourself"})
		return
	}

	auctionID, err := uuid.Parse(req.AuctionID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid auction ID"})
		return
	}

	var chatID uuid.UUID

	// Check for existing auction conversation
	queryErr := h.db.Pool.QueryRow(context.Background(), `
		SELECT id FROM conversations 
		WHERE auction_id = $1 AND ((participant_1 = $2 AND participant_2 = $3) OR (participant_1 = $3 AND participant_2 = $2))
	`, auctionID, userID, targetID).Scan(&chatID)

	if queryErr != nil {
		// Create new conversation for this auction
		insertErr := h.db.Pool.QueryRow(context.Background(), `
			INSERT INTO conversations (auction_id, participant_1, participant_2, created_at, last_message_at)
			VALUES ($1, $2, $3, $4, $4)
			RETURNING id
		`, auctionID, userID, targetID, time.Now()).Scan(&chatID)

		if insertErr != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create chat"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"id":         chatID,
		"auction_id": auctionID,
	})
}

func (h *ChatHandler) MarkAsRead(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	chatID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid chat ID"})
		return
	}

	// Get conversation participants to determine which unread count to reset
	var p1, p2 uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(),
		"SELECT participant_1, participant_2 FROM conversations WHERE id = $1", chatID).
		Scan(&p1, &p2)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Chat not found"})
		return
	}

	// Reset the appropriate unread count based on which participant the user is
	if p1 == userID {
		_, err = h.db.Pool.Exec(context.Background(),
			"UPDATE conversations SET unread_count_1 = 0 WHERE id = $1", chatID)
	} else if p2 == userID {
		_, err = h.db.Pool.Exec(context.Background(),
			"UPDATE conversations SET unread_count_2 = 0 WHERE id = $1", chatID)
	} else {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not a participant in this chat"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark as read"})
		return
	}

	c.Status(http.StatusOK)
}

func (h *ChatHandler) MarkAllAsRead(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	_, err := h.db.Pool.Exec(context.Background(), `
		UPDATE conversations 
		SET unread_count_1 = CASE WHEN participant_1 = $1 THEN 0 ELSE unread_count_1 END,
			unread_count_2 = CASE WHEN participant_2 = $1 THEN 0 ELSE unread_count_2 END
		WHERE participant_1 = $1 OR participant_2 = $1
	`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark all as read"})
		return
	}

	c.Status(http.StatusOK)
}

// GetAllConversations returns all conversations in the system (Admin)
func (h *ChatHandler) GetAllConversations(c *gin.Context) {
	townID := c.Query("town_id")
	suburbID := c.Query("suburb_id")
	convType := c.Query("type") // "auction", "shop", "all"

	where := []string{"1=1"}
	args := []interface{}{}
	argNum := 1

	if townID != "" {
		// Filter by town of the auction (if auction-based) or town of the store (if shop-based)
		where = append(where, fmt.Sprintf("(a.town_id = $%d OR s.town_id = $%d)", argNum, argNum))
		args = append(args, townID)
		argNum++
	}

	if suburbID != "" {
		where = append(where, fmt.Sprintf("(a.suburb_id = $%d OR s.suburb_id = $%d)", argNum, argNum))
		args = append(args, suburbID)
		argNum++
	}

	if convType == "auction" {
		where = append(where, "c.auction_id IS NOT NULL")
	} else if convType == "shop" {
		where = append(where, "c.store_id IS NOT NULL")
	}

	query := fmt.Sprintf(`
		SELECT c.id, c.auction_id, c.store_id, c.participant_1, c.participant_2, 
			   c.last_message_preview, c.last_message_at,
			   a.title as auction_title,
			   s.store_name,
			   u1.username, u1.avatar_url, u2.username, u2.avatar_url,
			   COUNT(*) OVER() as total_count
		FROM conversations c
		LEFT JOIN auctions a ON c.auction_id = a.id
		LEFT JOIN stores s ON c.store_id = s.id
		LEFT JOIN users u1 ON c.participant_1 = u1.id
		LEFT JOIN users u2 ON c.participant_2 = u2.id
		WHERE %s
		ORDER BY c.last_message_at DESC NULLS LAST
		LIMIT 100`, strings.Join(where, " AND "))

	rows, err := h.db.Pool.Query(context.Background(), query, args...)

	if err != nil {
		log.Printf("Error fetching all conversations: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch conversations"})
		return
	}
	defer rows.Close()

	var chats []gin.H
	totalCount := 0
	for rows.Next() {
		var id, p1, p2 uuid.UUID
		var auctionID, storeID *uuid.UUID
		var lastMsg, lastMsgAt, auctionTitle, storeName, u1Avatar, u2Avatar *string
		var u1Name, u2Name string

		err := rows.Scan(
			&id, &auctionID, &storeID, &p1, &p2,
			&lastMsg, &lastMsgAt,
			&auctionTitle, &storeName,
			&u1Name, &u1Avatar, &u2Name, &u2Avatar,
			&totalCount,
		)
		if err != nil {
			log.Printf("Error scanning conversation: %v", err)
			continue
		}

		chats = append(chats, gin.H{
			"id":                   id,
			"auction_id":           auctionID,
			"auction_title":        auctionTitle,
			"store_id":             storeID,
			"store_name":           storeName,
			"participant_1_name":   u1Name,
			"participant_1_avatar": u1Avatar,
			"participant_2_name":   u2Name,
			"participant_2_avatar": u2Avatar,
			"last_message":         lastMsg,
			"updated_at":           lastMsgAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"chats": chats,
		"total": totalCount,
	})
}

// GetConversationMessagesAdmin returns all messages in a conversation for Admin
func (h *ChatHandler) GetConversationMessagesAdmin(c *gin.Context) {
	chatID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT m.id, m.sender_id, m.body, m.is_read, m.created_at, u.username
		FROM messages m
		JOIN users u ON m.sender_id = u.id
		WHERE m.conversation_id = $1
		ORDER BY m.created_at ASC
	`, chatID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch messages"})
		return
	}
	defer rows.Close()

	var messages []gin.H
	for rows.Next() {
		var id, senderID uuid.UUID
		var body, username string
		var isRead bool
		var createdAt time.Time
		rows.Scan(&id, &senderID, &body, &isRead, &createdAt, &username)
		messages = append(messages, gin.H{
			"id":         id,
			"sender_id":  senderID,
			"username":   username,
			"body":       body,
			"is_read":    isRead,
			"created_at": createdAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"messages": messages})
}
