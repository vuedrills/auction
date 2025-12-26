package fcm

import (
	"context"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/airmass/backend/internal/config"
	"google.golang.org/api/option"
)

// FCMService handles sending push notifications via Firebase Cloud Messaging
type FCMService struct {
	client *messaging.Client
}

// NewFCMService creates a new FCM service
func NewFCMService(cfg *config.Config) (*FCMService, error) {
	if cfg.FirebaseServiceAccountPath == "" {
		log.Println("⚠️ Firebase service account not configured, push notifications disabled")
		return &FCMService{}, nil
	}

	opt := option.WithCredentialsFile(cfg.FirebaseServiceAccountPath)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return nil, fmt.Errorf("error initializing firebase app: %v", err)
	}

	client, err := app.Messaging(context.Background())
	if err != nil {
		return nil, fmt.Errorf("error getting messaging client: %v", err)
	}

	log.Println("🔔 Firebase Cloud Messaging initialized")
	return &FCMService{client: client}, nil
}

// SendToDevice sends a push notification to a specific device
func (s *FCMService) SendToDevice(token, title, body string, data map[string]string) error {
	if s.client == nil {
		log.Println("⚠️ FCM client not initialized, skipping push notification")
		return nil
	}

	message := &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Icon:  "ic_notification",
				Color: "#EE456B",
				Sound: "default",
			},
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound:            "default",
					ContentAvailable: true,
				},
			},
		},
	}

	response, err := s.client.Send(context.Background(), message)
	if err != nil {
		return fmt.Errorf("error sending message: %v", err)
	}

	log.Printf("🔔 Push notification sent: %s", response)
	return nil
}

// SendToMultipleDevices sends push notification to multiple devices
func (s *FCMService) SendToMultipleDevices(tokens []string, title, body string, data map[string]string) error {
	if s.client == nil || len(tokens) == 0 {
		return nil
	}

	message := &messaging.MulticastMessage{
		Tokens: tokens,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Icon:  "ic_notification",
				Color: "#EE456B",
				Sound: "default",
			},
		},
	}

	response, err := s.client.SendEachForMulticast(context.Background(), message)
	if err != nil {
		return fmt.Errorf("error sending multicast: %v", err)
	}

	log.Printf("🔔 Multicast sent: %d success, %d failure", response.SuccessCount, response.FailureCount)
	return nil
}

// SendBidNotification sends a notification when outbid
func (s *FCMService) SendBidNotification(token, auctionTitle string, newPrice float64, auctionId string) error {
	return s.SendToDevice(token,
		"⚡ You've been outbid!",
		fmt.Sprintf("Someone placed a higher bid on %s - $%.2f", auctionTitle, newPrice),
		map[string]string{
			"type":       "outbid",
			"auction_id": auctionId,
			"route":      "/auction/" + auctionId,
		},
	)
}

// SendAuctionWonNotification sends a notification when auction is won
func (s *FCMService) SendAuctionWonNotification(token, auctionTitle string, finalPrice float64, auctionId string) error {
	return s.SendToDevice(token,
		"🏆 Congratulations, You Won!",
		fmt.Sprintf("You won %s for $%.2f", auctionTitle, finalPrice),
		map[string]string{
			"type":       "auction_won",
			"auction_id": auctionId,
			"route":      "/auction/" + auctionId,
		},
	)
}

// SendAuctionSoldNotification sends a notification when auction sells
func (s *FCMService) SendAuctionSoldNotification(token, auctionTitle string, finalPrice float64, auctionId string) error {
	return s.SendToDevice(token,
		"💰 Your Auction Sold!",
		fmt.Sprintf("%s sold for $%.2f", auctionTitle, finalPrice),
		map[string]string{
			"type":       "auction_sold",
			"auction_id": auctionId,
			"route":      "/auction/" + auctionId,
		},
	)
}

// SendNewMessageNotification sends a notification for new messages
func (s *FCMService) SendNewMessageNotification(token, senderName, messagePreview, chatId string) error {
	return s.SendToDevice(token,
		fmt.Sprintf("💬 Message from %s", senderName),
		messagePreview,
		map[string]string{
			"type":    "message",
			"chat_id": chatId,
			"route":   "/chats/" + chatId,
		},
	)
}

// SendAuctionEndingNotification sends a notification when auction is about to end
func (s *FCMService) SendAuctionEndingNotification(token, auctionTitle, timeLeft, auctionId string) error {
	return s.SendToDevice(token,
		"⏰ Auction Ending Soon!",
		fmt.Sprintf("%s ends in %s", auctionTitle, timeLeft),
		map[string]string{
			"type":       "auction_ending",
			"auction_id": auctionId,
			"route":      "/auction/" + auctionId,
		},
	)
}

// SubscribeToTopic subscribes tokens to a topic
func (s *FCMService) SubscribeToTopic(tokens []string, topic string) error {
	if s.client == nil || len(tokens) == 0 {
		return nil
	}

	_, err := s.client.SubscribeToTopic(context.Background(), tokens, topic)
	return err
}

// UnsubscribeFromTopic unsubscribes tokens from a topic
func (s *FCMService) UnsubscribeFromTopic(tokens []string, topic string) error {
	if s.client == nil || len(tokens) == 0 {
		return nil
	}

	_, err := s.client.UnsubscribeFromTopic(context.Background(), tokens, topic)
	return err
}

// SendToTopic sends a notification to all subscribers of a topic
func (s *FCMService) SendToTopic(topic, title, body string, data map[string]string) error {
	if s.client == nil {
		return nil
	}

	message := &messaging.Message{
		Topic: topic,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
	}

	response, err := s.client.Send(context.Background(), message)
	if err != nil {
		return fmt.Errorf("error sending to topic: %v", err)
	}

	log.Printf("🔔 Topic notification sent: %s", response)
	return nil
}
