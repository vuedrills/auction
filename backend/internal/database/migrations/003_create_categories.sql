-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    icon VARCHAR(100),
    description TEXT,
    parent_id UUID REFERENCES categories(id),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Category slots per town (controls how many auctions can be active per category per town)
CREATE TABLE IF NOT EXISTS category_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    town_id UUID REFERENCES towns(id) ON DELETE CASCADE,
    max_active_auctions INT DEFAULT 10,
    auction_duration_hours INT DEFAULT 168,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(category_id, town_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_category_slots_category_town ON category_slots(category_id, town_id);

-- Seed categories
INSERT INTO categories (id, name, icon, description, sort_order) VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Electronics', 'devices', 'Phones, computers, cameras, and more', 1),
    ('22222222-2222-2222-2222-222222222222', 'Furniture', 'chair', 'Tables, chairs, sofas, and home furnishings', 2),
    ('33333333-3333-3333-3333-333333333333', 'Vehicles', 'directions_car', 'Cars, motorcycles, and bicycles', 3),
    ('44444444-4444-4444-4444-444444444444', 'Fashion', 'styler', 'Clothing, shoes, and accessories', 4),
    ('55555555-5555-5555-5555-555555555555', 'Collectibles', 'collections', 'Antiques, art, and rare items', 5),
    ('66666666-6666-6666-6666-666666666666', 'Home & Garden', 'yard', 'Appliances, tools, and garden items', 6),
    ('77777777-7777-7777-7777-777777777777', 'Sports', 'sports_soccer', 'Sports equipment and gear', 7),
    ('88888888-8888-8888-8888-888888888888', 'Books & Media', 'menu_book', 'Books, music, and movies', 8),
    ('99999999-9999-9999-9999-999999999999', 'Other', 'category', 'Everything else', 9)
ON CONFLICT DO NOTHING;
