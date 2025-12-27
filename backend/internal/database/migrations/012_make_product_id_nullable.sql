-- Make product_id nullable to support store-level events
ALTER TABLE product_analytics ALTER COLUMN product_id DROP NOT NULL;
