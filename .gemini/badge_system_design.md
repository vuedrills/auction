# Badge System Design for Auction App

## Overview
A comprehensive badge system to build trust, encourage engagement, and reward users.

## Badge Categories

### 1. Trust & Verification Badges
| Badge | Icon | Description | How to Earn |
|-------|------|-------------|-------------|
| **ID Verified** | `verified_user` | User has verified their identity | Submit valid national ID + selfie |
| **Phone Verified** | `phone_android` | Phone number confirmed | Verify via SMS OTP |
| **Email Verified** | `mark_email_read` | Email address confirmed | Click verification link |

### 2. Seller Badges
| Badge | Icon | Description | How to Earn |
|-------|------|-------------|-------------|
| **First Sale** | `sell` | Completed first auction | Complete 1 sale |
| **Super Seller** | `workspace_premium` | Consistent high-quality seller | 10+ sales with 4.5+ rating |
| **Power Seller** | `diamond` | Top-tier seller | 50+ sales, 4.8+ rating |
| **Trusted Seller** | `thumb_up` | Reliable seller | 5+ sales, no disputes |
| **Quick Shipper** | `local_shipping` | Fast delivery | Average shipping <24 hours |

### 3. Buyer Badges
| Badge | Icon | Description | How to Earn |
|-------|------|-------------|-------------|
| **First Win** | `emoji_events` | Won first auction | Win 1 auction |
| **Power Buyer** | `shopping_bag` | Active buyer | 10+ auction wins |
| **Quick Payer** | `payments` | Prompt payment | Pay within 24 hours consistently |

### 4. Community Badges
| Badge | Icon | Description | How to Earn |
|-------|------|-------------|-------------|
| **OG Member** | `history` | Early adopter | Joined during first 3 months |
| **1 Year Member** | `cake` | Anniversary | Member for 1 year |
| **5 Star Seller** | `star` | Perfect rating | Maintain 5.0 rating (10+ reviews) |
| **Top Rated** | `military_tech` | Exceptional reputation | 4.9+ rating, 50+ reviews |
| **Local Legend** | `public` | Popular in their town | Top 10 seller in town |

### 5. Activity Badges
| Badge | Icon | Description | How to Earn |
|-------|------|-------------|-------------|
| **Active Seller** | `storefront` | Regularly posts auctions | 3+ active auctions |
| **Bid Master** | `gavel` | Frequent bidder | 100+ bids placed |
| **Watchlist Pro** | `visibility` | Actively watches | 20+ items on watchlist |

## Database Schema

```sql
-- Badge definitions table
CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    category VARCHAR(50), -- trust, seller, buyer, community, activity
    priority INT DEFAULT 0, -- for display ordering
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- User badges (many-to-many)
CREATE TABLE user_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    badge_id UUID REFERENCES badges(id),
    earned_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP, -- null = permanent
    UNIQUE(user_id, badge_id)
);

-- Verification requests for ID verification
CREATE TABLE verification_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    id_document_url TEXT NOT NULL,
    selfie_url TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    reviewer_notes TEXT,
    reviewed_at TIMESTAMP,
    reviewed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);
```

## API Endpoints

### Badges
- `GET /api/badges` - List all available badges
- `GET /api/users/:userId/badges` - Get user's badges
- `POST /api/users/me/verification` - Submit ID verification request

### Admin (Future)
- `GET /api/admin/verification-requests` - List pending verifications
- `PUT /api/admin/verification-requests/:id` - Approve/reject verification

## Priority Badges to Display
1. ID Verified (highest trust signal)
2. Trusted Seller / Super Seller
3. Top Rated
4. 5 Star Seller
5. Power Seller
6. Power Buyer

## Implementation Phases

### Phase 1: Foundation
- [ ] Create database tables
- [ ] Create Badge model
- [ ] Seed initial badges
- [ ] GET /api/badges endpoint
- [ ] GET /api/users/:userId/badges endpoint
- [ ] Display badges on user profile

### Phase 2: ID Verification
- [ ] Verification request model
- [ ] Supabase bucket for verification documents
- [ ] POST /api/users/me/verification endpoint
- [ ] Verification request screen in mobile app
- [ ] Admin panel to review requests

### Phase 3: Auto-Earned Badges
- [ ] Background job to evaluate and award badges
- [ ] First Sale, First Win auto-award
- [ ] Rating-based badges
- [ ] Activity-based badges

### Phase 4: Advanced Features
- [ ] Badge notifications
- [ ] Badge showcase on profile
- [ ] Badge filters in search
