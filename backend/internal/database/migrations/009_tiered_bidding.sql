-- Bid increment tiers configuration table
-- This allows dynamic configuration of bid increments based on price ranges
CREATE TABLE IF NOT EXISTS bid_increment_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    min_price DECIMAL(10,2) NOT NULL,
    max_price DECIMAL(10,2),  -- NULL means no upper limit
    increment DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert default tier configuration
INSERT INTO bid_increment_tiers (min_price, max_price, increment) VALUES
    (0.00, 4.99, 1.00),      -- $0 - $4.99 → +$1
    (5.00, 19.99, 2.00),     -- $5 - $19.99 → +$2
    (20.00, 99.99, 5.00),    -- $20 - $99.99 → +$5
    (100.00, 499.99, 10.00), -- $100 - $499.99 → +$10
    (500.00, NULL, 25.00)    -- $500+ → +$25
ON CONFLICT DO NOTHING;

-- Create index for efficient tier lookup
CREATE INDEX IF NOT EXISTS idx_bid_increment_tiers_active ON bid_increment_tiers(is_active);
CREATE INDEX IF NOT EXISTS idx_bid_increment_tiers_range ON bid_increment_tiers(min_price, max_price);

-- Function to calculate the correct bid increment for a given price
CREATE OR REPLACE FUNCTION get_bid_increment(current_price DECIMAL(10,2))
RETURNS DECIMAL(10,2) AS $$
DECLARE
    increment DECIMAL(10,2);
BEGIN
    SELECT t.increment INTO increment
    FROM bid_increment_tiers t
    WHERE t.is_active = TRUE
    AND current_price >= t.min_price
    AND (t.max_price IS NULL OR current_price <= t.max_price)
    ORDER BY t.min_price DESC
    LIMIT 1;
    
    -- Default to $1 if no tier found
    RETURN COALESCE(increment, 1.00);
END;
$$ LANGUAGE plpgsql;

-- Function to get the exact next valid bid amount
CREATE OR REPLACE FUNCTION get_next_bid_amount(auction_id_param UUID)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    current DECIMAL(10,2);
    starting DECIMAL(10,2);
    increment DECIMAL(10,2);
BEGIN
    SELECT COALESCE(current_price, starting_price), starting_price
    INTO current, starting
    FROM auctions
    WHERE id = auction_id_param;
    
    -- If no current price, use starting price
    IF current IS NULL THEN
        current := starting;
    END IF;
    
    -- Get the tier-based increment
    increment := get_bid_increment(current);
    
    RETURN current + increment;
END;
$$ LANGUAGE plpgsql;

-- Update the update_auction_on_bid trigger to also update the bid_increment field
CREATE OR REPLACE FUNCTION update_auction_on_bid_v2()
RETURNS TRIGGER AS $$
DECLARE
    new_increment DECIMAL(10,2);
BEGIN
    -- Calculate new dynamic increment based on the new price
    new_increment := get_bid_increment(NEW.amount);
    
    -- Update auction current price, total bids, and dynamic increment
    UPDATE auctions 
    SET current_price = NEW.amount,
        total_bids = total_bids + 1,
        bid_increment = new_increment,
        updated_at = NOW()
    WHERE id = NEW.auction_id;
    
    -- Mark previous winning bid as not winning
    UPDATE bids 
    SET is_winning = FALSE 
    WHERE auction_id = NEW.auction_id 
    AND id != NEW.id 
    AND is_winning = TRUE;
    
    -- Mark new bid as winning
    NEW.is_winning = TRUE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop old trigger and create new one
DROP TRIGGER IF EXISTS trigger_update_auction_on_bid ON bids;
CREATE TRIGGER trigger_update_auction_on_bid
    BEFORE INSERT ON bids
    FOR EACH ROW
    EXECUTE FUNCTION update_auction_on_bid_v2();

-- Feature flags table for town-specific feature enablement
CREATE TABLE IF NOT EXISTS feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_name VARCHAR(100) NOT NULL,
    is_enabled BOOLEAN DEFAULT TRUE,
    town_id UUID REFERENCES towns(id),  -- NULL means global
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(feature_name, town_id)
);

-- Insert default feature flags
INSERT INTO feature_flags (feature_name, is_enabled, description) VALUES
    ('tiered_bid_increments', TRUE, 'Use tiered bid increment system'),
    ('anti_sniping', TRUE, 'Extend auctions when bids placed near end'),
    ('auto_bidding', FALSE, 'Allow users to set maximum auto-bid'),
    ('escrow_payments', FALSE, 'Enable payment escrow system'),
    ('promoted_listings', TRUE, 'Allow paid listing promotion'),
    ('hot_auction_tags', TRUE, 'Auto-tag trending/hot auctions')
ON CONFLICT DO NOTHING;

-- Auction tags for hot/trending auctions
CREATE TABLE IF NOT EXISTS auction_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID REFERENCES auctions(id) ON DELETE CASCADE,
    tag_type VARCHAR(50) NOT NULL,  -- 'trending', 'bidding_war', 'ending_soon', 'featured'
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    UNIQUE(auction_id, tag_type)
);

CREATE INDEX IF NOT EXISTS idx_auction_tags_auction ON auction_tags(auction_id);
CREATE INDEX IF NOT EXISTS idx_auction_tags_type ON auction_tags(tag_type);

-- User reputation/trust metrics
ALTER TABLE users ADD COLUMN IF NOT EXISTS completed_auctions INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_sales DECIMAL(10,2) DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS rating_count INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_trusted_seller BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS badges TEXT[] DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS member_since TIMESTAMP;

-- Update member_since for existing users
UPDATE users SET member_since = created_at WHERE member_since IS NULL;

-- Fraud detection signals table (backend-only, for review)
CREATE TABLE IF NOT EXISTS fraud_signals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    auction_id UUID REFERENCES auctions(id) ON DELETE CASCADE,
    signal_type VARCHAR(100) NOT NULL,  -- 'self_bidding', 'rapid_bids', 'cancellation_pattern'
    severity VARCHAR(20) DEFAULT 'low',  -- 'low', 'medium', 'high', 'critical'
    details JSONB,
    is_reviewed BOOLEAN DEFAULT FALSE,
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fraud_signals_user ON fraud_signals(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_signals_unreviewed ON fraud_signals(is_reviewed) WHERE is_reviewed = FALSE;

-- Saved searches / category alerts
CREATE TABLE IF NOT EXISTS saved_searches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    search_query TEXT,
    category_id UUID REFERENCES categories(id),
    town_id UUID REFERENCES towns(id),
    min_price DECIMAL(10,2),
    max_price DECIMAL(10,2),
    notify_new_listings BOOLEAN DEFAULT TRUE,
    notify_price_drops BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_saved_searches_user ON saved_searches(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_searches_category ON saved_searches(category_id);

-- Promoted auctions (monetization)
CREATE TABLE IF NOT EXISTS promoted_auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID REFERENCES auctions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    promotion_type VARCHAR(50) NOT NULL,  -- 'pinned', 'highlighted', 'boosted'
    town_id UUID REFERENCES towns(id),
    starts_at TIMESTAMP DEFAULT NOW(),
    ends_at TIMESTAMP NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_promoted_auctions_active ON promoted_auctions(is_active, ends_at);
CREATE INDEX IF NOT EXISTS idx_promoted_auctions_town ON promoted_auctions(town_id);

-- User ratings/reviews
CREATE TABLE IF NOT EXISTS user_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rater_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rated_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    auction_id UUID REFERENCES auctions(id),
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    role VARCHAR(20) NOT NULL,  -- 'buyer' or 'seller'
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(rater_id, auction_id)
);

CREATE INDEX IF NOT EXISTS idx_user_ratings_rated ON user_ratings(rated_user_id);

-- Trigger to update user rating stats
CREATE OR REPLACE FUNCTION update_user_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users
    SET rating = (
        SELECT COALESCE(AVG(rating), 0)
        FROM user_ratings
        WHERE rated_user_id = NEW.rated_user_id
    ),
    rating_count = (
        SELECT COUNT(*)
        FROM user_ratings
        WHERE rated_user_id = NEW.rated_user_id
    )
    WHERE id = NEW.rated_user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_user_rating
    AFTER INSERT OR UPDATE ON user_ratings
    FOR EACH ROW
    EXECUTE FUNCTION update_user_rating_stats();

-- Function to auto-tag hot auctions
CREATE OR REPLACE FUNCTION update_hot_auction_tags()
RETURNS void AS $$
BEGIN
    -- Clear expired tags
    DELETE FROM auction_tags WHERE expires_at < NOW();
    
    -- Tag auctions ending soon (< 1 hour)
    INSERT INTO auction_tags (auction_id, tag_type, expires_at)
    SELECT id, 'ending_soon', end_time
    FROM auctions
    WHERE status = 'active'
    AND end_time BETWEEN NOW() AND NOW() + INTERVAL '1 hour'
    ON CONFLICT (auction_id, tag_type) DO UPDATE SET expires_at = EXCLUDED.expires_at;
    
    -- Tag trending auctions (high view count in last 24h)
    INSERT INTO auction_tags (auction_id, tag_type, expires_at)
    SELECT id, 'trending', NOW() + INTERVAL '6 hours'
    FROM auctions
    WHERE status IN ('active', 'ending_soon')
    AND views > 50
    ON CONFLICT (auction_id, tag_type) DO UPDATE SET expires_at = EXCLUDED.expires_at;
    
    -- Tag bidding wars (5+ bids in last hour)
    INSERT INTO auction_tags (auction_id, tag_type, expires_at)
    SELECT a.id, 'bidding_war', NOW() + INTERVAL '1 hour'
    FROM auctions a
    WHERE a.status IN ('active', 'ending_soon')
    AND (
        SELECT COUNT(*) FROM bids b
        WHERE b.auction_id = a.id
        AND b.created_at > NOW() - INTERVAL '1 hour'
    ) >= 5
    ON CONFLICT (auction_id, tag_type) DO UPDATE SET expires_at = EXCLUDED.expires_at;
    
    -- Also update status to 'ending_soon' for auctions < 1 hour
    UPDATE auctions
    SET status = 'ending_soon'
    WHERE status = 'active'
    AND end_time BETWEEN NOW() AND NOW() + INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;
