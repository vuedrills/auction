-- Create product_analytics table
CREATE TABLE IF NOT EXISTS product_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL, -- 'impression', 'view', 'cart', 'checkout', 'contact', 'whatsapp', 'call'
    viewer_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Nullable for anonymous users
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add last_confirmed_at to products for freshness tracking
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS last_confirmed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create index for faster analytics queries
CREATE INDEX IF NOT EXISTS idx_product_analytics_store_date 
ON product_analytics(store_id, created_at);

CREATE INDEX IF NOT EXISTS idx_product_analytics_product_date 
ON product_analytics(product_id, created_at);
