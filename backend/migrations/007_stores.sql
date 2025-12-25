-- ============================================
-- SELLER STOREFRONT SCHEMA
-- Phase 1: Foundation
-- ============================================

-- Store categories for browsing
CREATE TABLE IF NOT EXISTS store_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    icon VARCHAR(50),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Seed store categories
INSERT INTO store_categories (name, display_name, icon, sort_order) VALUES
('electronics', 'Electronics & Gadgets', 'devices', 1),
('fashion', 'Fashion & Clothing', 'checkroom', 2),
('beauty', 'Beauty & Personal Care', 'spa', 3),
('food', 'Food & Groceries', 'restaurant', 4),
('home', 'Home & Garden', 'home', 5),
('automotive', 'Automotive & Parts', 'directions_car', 6),
('farming', 'Farming & Agriculture', 'agriculture', 7),
('services', 'Services & Skills', 'handyman', 8),
('crafts', 'Crafts & Handmade', 'palette', 9),
('other', 'Other', 'category', 10)
ON CONFLICT (name) DO NOTHING;

-- Store profiles (extends users)
CREATE TABLE IF NOT EXISTS stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    store_name VARCHAR(100) NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    tagline VARCHAR(100),
    about TEXT,
    logo_url TEXT,
    cover_url TEXT,
    category_id UUID REFERENCES store_categories(id),
    whatsapp VARCHAR(20),
    phone VARCHAR(20),
    delivery_options TEXT[] DEFAULT '{"pickup"}',
    delivery_radius_km INT,
    operating_hours JSONB DEFAULT '{}',
    town_id UUID REFERENCES towns(id),
    suburb_id UUID REFERENCES suburbs(id),
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    total_products INT DEFAULT 0,
    total_sales INT DEFAULT 0,
    follower_count INT DEFAULT 0,
    avg_response_time_minutes INT,
    views INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Products (fixed price items - separate from auctions)
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    compare_at_price DECIMAL(12,2),
    pricing_type VARCHAR(20) DEFAULT 'fixed', -- fixed, negotiable, service
    category_id UUID REFERENCES categories(id),
    condition VARCHAR(20) DEFAULT 'new', -- new, used, refurbished
    images TEXT[] DEFAULT '{}',
    stock_quantity INT DEFAULT 1,
    is_available BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    views INT DEFAULT 0,
    enquiries INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Store followers
CREATE TABLE IF NOT EXISTS store_followers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    followed_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(store_id, user_id)
);

-- Store enquiries (when customer contacts seller)
CREATE TABLE IF NOT EXISTS store_enquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id),
    product_id UUID REFERENCES products(id),
    customer_id UUID NOT NULL REFERENCES users(id),
    message TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, responded, converted, closed
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Store analytics (aggregated daily)
CREATE TABLE IF NOT EXISTS store_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id),
    date DATE NOT NULL,
    views INT DEFAULT 0,
    unique_visitors INT DEFAULT 0,
    product_views INT DEFAULT 0,
    enquiries INT DEFAULT 0,
    whatsapp_clicks INT DEFAULT 0,
    call_clicks INT DEFAULT 0,
    follows_gained INT DEFAULT 0,
    UNIQUE(store_id, date)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_stores_user_id ON stores(user_id);
CREATE INDEX IF NOT EXISTS idx_stores_slug ON stores(slug);
CREATE INDEX IF NOT EXISTS idx_stores_category_id ON stores(category_id);
CREATE INDEX IF NOT EXISTS idx_stores_town_id ON stores(town_id);
CREATE INDEX IF NOT EXISTS idx_stores_is_active ON stores(is_active);
CREATE INDEX IF NOT EXISTS idx_stores_is_featured ON stores(is_featured);

CREATE INDEX IF NOT EXISTS idx_products_store_id ON products(store_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_is_available ON products(is_available);
CREATE INDEX IF NOT EXISTS idx_products_pricing_type ON products(pricing_type);

CREATE INDEX IF NOT EXISTS idx_store_followers_store_id ON store_followers(store_id);
CREATE INDEX IF NOT EXISTS idx_store_followers_user_id ON store_followers(user_id);

CREATE INDEX IF NOT EXISTS idx_store_enquiries_store_id ON store_enquiries(store_id);
CREATE INDEX IF NOT EXISTS idx_store_enquiries_customer_id ON store_enquiries(customer_id);

CREATE INDEX IF NOT EXISTS idx_store_analytics_store_id_date ON store_analytics(store_id, date);
