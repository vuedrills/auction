-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID REFERENCES auctions(id) ON DELETE SET NULL,
    participant_1 UUID REFERENCES users(id) ON DELETE CASCADE,
    participant_2 UUID REFERENCES users(id) ON DELETE CASCADE,
    last_message_preview TEXT,
    last_message_at TIMESTAMP,
    unread_count_1 INT DEFAULT 0,
    unread_count_2 INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text',
    attachment_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Message types: text, image, system

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_conversations_participant_1 ON conversations(participant_1);
CREATE INDEX IF NOT EXISTS idx_conversations_participant_2 ON conversations(participant_2);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- Trigger to update conversation on new message
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations 
    SET last_message_preview = LEFT(NEW.content, 100),
        last_message_at = NOW(),
        unread_count_1 = CASE WHEN participant_1 != NEW.sender_id THEN unread_count_1 + 1 ELSE unread_count_1 END,
        unread_count_2 = CASE WHEN participant_2 != NEW.sender_id THEN unread_count_2 + 1 ELSE unread_count_2 END
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_conversation
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_on_message();
