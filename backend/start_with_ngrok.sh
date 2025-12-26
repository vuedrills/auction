#!/bin/bash
# Start backend with ngrok and notification support

# Validation
if [ -z "$1" ]; then
    echo "Usage: ./start_with_ngrok.sh <YOUR_NGROK_URL>"
    echo "Example: ./start_with_ngrok.sh https://a1b2-c3d4.ngrok-free.app"
    exit 1
fi

export PUBLIC_URL="$1"

# Resend Email Service
export RESEND_API_KEY="re_FjXQHJxk_HkdQnVSx4evtEUuyfJi1ZAUx"
export FROM_EMAIL="noreply@trabab.com"
export FROM_NAME="Trabab"

# Firebase (FCM)
export FIREBASE_SERVICE_ACCOUNT_PATH="./servicekey.json"

echo "🚀 Starting backend with Public URL: $PUBLIC_URL"
echo "📧 Email links will point to this URL"

go run cmd/server/main.go
