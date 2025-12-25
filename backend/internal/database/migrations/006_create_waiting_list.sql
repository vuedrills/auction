-- Waiting list table
CREATE TABLE IF NOT EXISTS waiting_list (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    town_id UUID REFERENCES towns(id) ON DELETE CASCADE,
    position INT,
    status VARCHAR(50) DEFAULT 'waiting',
    auction_title VARCHAR(255),
    auction_description TEXT,
    expected_starting_price DECIMAL(10,2),
    notified_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, category_id, town_id)
);

-- Status types: waiting, notified, slot_available, expired, cancelled

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_waiting_list_user_id ON waiting_list(user_id);
CREATE INDEX IF NOT EXISTS idx_waiting_list_category_town ON waiting_list(category_id, town_id);
CREATE INDEX IF NOT EXISTS idx_waiting_list_status ON waiting_list(status);

-- Function to calculate position when joining waiting list
CREATE OR REPLACE FUNCTION calculate_waiting_position()
RETURNS TRIGGER AS $$
BEGIN
    SELECT COALESCE(MAX(position), 0) + 1 
    INTO NEW.position 
    FROM waiting_list 
    WHERE category_id = NEW.category_id 
    AND town_id = NEW.town_id 
    AND status = 'waiting';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_calculate_position
    BEFORE INSERT ON waiting_list
    FOR EACH ROW
    EXECUTE FUNCTION calculate_waiting_position();
