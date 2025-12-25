package websocket

import (
	"encoding/json"
	"log"
	"sync"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

// MessageType represents WebSocket message types
type MessageType string

const (
	// Client -> Server
	MessageTypeSubscribe   MessageType = "subscribe"
	MessageTypeUnsubscribe MessageType = "unsubscribe"
	MessageTypePing        MessageType = "ping"

	// Server -> Client
	MessageTypeBidNew        MessageType = "bid:new"
	MessageTypeBidOutbid     MessageType = "bid:outbid"
	MessageTypeAuctionEnding MessageType = "auction:ending"
	MessageTypeAuctionEnded  MessageType = "auction:ended"
	MessageTypeAuctionWon    MessageType = "auction:won"
	MessageTypeAuctionSold   MessageType = "auction:sold"
	MessageTypeAuctionUpdate MessageType = "auction:update"
	MessageTypeNotification  MessageType = "notification:new"
	MessageTypeMessage       MessageType = "message:new"
	MessageTypeError         MessageType = "error"
	MessageTypePong          MessageType = "pong"
)

// Message represents a WebSocket message
type Message struct {
	Type      MessageType     `json:"type"`
	AuctionID *uuid.UUID      `json:"auction_id,omitempty"`
	UserID    *uuid.UUID      `json:"user_id,omitempty"`
	Data      json.RawMessage `json:"data,omitempty"`
}

// Client represents a WebSocket client
type Client struct {
	ID     uuid.UUID
	UserID *uuid.UUID
	Conn   *websocket.Conn
	Send   chan []byte
	Hub    *Hub
	Rooms  map[string]bool
	mu     sync.Mutex
}

// Hub manages WebSocket connections
type Hub struct {
	// Registered clients
	clients map[*Client]bool

	// Clients by user ID for direct messaging
	userClients map[uuid.UUID][]*Client

	// Auction room subscriptions
	auctionRooms map[uuid.UUID]map[*Client]bool

	// Town room subscriptions
	townRooms map[uuid.UUID]map[*Client]bool

	// Channels for operations
	register   chan *Client
	unregister chan *Client
	broadcast  chan *Message

	mu sync.RWMutex
}

// NewHub creates a new WebSocket hub
func NewHub() *Hub {
	return &Hub{
		clients:      make(map[*Client]bool),
		userClients:  make(map[uuid.UUID][]*Client),
		auctionRooms: make(map[uuid.UUID]map[*Client]bool),
		townRooms:    make(map[uuid.UUID]map[*Client]bool),
		register:     make(chan *Client),
		unregister:   make(chan *Client),
		broadcast:    make(chan *Message),
	}
}

// Run starts the hub's main loop
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.registerClient(client)
		case client := <-h.unregister:
			h.unregisterClient(client)
		case message := <-h.broadcast:
			h.handleBroadcast(message)
		}
	}
}

func (h *Hub) registerClient(client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	h.clients[client] = true

	if client.UserID != nil {
		h.userClients[*client.UserID] = append(h.userClients[*client.UserID], client)
	}

	log.Printf("Client registered: %s (User: %v)", client.ID, client.UserID)
}

func (h *Hub) unregisterClient(client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if _, ok := h.clients[client]; ok {
		delete(h.clients, client)
		close(client.Send)

		// Remove from user clients
		if client.UserID != nil {
			clients := h.userClients[*client.UserID]
			for i, c := range clients {
				if c == client {
					h.userClients[*client.UserID] = append(clients[:i], clients[i+1:]...)
					break
				}
			}
		}

		// Remove from all rooms
		for auctionID, room := range h.auctionRooms {
			delete(room, client)
			if len(room) == 0 {
				delete(h.auctionRooms, auctionID)
			}
		}

		for townID, room := range h.townRooms {
			delete(room, client)
			if len(room) == 0 {
				delete(h.townRooms, townID)
			}
		}

		log.Printf("Client unregistered: %s", client.ID)
	}
}

func (h *Hub) handleBroadcast(message *Message) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	data, err := json.Marshal(message)
	if err != nil {
		log.Printf("Error marshaling message: %v", err)
		return
	}

	// Broadcast to specific auction room
	if message.AuctionID != nil {
		if room, ok := h.auctionRooms[*message.AuctionID]; ok {
			for client := range room {
				select {
				case client.Send <- data:
				default:
					close(client.Send)
					delete(room, client)
				}
			}
		}
		return
	}

	// Broadcast to specific user
	if message.UserID != nil {
		if clients, ok := h.userClients[*message.UserID]; ok {
			for _, client := range clients {
				select {
				case client.Send <- data:
				default:
				}
			}
		}
		return
	}

	// Broadcast to all
	for client := range h.clients {
		select {
		case client.Send <- data:
		default:
			close(client.Send)
			delete(h.clients, client)
		}
	}
}

// SubscribeToAuction subscribes a client to an auction room
func (h *Hub) SubscribeToAuction(client *Client, auctionID uuid.UUID) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if _, ok := h.auctionRooms[auctionID]; !ok {
		h.auctionRooms[auctionID] = make(map[*Client]bool)
	}
	h.auctionRooms[auctionID][client] = true

	client.mu.Lock()
	client.Rooms["auction:"+auctionID.String()] = true
	client.mu.Unlock()

	log.Printf("Client %s subscribed to auction %s", client.ID, auctionID)
}

// UnsubscribeFromAuction unsubscribes a client from an auction room
func (h *Hub) UnsubscribeFromAuction(client *Client, auctionID uuid.UUID) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if room, ok := h.auctionRooms[auctionID]; ok {
		delete(room, client)
		if len(room) == 0 {
			delete(h.auctionRooms, auctionID)
		}
	}

	client.mu.Lock()
	delete(client.Rooms, "auction:"+auctionID.String())
	client.mu.Unlock()
}

// SubscribeToTown subscribes a client to a town room
func (h *Hub) SubscribeToTown(client *Client, townID uuid.UUID) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if _, ok := h.townRooms[townID]; !ok {
		h.townRooms[townID] = make(map[*Client]bool)
	}
	h.townRooms[townID][client] = true

	client.mu.Lock()
	client.Rooms["town:"+townID.String()] = true
	client.mu.Unlock()
}

// BroadcastToAuction sends a message to all clients subscribed to an auction
func (h *Hub) BroadcastToAuction(auctionID uuid.UUID, msgType MessageType, data interface{}) {
	jsonData, err := json.Marshal(data)
	if err != nil {
		log.Printf("Error marshaling broadcast data: %v", err)
		return
	}

	h.broadcast <- &Message{
		Type:      msgType,
		AuctionID: &auctionID,
		Data:      jsonData,
	}
}

// BroadcastToUser sends a message to a specific user
func (h *Hub) BroadcastToUser(userID uuid.UUID, msgType MessageType, data interface{}) {
	jsonData, err := json.Marshal(data)
	if err != nil {
		log.Printf("Error marshaling broadcast data: %v", err)
		return
	}

	h.broadcast <- &Message{
		Type:   msgType,
		UserID: &userID,
		Data:   jsonData,
	}
}

// BroadcastToTown sends a message to all clients subscribed to a town
func (h *Hub) BroadcastToTown(townID uuid.UUID, msgType MessageType, data interface{}) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	jsonData, err := json.Marshal(data)
	if err != nil {
		log.Printf("Error marshaling broadcast data: %v", err)
		return
	}

	message := &Message{
		Type: msgType,
		Data: jsonData,
	}

	if room, ok := h.townRooms[townID]; ok {
		msgBytes, _ := json.Marshal(message)
		for client := range room {
			select {
			case client.Send <- msgBytes:
			default:
			}
		}
	}
}

// Register adds a client to the hub
func (h *Hub) Register(client *Client) {
	h.register <- client
}

// Unregister removes a client from the hub
func (h *Hub) Unregister(client *Client) {
	h.unregister <- client
}
