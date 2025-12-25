-- Bids table
CREATE TABLE IF NOT EXISTS bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID REFERENCES auctions(id) ON DELETE CASCADE,
    bidder_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    is_winning BOOLEAN DEFAULT FALSE,
    is_auto_bid BOOLEAN DEFAULT FALSE,
    max_auto_bid DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_bids_auction_id ON bids(auction_id);
CREATE INDEX IF NOT EXISTS idx_bids_bidder_id ON bids(bidder_id);
CREATE INDEX IF NOT EXISTS idx_bids_auction_amount ON bids(auction_id, amount DESC);

-- Trigger to update auction current_price and total_bids when a bid is placed
CREATE OR REPLACE FUNCTION update_auction_on_bid()
RETURNS TRIGGER AS $$
BEGIN
    -- Update auction current price and total bids
    UPDATE auctions 
    SET current_price = NEW.amount,
        total_bids = total_bids + 1,
        updated_at = NOW()
    WHERE id = NEW.auction_id;
    
    -- Mark previous winning bid as not winning
    UPDATE bids 
    SET is_winning = FALSE 
    WHERE auction_id = NEW.auction_id 
    AND id != NEW.id 
    AND is_winning = TRUE;
    
    -- Mark new bid as winning
    NEW.is_winning = TRUE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_auction_on_bid
    BEFORE INSERT ON bids
    FOR EACH ROW
    EXECUTE FUNCTION update_auction_on_bid();

-- Anti-sniping trigger: extend auction end time if bid placed in last X minutes
CREATE OR REPLACE FUNCTION anti_snipe_extension()
RETURNS TRIGGER AS $$
DECLARE
    auction_record RECORD;
    extension_minutes INT;
BEGIN
    SELECT * INTO auction_record FROM auctions WHERE id = NEW.auction_id;
    
    -- If bid is placed within anti_snipe_minutes of end time, extend auction
    IF auction_record.end_time - NOW() < (auction_record.anti_snipe_minutes || ' minutes')::INTERVAL THEN
        extension_minutes := COALESCE(auction_record.anti_snipe_minutes, 5);
        
        UPDATE auctions 
        SET end_time = end_time + (extension_minutes || ' minutes')::INTERVAL
        WHERE id = NEW.auction_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_anti_snipe
    AFTER INSERT ON bids
    FOR EACH ROW
    EXECUTE FUNCTION anti_snipe_extension();
