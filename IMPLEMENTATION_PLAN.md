# AirMass - Community Auction App Implementation Plan

## Project Overview
AirMass is a town-first community auction platform that enables local buying and selling through time-limited auctions. The app emphasizes local community connections while also allowing national browsing.

## Core Concept: "Town-First" Auction Model
- Sellers can only create auctions in their registered home town
- Buyers can browse both locally and nationally
- Each category in a town has limited "slots" for active auctions
- Anti-sniping protection extends auctions when last-minute bids are placed

---

## Technology Stack

### Backend (Go)
- **Framework**: Gin
- **Database**: PostgreSQL 15+ with pgx/v5
- **Authentication**: JWT
- **Real-time**: WebSocket (gorilla/websocket)
- **Password Hashing**: bcrypt
- **Image Storage**: Supabase Storage

### Mobile (Flutter)
- **State Management**: Riverpod
- **Navigation**: go_router
- **HTTP Client**: Dio
- **Local Storage**: flutter_secure_storage, shared_preferences
- **Real-time**: web_socket_channel
- **Image Storage**: Supabase Storage

### Image Storage (Supabase)
- **Project**: tribab (pjqchcpnbjxcuvrevaht)
- **Bucket**: auctionimages
- **URL**: https://pjqchcpnbjxcuvrevaht.supabase.co

---

## Project Structure

### Backend Structure
```
backend/
├── cmd/server/main.go           # Entry point
├── internal/
│   ├── config/config.go         # Configuration
│   ├── database/
│   │   ├── postgres.go          # DB connection
│   │   └── migrations/          # SQL migrations
│   ├── handlers/                # HTTP handlers
│   │   ├── auth_handler.go
│   │   ├── town_handler.go
│   │   ├── category_handler.go
│   │   └── auction_handler.go
│   ├── middleware/              # Middleware
│   │   ├── auth.go
│   │   └── cors.go
│   ├── models/                  # Data models
│   ├── router/router.go         # Routes
│   └── websocket/               # Real-time
│       ├── hub.go
│       └── client.go
├── pkg/
│   ├── jwt/jwt.go               # JWT utilities
│   └── password/password.go     # Password utilities
├── go.mod
├── go.sum
└── .env.example
```

### Mobile Structure
```
mobile/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart             # Main app widget
│   │   ├── router.dart          # Navigation
│   │   └── theme.dart           # Design system
│   ├── core/
│   │   ├── config/api_config.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart
│   │   │   └── websocket_client.dart
│   │   └── services/
│   │       └── storage_service.dart
│   ├── data/models/             # Data models
│   │   ├── user.dart
│   │   ├── auction.dart
│   │   ├── category.dart
│   │   └── bid.dart
│   ├── screens/                 # UI screens
│   │   ├── splash/
│   │   ├── onboarding/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── auction/
│   │   ├── category/
│   │   ├── profile/
│   │   ├── notification/
│   │   └── settings/
│   └── widgets/                 # Reusable widgets
│       ├── common/
│       └── navigation/
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
└── pubspec.yaml
```

---

## Implemented Features

### Backend ✅
- [x] Project structure and configuration
- [x] PostgreSQL database connection
- [x] Database migrations (users, towns, categories, auctions, bids, etc.)
- [x] JWT authentication
- [x] Authentication endpoints (register, login, refresh)
- [x] User profile endpoints
- [x] Towns and suburbs endpoints
- [x] Categories and slots endpoints
- [x] Auctions CRUD endpoints
- [x] Bidding endpoints with anti-sniping
- [x] WebSocket hub for real-time updates
- [x] CORS middleware

### Mobile ✅
- [x] Project structure and dependencies
- [x] Design system (theme, colors, typography)
- [x] Navigation with go_router
- [x] Splash screen with animations
- [x] Onboarding carousel (4 slides)
- [x] Login screen
- [x] Registration screen with town selection
- [x] Home screen with bottom navigation
- [x] Auction detail screen
- [x] Create auction multi-step form
- [x] Category browser
- [x] Profile screen
- [x] Notification inbox
- [x] Settings screen
- [x] Dio HTTP client with auth interceptor
- [x] WebSocket client for real-time updates
- [x] Secure storage for tokens

---

## API Endpoints

### Authentication
```
POST /api/auth/register    - Register new user
POST /api/auth/login       - Login
POST /api/auth/refresh     - Refresh token
```

### Users
```
GET  /api/users/me         - Get current user
PUT  /api/users/me         - Update profile
PUT  /api/users/me/town    - Change home town (30-day limit)
```

### Towns
```
GET  /api/towns            - List all towns
GET  /api/towns/:id        - Get town with suburbs
GET  /api/towns/:id/suburbs - Get suburbs for town
```

### Categories
```
GET  /api/categories       - List categories
GET  /api/categories/:id   - Get category
GET  /api/categories/:id/slots/:townId - Get slot availability
```

### Auctions
```
GET  /api/auctions         - List auctions (with filters)
GET  /api/auctions/my-town - Auctions in user's town
GET  /api/auctions/national - National auctions
GET  /api/auctions/:id     - Get auction details
POST /api/auctions         - Create auction
GET  /api/auctions/:id/bids - Get bid history
POST /api/auctions/:id/bids - Place bid
```

### WebSocket
```
WS  /ws?token=<jwt>        - Connect for real-time updates
```

#### WebSocket Message Types

**Client → Server:**
```json
// Subscribe to auction updates
{"type": "subscribe", "auction_id": "<uuid>"}

// Unsubscribe from auction
{"type": "unsubscribe", "auction_id": "<uuid>"}

// Ping/keepalive
{"type": "ping"}
```

**Server → Client:**
```json
// New bid placed
{"type": "bid:new", "auction_id": "<uuid>", "data": {
  "bid_id": "<uuid>",
  "bidder_id": "<uuid>",
  "bidder_name": "John D.",
  "amount": 125.00,
  "total_bids": 12,
  "time_remaining": "2d 14h"
}}

// User has been outbid
{"type": "bid:outbid", "user_id": "<uuid>", "data": {...}}

// Auction ending soon (< 5 min)
{"type": "auction:ending", "auction_id": "<uuid>"}

// Auction has ended
{"type": "auction:ended", "auction_id": "<uuid>", "data": {
  "winner_id": "<uuid>",
  "final_price": 150.00
}}

// Pong response
{"type": "pong"}
```

---

## Design System

### Colors
- **Primary**: #EE456B (Coral Pink)
- **Secondary**: #FF8322 (Carrot Orange)
- **Success**: #22C55E
- **Warning**: #F59E0B
- **Error**: #EF4444
- **Info**: #3B82F6

### Typography
- **Font Family**: Plus Jakarta Sans
- **Display**: 36px, 800 weight
- **Headline**: 24px, 700 weight
- **Title**: 16px, 700 weight
- **Body**: 14px, 400 weight
- **Label**: 12px, 600 weight

---

---

## 🔥 CRITICAL: Tiered Bid Increment System (Implemented)

**Users cannot enter arbitrary bid amounts.** The system determines the ONLY valid next bid based on price:

| Current Price | Bid Increment |
|---------------|---------------|
| $0 - $4.99 | +$1 |
| $5 - $19.99 | +$2 |
| $20 - $99.99 | +$5 |
| $100 - $499.99 | +$10 |
| $500+ | +$25 |

### Key Implementation Details:
- **Server-side enforcement**: Client amounts are ignored; server recalculates
- **Transactional bidding**: Uses database transactions with row locking
- **Race condition prevention**: `SELECT ... FOR UPDATE` locks auction during bid
- **Mobile UI**: Shows "Bid +$X" button (no free-form input)
- **Real-time**: WebSocket broadcasts include `next_bid_amount` and `next_increment`

---

## 🤖 Auto-Bid System (Implemented)

Users can set a maximum bid and the system automatically bids on their behalf:

- **Max Amount**: User sets the maximum they're willing to pay
- **Tiered Increments**: Uses the same tiered system for all auto-bids
- **Transactional Safety**: All auto-bids use row locking to prevent races
- **Auto-Deactivation**: Bids stop when max reached, auction ends, or user cancels

### API Endpoints:
- `POST /api/auctions/:id/auto-bid` - Set auto-bid
- `DELETE /api/auctions/:id/auto-bid` - Cancel auto-bid
- `GET /api/auto-bids` - List user's auto-bids

---

## 🛡️ Trust & Safety Features (Implemented)

### User Reputation
- **Badge Levels**: Bronze / Silver / Gold (auto-calculated)
- **Star Rating**: 1-5 with detailed breakdowns
- **Completion Rate**: % without disputes
- **Fast Responder**: Average response < 30 mins
- **Member Since**: Account age display

### Badge Criteria:
| Badge | Sales | Rating | Completion |
|-------|-------|--------|------------|
| 🥉 Bronze | 5+ | 4.0+ | 90%+ |
| 🥈 Silver | 20+ | 4.5+ | 95%+ |
| 🥇 Gold | 50+ | 4.8+ | 98%+ |

### Fraud Detection
- Self-bidding detection
- Rapid bid spikes
- IP/device reuse tracking
- Cancellation patterns
- Shill bid probability scoring
- **Risk levels**: low, medium, high, critical
- **Auto-flag at score >= 70**

---

## 🔍 Saved Searches & Alerts (Implemented)

Users can save searches and get notified when matching auctions appear:

- **Filters**: Category, town, price range, keywords, condition
- **Notifications**: Email and/or push
- **Alerts**: new_match, price_drop
- **Limit**: 10 saved searches per user

### API Endpoints:
- `POST /api/saved-searches` - Create saved search
- `GET /api/saved-searches` - List user's searches
- `DELETE /api/saved-searches/:id` - Delete search

---

## 💎 Promoted Auctions (Implemented)

Sellers can pay to boost their auction visibility:

### Promotion Types:
| Type | Duration | Price | Boost |
|------|----------|-------|-------|
| Featured | 24h-7d | $1.99-$9.99 | 1.5x |
| Boosted | 24h | $0.99 | 1.3x |
| Pinned | 24h | $2.99 | 2.0x |
| Highlighted | 48h | $1.49 | 1.2x |

### Features:
- Time-limited boosts
- Impression/click tracking
- Town-specific pricing (optional)
- Featured ribbon display

---

## 🏆 Town Community Features (Implemented)

### Town Leaderboards:
- **Top Sellers**: By completed sales
- **Highest Rated**: By user rating
- **Most Active**: By bids + listings

### Periods:
- Weekly
- Monthly
- All-time

### Town Stats:
- Active auctions
- Total users
- Active sellers
- Total sales value
- Average auction price
- Top category

---

## Database Migrations

Run migrations in order:
1. `001_create_users.sql`
2. `002_create_towns.sql`
3. `003_create_categories.sql`
4. `004_create_auctions.sql`
5. `005_create_bids.sql`
6. `006_create_waiting_list.sql`
7. `007_create_notifications.sql`
8. `008_create_messages.sql`
9. `009_tiered_bidding.sql` - Tiered increments, initial trust fields
10. `010_complete_features.sql` - **NEW: Auto-bid, saved searches, promotions, fraud, leaderboards**

---

## API Endpoints Summary (New)

### Auto-Bid
```
POST   /api/auctions/:id/auto-bid    - Set auto-bid
DELETE /api/auctions/:id/auto-bid    - Cancel auto-bid
GET    /api/auto-bids                - List my auto-bids
```

### Saved Searches
```
POST   /api/saved-searches           - Create saved search
GET    /api/saved-searches           - List my searches
DELETE /api/saved-searches/:id       - Delete search
```

### Promotions
```
GET    /api/promotions/pricing       - Get pricing options
POST   /api/auctions/:id/promote     - Promote auction
```

### Reputation
```
GET    /api/users/:userId/reputation - Get reputation
GET    /api/users/:userId/ratings    - Get ratings
POST   /api/users/:userId/ratings    - Rate user
```

### Town Community
```
GET    /api/towns/:townId/leaderboard   - Get leaderboard
GET    /api/towns/:townId/stats         - Get town stats
GET    /api/towns/:townId/top-sellers   - Get top sellers
```

---

## Next Steps

### ✅ Completed (This Session)
- [x] Tiered bid increment system (backend + mobile)
- [x] Auto-bid system with transactional safety
- [x] Saved searches with notification preferences
- [x] Promoted auctions with pricing tiers
- [x] User reputation with badge levels
- [x] User ratings system
- [x] Fraud detection with behavior scoring
- [x] Town leaderboards (top sellers, highest rated, most active)
- [x] Town stats aggregation
- [x] Mobile UI widgets for reputation/badges

### High Priority (Remaining)
1. [ ] Run migrations `009_tiered_bidding.sql` and `010_complete_features.sql`
2. [ ] Add push notifications (FCM) for search alerts
3. [ ] Integrate payment gateway for promotions
4. [ ] Admin dashboard for fraud review

### Medium Priority
5. [ ] Slot pricing / queue skip purchases
6. [ ] Messaging improvements
7. [ ] Email notification templates
8. [ ] Performance optimization

### Low Priority
9. [ ] Analytics dashboard
10. [ ] Localization
11. [ ] Comprehensive test suite

---

## Running the App

### Backend
```bash
cd backend
cp .env.example .env
# Edit .env with your database credentials
go mod download
go run cmd/server/main.go
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

