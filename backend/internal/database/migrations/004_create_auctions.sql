-- Auctions table
CREATE TABLE IF NOT EXISTS auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    starting_price DECIMAL(10,2) NOT NULL,
    current_price DECIMAL(10,2),
    reserve_price DECIMAL(10,2),
    bid_increment DECIMAL(10,2) DEFAULT 1.00,
    seller_id UUID REFERENCES users(id) ON DELETE CASCADE,
    winner_id UUID REFERENCES users(id),
    category_id UUID REFERENCES categories(id),
    town_id UUID REFERENCES towns(id),
    suburb_id UUID REFERENCES suburbs(id),
    status VARCHAR(50) DEFAULT 'draft',
    condition VARCHAR(50) DEFAULT 'used',
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    original_end_time TIMESTAMP,
    anti_snipe_minutes INT DEFAULT 5,
    total_bids INT DEFAULT 0,
    views INT DEFAULT 0,
    images TEXT[],
    is_featured BOOLEAN DEFAULT FALSE,
    allow_offers BOOLEAN DEFAULT FALSE,
    pickup_location TEXT,
    shipping_available BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Auction status types: draft, pending, active, ending_soon, ended, sold, cancelled

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_auctions_seller_id ON auctions(seller_id);
CREATE INDEX IF NOT EXISTS idx_auctions_category_id ON auctions(category_id);
CREATE INDEX IF NOT EXISTS idx_auctions_town_id ON auctions(town_id);
CREATE INDEX IF NOT EXISTS idx_auctions_suburb_id ON auctions(suburb_id);
CREATE INDEX IF NOT EXISTS idx_auctions_status ON auctions(status);
CREATE INDEX IF NOT EXISTS idx_auctions_end_time ON auctions(end_time);
CREATE INDEX IF NOT EXISTS idx_auctions_created_at ON auctions(created_at DESC);

-- Create views for common queries
CREATE OR REPLACE VIEW active_auctions AS
SELECT a.*, 
       u.username as seller_username, 
       u.full_name as seller_name,
       u.avatar_url as seller_avatar,
       c.name as category_name,
       c.icon as category_icon,
       t.name as town_name,
       s.name as suburb_name
FROM auctions a
LEFT JOIN users u ON a.seller_id = u.id
LEFT JOIN categories c ON a.category_id = c.id
LEFT JOIN towns t ON a.town_id = t.id
LEFT JOIN suburbs s ON a.suburb_id = s.id
WHERE a.status IN ('active', 'ending_soon');
