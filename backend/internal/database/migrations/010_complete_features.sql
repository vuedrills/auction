-- =============================================================================
-- Migration 010: Complete Feature Set for AirMass Auction Platform
-- Implements: Reputation, Auto-Bid, Saved Searches, Promotions, Fraud Detection
-- =============================================================================

-- =============================================================================
-- 1️⃣ REPUTATION SYSTEM - Badge levels, completion rates, fast responder
-- =============================================================================

-- Extend users table with reputation fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS badge_level VARCHAR(20) DEFAULT 'none'; -- none, bronze, silver, gold
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_transactions INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS successful_transactions INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS disputed_transactions INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS avg_response_time_mins INT; -- Average response time
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_fast_responder BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS fraud_score DECIMAL(5,2) DEFAULT 0; -- 0-100, higher = more suspicious
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_flagged BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS flag_reason TEXT;

-- Calculate completion rate (no disputes)
CREATE OR REPLACE FUNCTION get_completion_rate(user_id_param UUID)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    total INT;
    successful INT;
BEGIN
    SELECT total_transactions, successful_transactions 
    INTO total, successful
    FROM users WHERE id = user_id_param;
    
    IF total = 0 THEN
        RETURN 100.00;
    END IF;
    
    RETURN ROUND((successful::DECIMAL / total::DECIMAL) * 100, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to recalculate user badge level based on stats
CREATE OR REPLACE FUNCTION update_user_badge()
RETURNS TRIGGER AS $$
DECLARE
    completion_rate DECIMAL;
    rating DECIMAL;
    total_sales INT;
BEGIN
    -- Calculate completion rate
    IF NEW.total_transactions > 0 THEN
        completion_rate := (NEW.successful_transactions::DECIMAL / NEW.total_transactions::DECIMAL) * 100;
    ELSE
        completion_rate := 100;
    END IF;
    
    rating := NEW.rating;
    total_sales := NEW.completed_auctions;
    
    -- Badge level logic:
    -- Gold: 50+ sales, 4.8+ rating, 98%+ completion
    -- Silver: 20+ sales, 4.5+ rating, 95%+ completion
    -- Bronze: 5+ sales, 4.0+ rating, 90%+ completion
    IF total_sales >= 50 AND rating >= 4.8 AND completion_rate >= 98 THEN
        NEW.badge_level := 'gold';
        NEW.is_trusted_seller := TRUE;
    ELSIF total_sales >= 20 AND rating >= 4.5 AND completion_rate >= 95 THEN
        NEW.badge_level := 'silver';
        NEW.is_trusted_seller := TRUE;
    ELSIF total_sales >= 5 AND rating >= 4.0 AND completion_rate >= 90 THEN
        NEW.badge_level := 'bronze';
    ELSE
        NEW.badge_level := 'none';
    END IF;
    
    -- Fast responder: avg response time < 30 mins
    IF NEW.avg_response_time_mins IS NOT NULL AND NEW.avg_response_time_mins < 30 THEN
        NEW.is_fast_responder := TRUE;
    ELSE
        NEW.is_fast_responder := FALSE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_user_badge
    BEFORE UPDATE ON users
    FOR EACH ROW
    WHEN (OLD.completed_auctions IS DISTINCT FROM NEW.completed_auctions 
       OR OLD.rating IS DISTINCT FROM NEW.rating 
       OR OLD.total_transactions IS DISTINCT FROM NEW.total_transactions
       OR OLD.avg_response_time_mins IS DISTINCT FROM NEW.avg_response_time_mins)
    EXECUTE FUNCTION update_user_badge();

-- Extend user_ratings table for more detailed reviews
ALTER TABLE user_ratings ADD COLUMN IF NOT EXISTS communication_rating INT CHECK (communication_rating >= 1 AND communication_rating <= 5);
ALTER TABLE user_ratings ADD COLUMN IF NOT EXISTS accuracy_rating INT CHECK (accuracy_rating >= 1 AND accuracy_rating <= 5);
ALTER TABLE user_ratings ADD COLUMN IF NOT EXISTS speed_rating INT CHECK (speed_rating >= 1 AND speed_rating <= 5);
ALTER TABLE user_ratings ADD COLUMN IF NOT EXISTS would_recommend BOOLEAN DEFAULT TRUE;

-- =============================================================================
-- 2️⃣ AUTO-BID SYSTEM - Max bid with transactional tiered increments
-- =============================================================================

-- Auto-bid configuration table
CREATE TABLE IF NOT EXISTS auto_bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID REFERENCES auctions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    max_amount DECIMAL(10,2) NOT NULL,
    current_bid_amount DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deactivated_at TIMESTAMP,
    deactivation_reason VARCHAR(50), -- 'max_reached', 'outbid', 'user_cancelled', 'auction_ended'
    UNIQUE(auction_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_auto_bids_auction ON auto_bids(auction_id, is_active);
CREATE INDEX IF NOT EXISTS idx_auto_bids_user ON auto_bids(user_id, is_active);

-- Function to process auto-bids after a new bid is placed
-- This is called AFTER a regular bid to see if any auto-bids should respond
CREATE OR REPLACE FUNCTION process_auto_bids(auction_id_param UUID, current_bid_amount DECIMAL, current_bidder_id UUID)
RETURNS TABLE(
    auto_bid_id UUID,
    auto_bidder_id UUID,
    new_bid_amount DECIMAL,
    was_placed BOOLEAN
) AS $$
DECLARE
    auto_bid RECORD;
    next_bid DECIMAL;
    increment DECIMAL;
    placed_bid BOOLEAN := FALSE;
BEGIN
    -- Get the increment for the current price
    increment := get_bid_increment(current_bid_amount);
    next_bid := current_bid_amount + increment;
    
    -- Find all active auto-bids for this auction that can still bid
    FOR auto_bid IN 
        SELECT ab.*, u.username 
        FROM auto_bids ab
        JOIN users u ON ab.user_id = u.id
        WHERE ab.auction_id = auction_id_param 
        AND ab.is_active = TRUE
        AND ab.user_id != current_bidder_id
        AND ab.max_amount >= next_bid
        ORDER BY ab.max_amount DESC, ab.created_at ASC
        LIMIT 1
    LOOP
        -- Place the auto-bid
        INSERT INTO bids (auction_id, bidder_id, amount, is_auto_bid)
        VALUES (auction_id_param, auto_bid.user_id, next_bid, TRUE);
        
        -- Update the auto-bid record
        UPDATE auto_bids 
        SET current_bid_amount = next_bid, updated_at = NOW()
        WHERE id = auto_bid.id;
        
        -- Check if max is reached
        IF auto_bid.max_amount < next_bid + get_bid_increment(next_bid) THEN
            UPDATE auto_bids 
            SET is_active = FALSE, deactivated_at = NOW(), deactivation_reason = 'max_reached'
            WHERE id = auto_bid.id;
        END IF;
        
        placed_bid := TRUE;
        
        RETURN QUERY SELECT auto_bid.id, auto_bid.user_id, next_bid, TRUE;
    END LOOP;
    
    -- Deactivate any auto-bids that can no longer compete
    UPDATE auto_bids
    SET is_active = FALSE, deactivated_at = NOW(), deactivation_reason = 'outbid'
    WHERE auction_id = auction_id_param
    AND is_active = TRUE
    AND max_amount < next_bid;
    
    IF NOT placed_bid THEN
        RETURN QUERY SELECT NULL::UUID, NULL::UUID, 0::DECIMAL, FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 3️⃣ SAVED SEARCHES + ALERTS
-- =============================================================================

-- Extend saved_searches table (already exists, add more fields)
ALTER TABLE saved_searches ADD COLUMN IF NOT EXISTS name VARCHAR(100);
ALTER TABLE saved_searches ADD COLUMN IF NOT EXISTS keywords TEXT[];
ALTER TABLE saved_searches ADD COLUMN IF NOT EXISTS condition VARCHAR(50);
ALTER TABLE saved_searches ADD COLUMN IF NOT EXISTS notify_email BOOLEAN DEFAULT TRUE;
ALTER TABLE saved_searches ADD COLUMN IF NOT EXISTS notify_push BOOLEAN DEFAULT TRUE;
ALTER TABLE saved_searches ADD COLUMN IF NOT EXISTS last_notified_at TIMESTAMP;
ALTER TABLE saved_searches ADD COLUMN IF NOT EXISTS match_count INT DEFAULT 0;
ALTER TABLE saved_searches ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Search alerts log (for tracking what notifications were sent)
CREATE TABLE IF NOT EXISTS search_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    saved_search_id UUID REFERENCES saved_searches(id) ON DELETE CASCADE,
    auction_id UUID REFERENCES auctions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    alert_type VARCHAR(20) NOT NULL, -- 'new_match', 'price_drop'
    was_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(saved_search_id, auction_id, alert_type)
);

CREATE INDEX IF NOT EXISTS idx_search_alerts_user ON search_alerts(user_id, was_read);

-- Function to find auctions matching saved searches
CREATE OR REPLACE FUNCTION find_matching_auctions(search_id_param UUID)
RETURNS TABLE(auction_id UUID, match_score INT) AS $$
DECLARE
    search RECORD;
BEGIN
    SELECT * INTO search FROM saved_searches WHERE id = search_id_param;
    
    RETURN QUERY
    SELECT a.id, 
           (CASE WHEN search.category_id IS NOT NULL AND a.category_id = search.category_id THEN 50 ELSE 0 END +
            CASE WHEN search.town_id IS NOT NULL AND a.town_id = search.town_id THEN 30 ELSE 0 END +
            CASE WHEN search.min_price IS NOT NULL AND COALESCE(a.current_price, a.starting_price) >= search.min_price THEN 10 ELSE 0 END +
            CASE WHEN search.max_price IS NOT NULL AND COALESCE(a.current_price, a.starting_price) <= search.max_price THEN 10 ELSE 0 END
           ) as score
    FROM auctions a
    WHERE a.status IN ('active', 'ending_soon')
    AND (search.category_id IS NULL OR a.category_id = search.category_id)
    AND (search.town_id IS NULL OR a.town_id = search.town_id)
    AND (search.min_price IS NULL OR COALESCE(a.current_price, a.starting_price) >= search.min_price)
    AND (search.max_price IS NULL OR COALESCE(a.current_price, a.starting_price) <= search.max_price)
    AND (search.keywords IS NULL OR array_length(search.keywords, 1) IS NULL OR 
         EXISTS (SELECT 1 FROM unnest(search.keywords) kw WHERE a.title ILIKE '%' || kw || '%'))
    AND a.created_at > COALESCE(search.last_notified_at, search.created_at)
    ORDER BY score DESC;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 4️⃣ PROMOTED AUCTIONS - Featured ribbon, time-limited boosts
-- =============================================================================

-- Extend promoted_auctions table (already exists)
ALTER TABLE promoted_auctions ADD COLUMN IF NOT EXISTS impressions INT DEFAULT 0;
ALTER TABLE promoted_auctions ADD COLUMN IF NOT EXISTS clicks INT DEFAULT 0;
ALTER TABLE promoted_auctions ADD COLUMN IF NOT EXISTS boost_multiplier DECIMAL(3,1) DEFAULT 1.5;
ALTER TABLE promoted_auctions ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20) DEFAULT 'pending'; -- pending, paid, refunded

-- Promotion pricing table
CREATE TABLE IF NOT EXISTS promotion_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    promotion_type VARCHAR(50) NOT NULL, -- 'featured', 'boosted', 'pinned', 'highlighted'
    duration_hours INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    boost_multiplier DECIMAL(3,1) DEFAULT 1.0,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    town_id UUID REFERENCES towns(id), -- NULL = global pricing
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert default promotion pricing
INSERT INTO promotion_pricing (name, promotion_type, duration_hours, price, boost_multiplier, description) VALUES
    ('Featured 24h', 'featured', 24, 1.99, 1.5, 'Featured ribbon for 24 hours'),
    ('Featured 3 Days', 'featured', 72, 4.99, 1.5, 'Featured ribbon for 3 days'),
    ('Featured Week', 'featured', 168, 9.99, 1.5, 'Featured ribbon for 1 week'),
    ('Boosted 24h', 'boosted', 24, 0.99, 1.3, 'Increased visibility for 24 hours'),
    ('Pinned Town', 'pinned', 24, 2.99, 2.0, 'Pinned at top of town listings for 24 hours'),
    ('Highlighted', 'highlighted', 48, 1.49, 1.2, 'Highlighted with special border for 48 hours')
ON CONFLICT DO NOTHING;

-- Function to get active promotions for an auction
CREATE OR REPLACE FUNCTION get_auction_promotions(auction_id_param UUID)
RETURNS TABLE(
    promotion_type VARCHAR,
    ends_at TIMESTAMP,
    boost_multiplier DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT pa.promotion_type, pa.ends_at, pa.boost_multiplier
    FROM promoted_auctions pa
    WHERE pa.auction_id = auction_id_param
    AND pa.is_active = TRUE
    AND pa.ends_at > NOW()
    AND pa.payment_status = 'paid';
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 5️⃣ CATEGORY SLOT PRICING - Pay to jump waiting list
-- =============================================================================

-- Category slot purchases table
CREATE TABLE IF NOT EXISTS slot_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id),
    town_id UUID REFERENCES towns(id),
    auction_id UUID REFERENCES auctions(id),
    amount_paid DECIMAL(10,2) NOT NULL,
    original_wait_position INT, -- Position in waiting list before purchase
    purchase_type VARCHAR(30) NOT NULL, -- 'skip_queue', 'extra_slot'
    status VARCHAR(20) DEFAULT 'pending', -- pending, completed, refunded
    created_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP
);

-- Slot pricing by category and town
CREATE TABLE IF NOT EXISTS slot_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES categories(id),
    town_id UUID REFERENCES towns(id),
    skip_queue_price DECIMAL(10,2) DEFAULT 2.99, -- Price to skip queue
    extra_slot_price DECIMAL(10,2) DEFAULT 4.99, -- Price for temporary extra slot
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(category_id, town_id)
);

-- =============================================================================
-- 6️⃣ FRAUD & BEHAVIOR SCORING
-- =============================================================================

-- Extend fraud_signals table (already exists)
ALTER TABLE fraud_signals ADD COLUMN IF NOT EXISTS ip_address INET;
ALTER TABLE fraud_signals ADD COLUMN IF NOT EXISTS device_fingerprint TEXT;
ALTER TABLE fraud_signals ADD COLUMN IF NOT EXISTS score_impact DECIMAL(5,2) DEFAULT 0;
ALTER TABLE fraud_signals ADD COLUMN IF NOT EXISTS auto_flagged BOOLEAN DEFAULT FALSE;

-- User behavior metrics for fraud detection
CREATE TABLE IF NOT EXISTS user_behavior_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    bid_cancel_rate DECIMAL(5,2) DEFAULT 0, -- % of bids cancelled
    avg_bid_time_before_end_mins INT, -- Average time before auction end when bidding
    same_ip_bidders_count INT DEFAULT 0, -- Number of other users on same IP
    rapid_bid_count INT DEFAULT 0, -- Bids within 5 seconds of each other
    self_bid_attempts INT DEFAULT 0, -- Attempts to bid on own auctions
    shill_bid_probability DECIMAL(5,2) DEFAULT 0, -- 0-100
    account_age_days INT,
    last_calculated_at TIMESTAMP DEFAULT NOW(),
    risk_level VARCHAR(20) DEFAULT 'low' -- low, medium, high, critical
);

CREATE INDEX IF NOT EXISTS idx_behavior_risk ON user_behavior_metrics(risk_level);

-- Function to calculate fraud score for a user
CREATE OR REPLACE FUNCTION calculate_fraud_score(user_id_param UUID)
RETURNS DECIMAL AS $$
DECLARE
    score DECIMAL := 0;
    metrics RECORD;
    signal_count INT;
BEGIN
    -- Get behavior metrics
    SELECT * INTO metrics FROM user_behavior_metrics WHERE user_id = user_id_param;
    
    IF metrics IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Bid cancel rate contributes up to 20 points
    score := score + LEAST(metrics.bid_cancel_rate * 0.5, 20);
    
    -- Same IP bidders contributes up to 30 points
    score := score + LEAST(metrics.same_ip_bidders_count * 5, 30);
    
    -- Rapid bid count contributes up to 15 points
    score := score + LEAST(metrics.rapid_bid_count * 1, 15);
    
    -- Self-bid attempts contributes up to 25 points
    score := score + LEAST(metrics.self_bid_attempts * 10, 25);
    
    -- Shill bid probability
    score := score + metrics.shill_bid_probability * 0.1;
    
    -- Count unreviewed fraud signals
    SELECT COUNT(*) INTO signal_count 
    FROM fraud_signals 
    WHERE user_id = user_id_param AND is_reviewed = FALSE;
    
    score := score + LEAST(signal_count * 5, 20);
    
    -- Cap at 100
    RETURN LEAST(score, 100);
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-flag users when fraud score exceeds threshold
CREATE OR REPLACE FUNCTION check_and_flag_user()
RETURNS TRIGGER AS $$
DECLARE
    fraud_score DECIMAL;
BEGIN
    fraud_score := calculate_fraud_score(NEW.user_id);
    
    -- Update risk level
    IF fraud_score >= 70 THEN
        NEW.risk_level := 'critical';
        UPDATE users SET is_flagged = TRUE, flag_reason = 'High fraud score: ' || fraud_score::TEXT 
        WHERE id = NEW.user_id AND is_flagged = FALSE;
    ELSIF fraud_score >= 50 THEN
        NEW.risk_level := 'high';
    ELSIF fraud_score >= 30 THEN
        NEW.risk_level := 'medium';
    ELSE
        NEW.risk_level := 'low';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_check_fraud
    BEFORE UPDATE ON user_behavior_metrics
    FOR EACH ROW
    EXECUTE FUNCTION check_and_flag_user();

-- =============================================================================
-- 7️⃣ TOWN IDENTITY & COMMUNITY - Leaderboards, top sellers
-- =============================================================================

-- Town leaderboard cached table (refreshed periodically)
CREATE TABLE IF NOT EXISTS town_leaderboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    town_id UUID REFERENCES towns(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rank INT NOT NULL,
    leaderboard_type VARCHAR(30) NOT NULL, -- 'top_sellers', 'most_active', 'highest_rated', 'most_bids'
    period VARCHAR(20) NOT NULL, -- 'weekly', 'monthly', 'all_time'
    score DECIMAL(10,2) NOT NULL,
    metric_value INT, -- The actual value (sales, bids, etc.)
    calculated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(town_id, user_id, leaderboard_type, period)
);

CREATE INDEX IF NOT EXISTS idx_leaderboard_town ON town_leaderboards(town_id, leaderboard_type, period);
CREATE INDEX IF NOT EXISTS idx_leaderboard_rank ON town_leaderboards(town_id, leaderboard_type, rank);

-- Function to refresh town leaderboards
CREATE OR REPLACE FUNCTION refresh_town_leaderboard(town_id_param UUID, lb_type VARCHAR, lb_period VARCHAR)
RETURNS void AS $$
DECLARE
    period_start TIMESTAMP;
BEGIN
    -- Determine period start
    CASE lb_period
        WHEN 'weekly' THEN period_start := NOW() - INTERVAL '7 days';
        WHEN 'monthly' THEN period_start := NOW() - INTERVAL '30 days';
        ELSE period_start := '1970-01-01'::TIMESTAMP;
    END CASE;
    
    -- Delete old entries
    DELETE FROM town_leaderboards 
    WHERE town_id = town_id_param 
    AND leaderboard_type = lb_type 
    AND period = lb_period;
    
    -- Insert new rankings
    IF lb_type = 'top_sellers' THEN
        INSERT INTO town_leaderboards (town_id, user_id, rank, leaderboard_type, period, score, metric_value)
        SELECT 
            town_id_param,
            u.id,
            ROW_NUMBER() OVER (ORDER BY COUNT(a.id) DESC, u.rating DESC),
            lb_type,
            lb_period,
            COUNT(a.id) * 10 + COALESCE(u.rating, 0) * 5,
            COUNT(a.id)::INT
        FROM users u
        JOIN auctions a ON a.seller_id = u.id
        WHERE u.home_town_id = town_id_param
        AND a.status = 'sold'
        AND a.updated_at >= period_start
        GROUP BY u.id, u.rating
        ORDER BY COUNT(a.id) DESC
        LIMIT 50;
    ELSIF lb_type = 'highest_rated' THEN
        INSERT INTO town_leaderboards (town_id, user_id, rank, leaderboard_type, period, score, metric_value)
        SELECT 
            town_id_param,
            u.id,
            ROW_NUMBER() OVER (ORDER BY u.rating DESC, u.rating_count DESC),
            lb_type,
            lb_period,
            u.rating * 20,
            u.rating_count
        FROM users u
        WHERE u.home_town_id = town_id_param
        AND u.rating_count >= 3
        ORDER BY u.rating DESC
        LIMIT 50;
    ELSIF lb_type = 'most_active' THEN
        INSERT INTO town_leaderboards (town_id, user_id, rank, leaderboard_type, period, score, metric_value)
        SELECT 
            town_id_param,
            u.id,
            ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT b.id) + COUNT(DISTINCT a.id) DESC),
            lb_type,
            lb_period,
            COUNT(DISTINCT b.id) * 1 + COUNT(DISTINCT a.id) * 5,
            (COUNT(DISTINCT b.id) + COUNT(DISTINCT a.id))::INT
        FROM users u
        LEFT JOIN bids b ON b.bidder_id = u.id AND b.created_at >= period_start
        LEFT JOIN auctions a ON a.seller_id = u.id AND a.created_at >= period_start
        WHERE u.home_town_id = town_id_param
        GROUP BY u.id
        ORDER BY COUNT(DISTINCT b.id) + COUNT(DISTINCT a.id) DESC
        LIMIT 50;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Town stats cached table
CREATE TABLE IF NOT EXISTS town_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    town_id UUID REFERENCES towns(id) ON DELETE CASCADE UNIQUE,
    active_auctions INT DEFAULT 0,
    total_auctions INT DEFAULT 0,
    total_users INT DEFAULT 0,
    active_sellers INT DEFAULT 0,
    total_sales_value DECIMAL(12,2) DEFAULT 0,
    avg_auction_price DECIMAL(10,2) DEFAULT 0,
    top_category_id UUID REFERENCES categories(id),
    calculated_at TIMESTAMP DEFAULT NOW()
);

-- Function to refresh town stats
CREATE OR REPLACE FUNCTION refresh_town_stats(town_id_param UUID)
RETURNS void AS $$
BEGIN
    INSERT INTO town_stats (town_id, active_auctions, total_auctions, total_users, active_sellers, total_sales_value, avg_auction_price, top_category_id)
    SELECT 
        town_id_param,
        (SELECT COUNT(*) FROM auctions WHERE town_id = town_id_param AND status IN ('active', 'ending_soon')),
        (SELECT COUNT(*) FROM auctions WHERE town_id = town_id_param),
        (SELECT COUNT(*) FROM users WHERE home_town_id = town_id_param),
        (SELECT COUNT(DISTINCT seller_id) FROM auctions WHERE town_id = town_id_param AND status IN ('active', 'ending_soon')),
        (SELECT COALESCE(SUM(current_price), 0) FROM auctions WHERE town_id = town_id_param AND status = 'sold'),
        (SELECT COALESCE(AVG(current_price), 0) FROM auctions WHERE town_id = town_id_param AND status = 'sold'),
        (SELECT category_id FROM auctions WHERE town_id = town_id_param GROUP BY category_id ORDER BY COUNT(*) DESC LIMIT 1)
    ON CONFLICT (town_id) DO UPDATE SET
        active_auctions = EXCLUDED.active_auctions,
        total_auctions = EXCLUDED.total_auctions,
        total_users = EXCLUDED.total_users,
        active_sellers = EXCLUDED.active_sellers,
        total_sales_value = EXCLUDED.total_sales_value,
        avg_auction_price = EXCLUDED.avg_auction_price,
        top_category_id = EXCLUDED.top_category_id,
        calculated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_users_badge ON users(badge_level) WHERE badge_level != 'none';
CREATE INDEX IF NOT EXISTS idx_users_trusted ON users(is_trusted_seller) WHERE is_trusted_seller = TRUE;
CREATE INDEX IF NOT EXISTS idx_users_fast_responder ON users(is_fast_responder) WHERE is_fast_responder = TRUE;
CREATE INDEX IF NOT EXISTS idx_users_home_town ON users(home_town_id);
CREATE INDEX IF NOT EXISTS idx_promoted_active ON promoted_auctions(is_active, ends_at) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_saved_searches_active ON saved_searches(user_id, is_active) WHERE is_active = TRUE;
