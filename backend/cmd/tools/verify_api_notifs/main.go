package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

func main() {
	// 1. Login
	loginURL := "http://localhost:8080/api/auth/login"
	loginPayload := map[string]string{
		"email":    "alice@example.com",
		"password": "password123", // Assuming standard test password, might need adjustment if unknown
	}
	payloadBytes, _ := json.Marshal(loginPayload)

	resp, err := http.Post(loginURL, "application/json", bytes.NewBuffer(payloadBytes))
	if err != nil {
		log.Fatalf("Login failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		log.Fatalf("Login returned %d: %s", resp.StatusCode, string(body))
	}

	var loginResp struct {
		Token string `json:"token"`
	}
	json.NewDecoder(resp.Body).Decode(&loginResp)
	fmt.Println("🔑 Logged in as Alice. Token obtained.")

	// 2. Fetch Notifications
	notifURL := "http://localhost:8080/api/notifications"
	req, _ := http.NewRequest("GET", notifURL, nil)
	req.Header.Set("Authorization", "Bearer "+loginResp.Token)

	client := &http.Client{}
	resp2, err := client.Do(req)
	if err != nil {
		log.Fatalf("Fetch notifications failed: %v", err)
	}
	defer resp2.Body.Close()

	body2, _ := ioutil.ReadAll(resp2.Body)
	// fmt.Println(string(body2))

	var notifResp struct {
		Notifications []map[string]interface{} `json:"notifications"`
	}
	json.Unmarshal(body2, &notifResp)

	fmt.Printf("📋 Found %d notifications via API.\n", len(notifResp.Notifications))
	found := false
	for _, n := range notifResp.Notifications {
		title := n["title"].(string)
		// body might be nil or string
		body := ""
		if n["body"] != nil {
			body = n["body"].(string)
		}

		fmt.Printf("- [%s] %s: %s\n", n["created_at"], title, body)
		if title == "Boost Your Visibility" {
			found = true
		}
	}

	if found {
		fmt.Println("✅ API returns the notification correctly.")
		fmt.Println("👉 Advice: Check mobile app formatting or refresh.")
	} else {
		fmt.Println("❌ API did NOT return the notification.")
	}
}
