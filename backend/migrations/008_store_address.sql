-- Add physical address to stores
ALTER TABLE stores ADD COLUMN IF NOT EXISTS address TEXT;
