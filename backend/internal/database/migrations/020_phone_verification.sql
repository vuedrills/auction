-- =====================================================
-- Migration 020: Phone Verification System
-- Adds phone verification badge and tracking
-- =====================================================

-- Add phone verification fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified_at TIMESTAMP;

-- Create phone verification tracking table
CREATE TABLE IF NOT EXISTS phone_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    phone_number VARCHAR(50) NOT NULL,
    verification_code VARCHAR(10) NOT NULL,
    code_sent_at TIMESTAMP DEFAULT NOW(),
    code_expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '5 minutes',
    verified_at TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    attempts INT DEFAULT 0,
    ip_address INET,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for phone verifications
CREATE INDEX IF NOT EXISTS idx_phone_verifications_user ON phone_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_phone ON phone_verifications(phone_number);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_code ON phone_verifications(verification_code, is_verified);

-- Index for verified users
CREATE INDEX IF NOT EXISTS idx_users_phone_verified ON users(phone_verified) WHERE phone_verified = TRUE;

-- Insert Phone Verified badge if badges table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'badges') THEN
        INSERT INTO badges (
            name,
            display_name,
            description,
            icon,
            category,
            priority
        ) VALUES (
            'phone_verified',
            'Phone Verified',
            'Verified phone number',
            'phone',
            'verification',
            95
        ) ON CONFLICT (name) DO NOTHING;
    END IF;
END $$;

