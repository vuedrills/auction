-- Zimbabwe Towns and Suburbs
-- ============================

-- Create towns table
CREATE TABLE IF NOT EXISTS towns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Zimbabwe',
    timezone VARCHAR(50) DEFAULT 'Africa/Harare',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create suburbs table
CREATE TABLE IF NOT EXISTS suburbs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    zip_code VARCHAR(20),
    town_id UUID NOT NULL REFERENCES towns(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name, town_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_suburbs_town_id ON suburbs(town_id);
CREATE INDEX IF NOT EXISTS idx_towns_name ON towns(name);

-- ============================
-- Seed Zimbabwe Major Towns
-- ============================

INSERT INTO towns (name, state, country, timezone) VALUES
    ('Harare', 'Harare Province', 'Zimbabwe', 'Africa/Harare'),
    ('Bulawayo', 'Bulawayo Province', 'Zimbabwe', 'Africa/Harare'),
    ('Mutare', 'Manicaland', 'Zimbabwe', 'Africa/Harare'),
    ('Gweru', 'Midlands', 'Zimbabwe', 'Africa/Harare'),
    ('Masvingo', 'Masvingo Province', 'Zimbabwe', 'Africa/Harare'),
    ('Chinhoyi', 'Mashonaland West', 'Zimbabwe', 'Africa/Harare'),
    ('Kwekwe', 'Midlands', 'Zimbabwe', 'Africa/Harare'),
    ('Kadoma', 'Mashonaland West', 'Zimbabwe', 'Africa/Harare'),
    ('Victoria Falls', 'Matabeleland North', 'Zimbabwe', 'Africa/Harare'),
    ('Kariba', 'Mashonaland West', 'Zimbabwe', 'Africa/Harare'),
    ('Marondera', 'Mashonaland East', 'Zimbabwe', 'Africa/Harare'),
    ('Bindura', 'Mashonaland Central', 'Zimbabwe', 'Africa/Harare'),
    ('Hwange', 'Matabeleland North', 'Zimbabwe', 'Africa/Harare'),
    ('Chipinge', 'Manicaland', 'Zimbabwe', 'Africa/Harare'),
    ('Beitbridge', 'Matabeleland South', 'Zimbabwe', 'Africa/Harare')
ON CONFLICT (name) DO NOTHING;

-- ============================
-- Seed Harare Suburbs
-- ============================
INSERT INTO suburbs (name, town_id) 
SELECT s.name, t.id FROM (
    VALUES 
        ('Avondale'), ('Borrowdale'), ('Mount Pleasant'), ('Highlands'), ('Greendale'),
        ('Marlborough'), ('Mabelreign'), ('Hatfield'), ('Eastlea'), ('Belvedere'),
        ('Milton Park'), ('Newlands'), ('Alexandra Park'), ('Chisipite'), ('Glen Lorne'),
        ('Greystone Park'), ('Vainona'), ('Pomona'), ('The Grange'), ('Emerald Hill'),
        ('Waterfalls'), ('Mbare'), ('Highfield'), ('Glen Norah'), ('Budiriro'),
        ('Warren Park'), ('Kambuzuma'), ('Kuwadzana'), ('Dzivaresekwa'), ('Tynwald'),
        ('Westgate'), ('Ashdown Park'), ('Bluff Hill'), ('Gunhill'), ('Mandara'),
        ('Cranborne'), ('Sunridge'), ('Arcadia'), ('CBD'), ('Meyrick Park')
    ) AS s(name)
CROSS JOIN towns t WHERE t.name = 'Harare'
ON CONFLICT (name, town_id) DO NOTHING;

-- ============================
-- Seed Bulawayo Suburbs
-- ============================
INSERT INTO suburbs (name, town_id) 
SELECT s.name, t.id FROM (
    VALUES 
        ('Hillside'), ('Suburbs'), ('Burnside'), ('Matsheumhlope'), ('Kumalo'),
        ('Waterford'), ('Morningside'), ('Famona'), ('Riverside'), ('Bradfield'),
        ('Fourwinds'), ('Sunninghill'), ('Montrose'), ('Malindela'), ('Pumula'),
        ('Nkulumane'), ('Emganwini'), ('Cowdray Park'), ('Luveve'), ('Entumbane'),
        ('Makokoba'), ('Mzilikazi'), ('Mpopoma'), ('Barbourfields'), ('Lobengula'),
        ('Kensington'), ('Queens Park'), ('Northend'), ('Ascot'), ('CBD')
    ) AS s(name)
CROSS JOIN towns t WHERE t.name = 'Bulawayo'
ON CONFLICT (name, town_id) DO NOTHING;

-- ============================
-- Seed Mutare Suburbs
-- ============================
INSERT INTO suburbs (name, town_id) 
SELECT s.name, t.id FROM (
    VALUES 
        ('Murambi'), ('Penhalonga'), ('Palmerston'), ('Fairbridge Park'), ('Yeovil'),
        ('Greenside'), ('Darlington'), ('Morningside'), ('Utopia'), ('Zimunya'),
        ('Chikanga'), ('Dangamvura'), ('Sakubva'), ('Hobhouse'), ('Florida'),
        ('Fern Valley'), ('Tiger''s Kloof'), ('CBD')
    ) AS s(name)
CROSS JOIN towns t WHERE t.name = 'Mutare'
ON CONFLICT (name, town_id) DO NOTHING;

-- ============================  
-- Seed Gweru Suburbs
-- ============================
INSERT INTO suburbs (name, town_id) 
SELECT s.name, t.id FROM (
    VALUES 
        ('Kopje'), ('Ridgemont'), ('Ascot'), ('Nashville'), ('Mkoba'),
        ('Senga'), ('Mtapa'), ('Woodlands'), ('Ivene'), ('Southdowns'),
        ('Athlone'), ('CBD'), ('Nehanda'), ('Riverside')
    ) AS s(name)
CROSS JOIN towns t WHERE t.name = 'Gweru'
ON CONFLICT (name, town_id) DO NOTHING;

-- ============================
-- Seed Masvingo Suburbs  
-- ============================
INSERT INTO suburbs (name, town_id) 
SELECT s.name, t.id FROM (
    VALUES 
        ('Target Kopje'), ('Rhodene'), ('Mucheke'), ('Rujeko'), ('Eastvale'),
        ('Clipsham'), ('Zimre Park'), ('Hillside'), ('Morgenster'), ('Victoria Range'),
        ('CBD'), ('Chesvingo')
    ) AS s(name)
CROSS JOIN towns t WHERE t.name = 'Masvingo'
ON CONFLICT (name, town_id) DO NOTHING;

-- ============================
-- Seed Victoria Falls Suburbs
-- ============================
INSERT INTO suburbs (name, town_id) 
SELECT s.name, t.id FROM (
    VALUES 
        ('Mkhosana'), ('Chinotimba'), ('Aerodrome'), ('Big Tree'), ('Elephant Hills'),
        ('CBD'), ('Falls View')
    ) AS s(name)
CROSS JOIN towns t WHERE t.name = 'Victoria Falls'
ON CONFLICT (name, town_id) DO NOTHING;
