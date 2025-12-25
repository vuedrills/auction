# 🏆 Auction Winner Flow - Implementation Plan

**Date**: December 25, 2025  
**Goal**: Complete end-to-end winner selection with notifications, chat, and rating

---

## 📊 CURRENT STATE ANALYSIS

### ✅ What Already Exists:
1. **Backend**:
   - ✅ Auction worker runs every 30 seconds
   - ✅ Worker ends expired auctions (sets status to 'ended')
   - ✅ Notification endpoints (GET, mark read, unread count)
   - ✅ Rating endpoints (`/api/users/:userId/ratings`)
   - ✅ Chat endpoints (conversations, messages)
   - ✅ WebSocket hub for real-time updates

2. **Mobile**:
   - ✅ Chat screens fully implemented (`/lib/screens/chat/chat_screens.dart`)
   - ✅ Rating screen exists (`/lib/screens/rating/rate_user_screen.dart`)
   - ✅ Notification screen exists (`/lib/screens/notification/`)

### ❌ What's MISSING:
1. **Backend**:
   - ❌ Worker does NOT determine winner from highest bid
   - ❌ Worker does NOT create notifications on auction end
   - ❌ Worker does NOT create conversation between winner & seller
   - ❌ No push notification service integration (FCM placeholder needed)

2. **Mobile**:
   - ❌ No notification badge on bottom nav
   - ❌ No real-time notification updates
   - ❌ No direct navigation from "You won!" notification to chat
   - ❌ No push notification handling code

---

## 🎯 IMPLEMENTATION STRATEGY

### **PHASE 1: Backend Winner Logic** ⚙️
**File**: `/backend/internal/worker/auction_worker.go`

**Changes**:
1. Enhance `endExpiredAuctions()` to:
   - Find highest bid for each ended auction
   - Update auction with `winner_id`
   - Create notification for winner: "🎉 You won [Auction Title]!"
   - Create notification for seller: "✅ Your auction ended. Winner: [Name]"
   - Create conversation between winner and seller
   - Send WebSocket updates to both users

**SQL Queries Needed**:
```sql
-- Get highest bidder
SELECT bidder_id, amount FROM bids 
WHERE auction_id = $1 
ORDER BY amount DESC LIMIT 1

-- Update winner
UPDATE auctions SET winner_id = $1 WHERE id = $2

-- Create notifications
INSERT INTO notifications (user_id, type, title, body, related_auction_id)
VALUES ($1, 'auction_won', $2, $3, $4)

-- Create conversation
INSERT INTO conversations (auction_id, participant_1, participant_2)
VALUES ($1, $2, $3) RETURNING id
```

---

### **PHASE 2: Backend Notification Service** 📬
**New File**: `/backend/internal/services/notification_service.go`

**Purpose**: Centralize notification creation logic

**Functions**:
- `SendAuctionWonNotification(winnerID, auctionID, title)`
- `SendAuctionSoldNotification(sellerID, auctionID, winnerName, amount)`
- `SendPushNotification(userID, title, body)` - FCM placeholder

---

### **PHASE 3: Mobile Notification UI** 📱
**Files to Modify**:
1. `/mobile/lib/widgets/navigation/bottom_nav_bar.dart`
   - Add notification badge showing unread count

2. `/mobile/lib/screens/notification/notification_screen.dart`
   - Add tap handler to navigate to chat when tapping "auction_won" notification
   - Add real-time listener for new notifications

3. **New File**: `/mobile/lib/core/services/push_notification_service.dart`
   - FCM initialization (placeholder for local dev)
   - Handle foreground/background notifications
   - Navigate to appropriate screen on tap

---

### **PHASE 4: Testing Scenario** 🧪

**Setup**:
1. Alice creates auction ending in 2 minutes
2. Bob places highest bid
3. Wait for auction to expire (or use backend tool to force)

**Expected Flow**:
1. ✅ Auction status → 'ended'
2. ✅ Winner determined (Bob)
3. ✅ Notification sent to Bob: "🎉 You won [Item]!"
4. ✅ Notification sent to Alice: "✅ Sold to Bob - R[Amount]"
5. ✅ Conversation created between Alice & Bob
6. ✅ Bob taps notification → Opens chat with Alice
7. ✅ Both can message each other
8. ✅ After transaction, both can rate each other

---

## 📋 FILES TO MODIFY

### Backend (4 files):
1. ✏️ `/backend/internal/worker/auction_worker.go` - Add winner logic
2. ✏️ `/backend/internal/services/notification_service.go` - NEW file
3. ✏️ `/backend/internal/services/fcm_service.go` - NEW file (FCM placeholder)
4. ✏️ `/backend/cmd/tools/expire_auction.go` - Testing tool

### Mobile (5 files):
1. ✏️ `/mobile/lib/widgets/navigation/bottom_nav_bar.dart` - Add badge
2. ✏️ `/mobile/lib/screens/notification/notification_screen.dart` - Add navigation
3. ✏️ `/mobile/lib/core/services/push_notification_service.dart` - NEW file
4. ✏️ `/mobile/lib/data/providers/notification_provider.dart` - Real-time updates
5. ✏️ `/mobile/lib/app/router.dart` - Notification deep links

---

## ⚠️ SAFETY RULES

1. **NO breaking changes** to existing working features
2. **Only add** new functionality, don't rewrite working code
3. **Test incrementally** after each phase
4. **Use Alice & Bob** as test users
5. **Keep push notifications** as placeholder (won't test locally)

---

## 🚀 EXECUTION ORDER

1. ✅ Create notification service (backend)
2. ✅ Update auction worker to determine winner
3. ✅ Create testing tool to expire auction manually
4. ✅ Test backend flow with database queries
5. ✅ Add notification badge to mobile
6. ✅ Add tap navigation on notifications
7. ✅ Add push notification service (placeholder)
8. ✅ End-to-end test with Alice & Bob

---

## ✨ SUCCESS CRITERIA

- [ ] Auction expires → Winner selected
- [ ] Notifications sent to both users
- [ ] Notifications appear in mobile app
- [ ] Badge shows unread count
- [ ] Tap notification → Opens chat
- [ ] Real-time messaging works
- [ ] Rating screen accessible after transaction
- [ ] Push notification code in place (FCM placeholder)

---

**Ready to implement!** 🎯
