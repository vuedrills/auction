-- Create app_settings table
CREATE TABLE IF NOT EXISTS app_settings (
    key VARCHAR(100) PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insert default keys if they don't exist
INSERT INTO app_settings (key, value) VALUES 
('faq_content', '# Frequently Asked Questions\n\nComing soon...'),
('about_content', '# About Us\n\nComing soon...'),
('privacy_policy', '# Privacy Policy\n\nComing soon...'),
('terms_of_service', '# Terms of Service\n\nComing soon...')
ON CONFLICT (key) DO NOTHING;
