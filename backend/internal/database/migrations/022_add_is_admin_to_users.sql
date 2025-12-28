-- Add is_admin column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Set the first user as admin (optional, but helpful for development)
-- UPDATE users SET is_admin = TRUE WHERE email = 'admin@trabab.co.zw' OR username = 'admin';
