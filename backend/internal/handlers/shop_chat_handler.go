package handlers

import (
	"context"
	"log"
	"net/http"
	"time"

	"github.com/airmass/backend/internal/database"
	"github.com/airmass/backend/internal/fcm"
	"github.com/airmass/backend/internal/middleware"
	"github.com/airmass/backend/internal/models"
	"github.com/airmass/backend/internal/websocket"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ShopChatHandler struct {
	db         *database.DB
	hub        *websocket.Hub
	fcmService *fcm.FCMService
}

func NewShopChatHandler(db *database.DB, hub *websocket.Hub, fcmService *fcm.FCMService) *ShopChatHandler {
	return &ShopChatHandler{db: db, hub: hub, fcmService: fcmService}
}

// GetShopConversations returns all shop chat conversations for the user
// Includes chats where user is either a store owner or a customer
func (h *ShopChatHandler) GetShopConversations(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT 
			sc.id, sc.store_id, sc.customer_id, sc.product_id,
			sc.last_message_preview, sc.last_message_at, 
			sc.unread_count_store, sc.unread_count_customer, sc.status,
			sc.created_at,
			s.store_name, s.logo_url, s.user_id as store_owner_id,
			COALESCE(NULLIF(cu.full_name, ''), cu.username, 'Unknown') as customer_name, 
			cu.avatar_url as customer_avatar,
			p.title as product_title, p.images as product_images
		FROM shop_conversations sc
		JOIN stores s ON sc.store_id = s.id
		JOIN users cu ON sc.customer_id = cu.id
		LEFT JOIN products p ON sc.product_id = p.id
		WHERE sc.customer_id = $1 OR s.user_id = $1
		ORDER BY sc.last_message_at DESC NULLS LAST
	`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch shop conversations"})
		return
	}
	defer rows.Close()

	var chats []gin.H
	for rows.Next() {
		var id, storeID, customerID uuid.UUID
		var storeOwnerID uuid.UUID
		var productID *uuid.UUID
		var lastMsg *string
		var lastMsgAt *time.Time
		var unreadStore, unreadCustomer int
		var status string
		var createdAt time.Time
		var storeName string
		var storeLogo *string
		var customerName string
		var customerAvatar *string
		var productTitle *string
		var productImages []string

		err := rows.Scan(
			&id, &storeID, &customerID, &productID,
			&lastMsg, &lastMsgAt, &unreadStore, &unreadCustomer, &status,
			&createdAt,
			&storeName, &storeLogo, &storeOwnerID,
			&customerName, &customerAvatar,
			&productTitle, &productImages,
		)
		if err != nil {
			log.Printf("Error scanning shop conversation: %v", err)
			continue
		}

		// Determine if user is store owner or customer
		isStoreOwner := storeOwnerID == userID
		var unread int
		var otherName string
		var otherAvatar *string

		if isStoreOwner {
			unread = unreadStore
			otherName = customerName
			otherAvatar = customerAvatar
		} else {
			unread = unreadCustomer
			otherName = storeName
			otherAvatar = storeLogo
		}

		productImg := ""
		if len(productImages) > 0 {
			productImg = productImages[0]
		}

		var lastMsgObj interface{}
		if lastMsg != nil {
			lastMsgObj = gin.H{
				"content":    lastMsg,
				"created_at": lastMsgAt,
			}
		}

		updatedAt := createdAt
		if lastMsgAt != nil {
			updatedAt = *lastMsgAt
		}

		chats = append(chats, gin.H{
			"id":              id,
			"store_id":        storeID,
			"store_name":      storeName,
			"store_logo":      storeLogo,
			"customer_id":     customerID,
			"customer_name":   customerName,
			"customer_avatar": customerAvatar,
			"product_id":      productID,
			"product_title":   productTitle,
			"product_image":   productImg,
			"is_store_owner":  isStoreOwner,
			"other_name":      otherName,
			"other_avatar":    otherAvatar,
			"last_message":    lastMsgObj,
			"unread_count":    unread,
			"updated_at":      updatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"conversations": chats})
}

// GetShopMessages returns messages for a shop conversation
func (h *ShopChatHandler) GetShopMessages(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	// Verify user is participant
	var storeOwnerID, customerID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(), `
		SELECT s.user_id, sc.customer_id 
		FROM shop_conversations sc 
		JOIN stores s ON sc.store_id = s.id
		WHERE sc.id = $1
	`, conversationID).Scan(&storeOwnerID, &customerID)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Conversation not found"})
		return
	}

	if userID != storeOwnerID && userID != customerID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	rows, err := h.db.Pool.Query(context.Background(), `
		SELECT sm.id, sm.conversation_id, sm.sender_id, sm.content, 
			   sm.message_type, sm.product_id, sm.attachment_url, sm.is_read, sm.created_at,
			   COALESCE(NULLIF(u.full_name, ''), u.username, 'Unknown') as sender_name,
			   u.avatar_url as sender_avatar
		FROM shop_messages sm
		JOIN users u ON sm.sender_id = u.id
		WHERE sm.conversation_id = $1
		ORDER BY sm.created_at DESC
		LIMIT 50
	`, conversationID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch messages"})
		return
	}
	defer rows.Close()

	var messages []gin.H
	for rows.Next() {
		var m models.ShopMessage
		var senderName string
		var senderAvatar *string

		err := rows.Scan(&m.ID, &m.ConversationID, &m.SenderID, &m.Content,
			&m.MessageType, &m.ProductID, &m.AttachmentURL, &m.IsRead, &m.CreatedAt,
			&senderName, &senderAvatar)
		if err != nil {
			continue
		}

		messages = append(messages, gin.H{
			"id":              m.ID,
			"conversation_id": m.ConversationID,
			"sender_id":       m.SenderID,
			"sender_name":     senderName,
			"sender_avatar":   senderAvatar,
			"content":         m.Content,
			"message_type":    m.MessageType,
			"product_id":      m.ProductID,
			"attachment_url":  m.AttachmentURL,
			"is_read":         m.IsRead,
			"created_at":      m.CreatedAt,
		})
	}

	c.JSON(http.StatusOK, gin.H{"messages": messages})
}

// SendShopMessage sends a message in a shop conversation
func (h *ShopChatHandler) SendShopMessage(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	var req struct {
		Content       string  `json:"content" binding:"required"`
		MessageType   string  `json:"message_type"`
		ProductID     *string `json:"product_id"`
		AttachmentURL *string `json:"attachment_url"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.MessageType == "" {
		req.MessageType = "text"
	}

	// Verify user is participant and get other party
	var storeOwnerID, customerID, storeID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(), `
		SELECT s.user_id, sc.customer_id, sc.store_id
		FROM shop_conversations sc 
		JOIN stores s ON sc.store_id = s.id
		WHERE sc.id = $1
	`, conversationID).Scan(&storeOwnerID, &customerID, &storeID)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Conversation not found"})
		return
	}

	if userID != storeOwnerID && userID != customerID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	// Insert message
	var msgID uuid.UUID
	createdAt := time.Now()
	var productID *uuid.UUID
	if req.ProductID != nil {
		pid, _ := uuid.Parse(*req.ProductID)
		productID = &pid
	}

	err = h.db.Pool.QueryRow(context.Background(), `
		INSERT INTO shop_messages (conversation_id, sender_id, content, message_type, product_id, attachment_url, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id
	`, conversationID, userID, req.Content, req.MessageType, productID, req.AttachmentURL, createdAt).Scan(&msgID)

	if err != nil {
		log.Printf("Error inserting shop message: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	// The trigger will update unread counts, but we need to broadcast
	isFromStoreOwner := userID == storeOwnerID
	recipientID := customerID
	if !isFromStoreOwner {
		recipientID = storeOwnerID
	}

	// Broadcast via WebSocket
	msgPayload := gin.H{
		"id":              msgID,
		"conversation_id": conversationID,
		"sender_id":       userID,
		"content":         req.Content,
		"message_type":    req.MessageType,
		"product_id":      productID,
		"attachment_url":  req.AttachmentURL,
		"is_read":         false,
		"created_at":      createdAt,
		"chat_type":       "shop", // Distinguish from auction chats
	}

	h.hub.BroadcastToUser(userID, websocket.MessageTypeShopMessage, gin.H{
		"message": msgPayload,
		"is_read": true, // Sender sees as read
	})
	h.hub.BroadcastToUser(recipientID, websocket.MessageTypeShopMessage, gin.H{
		"message": msgPayload,
		"is_read": false,
	})

	// Send push notification
	go func() {
		var fcmToken *string
		var senderName, storeName string
		h.db.Pool.QueryRow(context.Background(),
			"SELECT fcm_token FROM users WHERE id = $1", recipientID).Scan(&fcmToken)
		h.db.Pool.QueryRow(context.Background(),
			"SELECT COALESCE(NULLIF(full_name, ''), username) FROM users WHERE id = $1", userID).Scan(&senderName)
		h.db.Pool.QueryRow(context.Background(),
			"SELECT store_name FROM stores WHERE id = $1", storeID).Scan(&storeName)

		if fcmToken != nil && *fcmToken != "" {
			preview := req.Content
			if len(preview) > 50 {
				preview = preview[:47] + "..."
			}

			title := senderName
			if isFromStoreOwner {
				title = storeName
			}

			err := h.fcmService.SendShopMessageNotification(*fcmToken, title, preview, conversationID.String())
			if err != nil {
				log.Printf("Failed to send shop message push notification: %v", err)
			}
		}
	}()

	c.JSON(http.StatusOK, gin.H{
		"id":              msgID,
		"conversation_id": conversationID,
		"sender_id":       userID,
		"content":         req.Content,
		"message_type":    req.MessageType,
		"is_read":         false,
		"created_at":      createdAt,
	})
}

// StartShopConversation creates a new shop conversation or returns existing
func (h *ShopChatHandler) StartShopConversation(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	var req struct {
		StoreID   string  `json:"store_id" binding:"required"`
		ProductID *string `json:"product_id"`
		Message   string  `json:"message"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	storeID, err := uuid.Parse(req.StoreID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid store ID"})
		return
	}

	// Check if user is not the store owner (can't chat with self)
	var storeOwnerID uuid.UUID
	var storeName string
	err = h.db.Pool.QueryRow(context.Background(),
		"SELECT user_id, store_name FROM stores WHERE id = $1", storeID).Scan(&storeOwnerID, &storeName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Store not found"})
		return
	}

	if storeOwnerID == userID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "You cannot chat with your own store"})
		return
	}

	// Check for existing conversation
	var conversationID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(), `
		SELECT id FROM shop_conversations 
		WHERE store_id = $1 AND customer_id = $2
	`, storeID, userID).Scan(&conversationID)

	if err != nil {
		// Create new conversation
		var productID *uuid.UUID
		if req.ProductID != nil {
			pid, _ := uuid.Parse(*req.ProductID)
			productID = &pid
		}

		err = h.db.Pool.QueryRow(context.Background(), `
			INSERT INTO shop_conversations (store_id, customer_id, product_id, created_at, updated_at)
			VALUES ($1, $2, $3, NOW(), NOW())
			RETURNING id
		`, storeID, userID, productID).Scan(&conversationID)

		if err != nil {
			log.Printf("Error creating shop conversation: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create conversation"})
			return
		}
	}

	// If initial message provided, send it
	if req.Message != "" {
		h.db.Pool.Exec(context.Background(), `
			INSERT INTO shop_messages (conversation_id, sender_id, content, message_type, created_at)
			VALUES ($1, $2, $3, 'text', NOW())
		`, conversationID, userID, req.Message)
	}

	c.JSON(http.StatusOK, gin.H{
		"conversation_id": conversationID,
		"store_id":        storeID,
		"store_name":      storeName,
	})
}

// MarkShopConversationRead marks all messages as read in a shop conversation
func (h *ShopChatHandler) MarkShopConversationRead(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)
	conversationID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid conversation ID"})
		return
	}

	// Get store owner to determine which unread to reset
	var storeOwnerID, customerID uuid.UUID
	err = h.db.Pool.QueryRow(context.Background(), `
		SELECT s.user_id, sc.customer_id 
		FROM shop_conversations sc 
		JOIN stores s ON sc.store_id = s.id
		WHERE sc.id = $1
	`, conversationID).Scan(&storeOwnerID, &customerID)

	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Conversation not found"})
		return
	}

	if userID == storeOwnerID {
		_, err = h.db.Pool.Exec(context.Background(),
			"UPDATE shop_conversations SET unread_count_store = 0 WHERE id = $1", conversationID)
	} else if userID == customerID {
		_, err = h.db.Pool.Exec(context.Background(),
			"UPDATE shop_conversations SET unread_count_customer = 0 WHERE id = $1", conversationID)
	} else {
		c.JSON(http.StatusForbidden, gin.H{"error": "Not authorized"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark as read"})
		return
	}

	c.Status(http.StatusOK)
}

// GetUnreadShopCount returns total unread shop messages for user
func (h *ShopChatHandler) GetUnreadShopCount(c *gin.Context) {
	userID, _ := middleware.GetUserID(c)

	var count int
	err := h.db.Pool.QueryRow(context.Background(), `
		SELECT COALESCE(
			SUM(
				CASE 
					WHEN s.user_id = $1 THEN sc.unread_count_store 
					ELSE sc.unread_count_customer 
				END
			), 0
		)
		FROM shop_conversations sc
		JOIN stores s ON sc.store_id = s.id
		WHERE sc.customer_id = $1 OR s.user_id = $1
	`, userID).Scan(&count)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get count"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"unread_count": count})
}
