-- Seed Products for Alice (Casino Royale)
INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'Vintage Rolex Oyster', 'Stunning vintage watch in great condition.', 4500.00, 'negotiable', '55555555-5555-5555-5555-555555555555', ARRAY['https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=500&q=80'], 1, true FROM stores WHERE slug = 'casino-royale';

INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'Designer Evening Gown', 'Silk evening gown, used once.', 250.00, 'fixed', '44444444-4444-4444-4444-444444444444', ARRAY['https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=500&q=80'], 1, true FROM stores WHERE slug = 'casino-royale';

-- Seed Products for Bob (Trabab Store)
INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'Drill Machine XR', 'Heavy duty industrial drill', 150.00, 'fixed', '11111111-1111-1111-1111-111111111111', ARRAY['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=500&q=80'], 5, true FROM stores WHERE slug = 'trabab-store';

INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'Solar Panel Kit', 'Complete 200W solar charging kit for home', 299.00, 'fixed', '66666666-6666-6666-6666-666666666666', ARRAY['https://images.unsplash.com/photo-1509391366360-2e959784a276?w=500&q=80'], 10, true FROM stores WHERE slug = 'trabab-store';
