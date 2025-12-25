-- Badge System Schema for Auction App
-- Run this migration to add badge support

-- Badge definitions table
CREATE TABLE IF NOT EXISTS badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    category VARCHAR(50), -- trust, seller, buyer, community, activity
    priority INT DEFAULT 0, -- higher = more important
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- User badges (many-to-many)
CREATE TABLE IF NOT EXISTS user_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP, -- null = permanent
    UNIQUE(user_id, badge_id)
);

-- Verification requests for ID verification
CREATE TABLE IF NOT EXISTS verification_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    id_document_url TEXT NOT NULL,
    selfie_url TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    reviewer_notes TEXT,
    reviewed_at TIMESTAMP,
    reviewed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge_id ON user_badges(badge_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_user_id ON verification_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_status ON verification_requests(status);

-- Seed initial badges
INSERT INTO badges (name, display_name, description, icon, category, priority) VALUES
-- Trust & Verification (highest priority)
('id_verified', 'ID Verified', 'Identity verified with national ID', 'verified_user', 'trust', 100),
('phone_verified', 'Phone Verified', 'Phone number confirmed via SMS', 'phone_android', 'trust', 90),
('email_verified', 'Email Verified', 'Email address confirmed', 'mark_email_read', 'trust', 80),

-- Seller badges
('first_sale', 'First Sale', 'Completed your first auction sale', 'sell', 'seller', 50),
('trusted_seller', 'Trusted Seller', 'Reliable seller with no disputes', 'thumb_up', 'seller', 70),
('super_seller', 'Super Seller', '10+ sales with 4.5+ rating', 'workspace_premium', 'seller', 75),
('power_seller', 'Power Seller', 'Top-tier seller: 50+ sales, 4.8+ rating', 'diamond', 'seller', 85),
('quick_shipper', 'Quick Shipper', 'Consistently fast shipping', 'local_shipping', 'seller', 60),

-- Buyer badges
('first_win', 'First Win', 'Won your first auction', 'emoji_events', 'buyer', 50),
('power_buyer', 'Power Buyer', 'Active buyer with 10+ wins', 'shopping_bag', 'buyer', 65),
('quick_payer', 'Quick Payer', 'Always pays promptly', 'payments', 'buyer', 55),

-- Community badges
('og_member', 'OG Member', 'Early adopter of the platform', 'history', 'community', 40),
('one_year', '1 Year Member', 'Member for over a year', 'cake', 'community', 35),
('five_star', '5 Star Seller', 'Perfect 5.0 rating with 10+ reviews', 'star', 'community', 80),
('top_rated', 'Top Rated', 'Exceptional reputation: 4.9+ rating', 'military_tech', 'community', 82),
('local_legend', 'Local Legend', 'Top 10 seller in your town', 'public', 'community', 75),

-- Activity badges
('active_seller', 'Active Seller', '3+ active auctions at a time', 'storefront', 'activity', 30),
('bid_master', 'Bid Master', 'Placed 100+ bids', 'gavel', 'activity', 40),
('watchlist_pro', 'Watchlist Pro', '20+ items on watchlist', 'visibility', 'activity', 25)
ON CONFLICT (name) DO NOTHING;
