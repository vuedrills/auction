-- ============================================
-- SHOP MESSAGES SCHEMA
-- Separate from auction messages for cleaner architecture
-- ============================================

-- Shop conversations (store-customer chat threads)
CREATE TABLE IF NOT EXISTS shop_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    last_message_preview TEXT,
    last_message_at TIMESTAMP,
    unread_count_store INT DEFAULT 0,  -- Messages unread by store owner
    unread_count_customer INT DEFAULT 0, -- Messages unread by customer
    status VARCHAR(20) DEFAULT 'active', -- active, archived, blocked
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(store_id, customer_id) -- One conversation per customer-store pair
);

-- Shop messages
CREATE TABLE IF NOT EXISTS shop_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES shop_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text', -- text, image, product_share
    product_id UUID REFERENCES products(id) ON DELETE SET NULL, -- If sharing a product
    attachment_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_shop_conversations_store_id ON shop_conversations(store_id);
CREATE INDEX IF NOT EXISTS idx_shop_conversations_customer_id ON shop_conversations(customer_id);
CREATE INDEX IF NOT EXISTS idx_shop_conversations_last_message ON shop_conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_shop_messages_conversation_id ON shop_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_shop_messages_created_at ON shop_messages(created_at DESC);

-- Trigger to update shop_conversation on new message
CREATE OR REPLACE FUNCTION update_shop_conversation_on_message()
RETURNS TRIGGER AS $$
DECLARE
    store_owner_id UUID;
BEGIN
    -- Get the store owner
    SELECT s.user_id INTO store_owner_id
    FROM shop_conversations sc
    JOIN stores s ON sc.store_id = s.id
    WHERE sc.id = NEW.conversation_id;
    
    -- Update conversation
    UPDATE shop_conversations 
    SET last_message_preview = LEFT(NEW.content, 100),
        last_message_at = NOW(),
        updated_at = NOW(),
        -- Increment unread for the OTHER party
        unread_count_store = CASE 
            WHEN NEW.sender_id != store_owner_id THEN unread_count_store + 1 
            ELSE unread_count_store 
        END,
        unread_count_customer = CASE 
            WHEN NEW.sender_id = store_owner_id THEN unread_count_customer + 1 
            ELSE unread_count_customer 
        END
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_shop_conversation
    AFTER INSERT ON shop_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_shop_conversation_on_message();
