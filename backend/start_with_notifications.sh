#!/bin/bash
# Add Firebase and Resend configuration

# Resend Email Service
export RESEND_API_KEY="re_FjXQHJxk_HkdQnVSx4evtEUuyfJi1ZAUx"
export FROM_EMAIL="noreply@trabab.com"
export FROM_NAME="Trabab"

# Firebase Push Notifications (path to service account JSON)
export FIREBASE_SERVICE_ACCOUNT_PATH="./servicekey.json"

# Start the server
go run cmd/server/main.go
