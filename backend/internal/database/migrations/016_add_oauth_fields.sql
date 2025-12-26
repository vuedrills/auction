-- Add OAuth provider fields to users table for Google Sign-In support
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(50) DEFAULT 'email';

-- Make password_hash nullable for OAuth users (they don't have passwords)
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;

-- Create index on google_id for faster OAuth lookups
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);

-- Add index on auth_provider for querying by provider
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);
