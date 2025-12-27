-- Seed Stores
INSERT INTO stores (user_id, store_name, slug, tagline, about, logo_url, category_id, town_id, is_verified, is_featured, total_products) VALUES
('784033d1-1769-4706-80f4-9f777a6a0ddd', 'Tech Havens', 'tech-havens', 'Your daily tech destination', 'We provide the best gadgets in Harare since 2024.', 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&q=80', '7512c67b-0b31-42d8-bfd4-b5c4b00d90c0', '014b1b2e-ee5d-4dc3-a026-099161626008', true, true, 3),
('6c310cc6-efe4-4753-9f58-204fc26e71c7', 'Fashion Forward', 'fashion-forward', 'Stay trendy, stay bold', 'Bulawayos finest boutique for modern fashion.', 'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=500&q=80', '713a8838-443b-4ef8-a639-c4a7f47d34e9', '85663e94-1939-4764-9abc-6b593dc10079', true, false, 2),
('94a755f3-62a8-49c6-ae3b-b43ce4002711', 'Green Grocers', 'green-grocers', 'Fresh from the farm', 'Mutare locally sourced organic fruits and vegetables.', 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&q=80', '35a3f2ea-c20c-4c97-86a1-c42625bdad31', '5d2f49c8-48c0-4afe-a3ba-31cb4040dc89', false, true, 2)
ON CONFLICT (user_id) DO NOTHING;

-- Seed Products
-- Tech Havens Products
INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'MacBook Pro M2', 'Powerful laptop for professionals', 1800.00, 'fixed', '11111111-1111-1111-1111-111111111111', ARRAY['https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=500&q=80'], 5, true FROM stores WHERE slug = 'tech-havens';

INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'iPhone 14 Pro', 'Deep purple, 128GB, Brand new', 1100.00, 'negotiable', '11111111-1111-1111-1111-111111111111', ARRAY['https://images.unsplash.com/photo-1663499482523-1c0c1bae4ce1?w=500&q=80'], 3, true FROM stores WHERE slug = 'tech-havens';

INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'Sony WH-1000XM5', 'Noise cancelling headphones', 350.00, 'fixed', '11111111-1111-1111-1111-111111111111', ARRAY['https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=500&q=80'], 10, true FROM stores WHERE slug = 'tech-havens';

-- Fashion Forward Products
INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'Vintage Denim Jacket', 'Limited edition vintage wash', 55.00, 'fixed', '44444444-4444-4444-4444-444444444444', ARRAY['https://images.unsplash.com/photo-1527010154944-f2241763d806?w=500&q=80'], 2, true FROM stores WHERE slug = 'fashion-forward';

INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'Adidas Ultraboost', 'Comfortable running shoes', 120.00, 'fixed', '44444444-4444-4444-4444-444444444444', ARRAY['https://images.unsplash.com/photo-1587563871167-1ee9c731aefb?w=500&q=80'], 8, true FROM stores WHERE slug = 'fashion-forward';

-- Green Grocers Products
INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'Red Fuji Apples (5kg)', 'Crisp and sweet farm fresh apples', 12.00, 'fixed', '11111111-1111-1111-1111-111111111111', ARRAY['https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?w=500&q=80'], 50, true FROM stores WHERE slug = 'green-grocers';

INSERT INTO products (store_id, title, description, price, pricing_type, category_id, images, stock_quantity, is_available)
SELECT id, 'Organic Honey (500g)', 'Pure unprocessed multi-flower honey', 8.50, 'fixed', '11111111-1111-1111-1111-111111111111', ARRAY['https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=500&q=80'], 20, true FROM stores WHERE slug = 'green-grocers';
