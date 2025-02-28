-- Create price_chart_items table
CREATE TABLE price_chart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    price_chart_id UUID NOT NULL REFERENCES price_charts(id),
    product_id UUID NOT NULL REFERENCES products(id),
    price NUMERIC NOT NULL CHECK (price > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes
CREATE INDEX idx_price_chart_items_price_chart_id ON price_chart_items(price_chart_id);
CREATE INDEX idx_price_chart_items_product_id ON price_chart_items(product_id);
CREATE UNIQUE INDEX idx_price_chart_items_unique ON price_chart_items(price_chart_id, product_id);

-- Create trigger for updated_at
CREATE TRIGGER price_chart_items_updated_at
    BEFORE UPDATE ON price_chart_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Enable Row Level Security
ALTER TABLE price_chart_items ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_price_chart_items"
    ON price_chart_items
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Dealers can read their assigned price chart items
CREATE POLICY "dealers_read_assigned_price_chart_items"
    ON price_chart_items
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM dealers WHERE dealers.price_chart_id = price_chart_items.price_chart_id AND dealers.user_id = auth.uid()))
    );

-- Salespersons can read price chart items assigned to their dealers
CREATE POLICY "salespersons_read_dealer_price_chart_items"
    ON price_chart_items
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'salesperson' AND 
         EXISTS (SELECT 1 FROM dealers 
                 WHERE dealers.price_chart_id = price_chart_items.price_chart_id AND 
                       dealers.salesperson_id = (SELECT id FROM salespersons WHERE user_id = auth.uid())))
    );

-- Manufacturing can read all price chart items
CREATE POLICY "manufacturing_read_price_chart_items"
    ON price_chart_items
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

-- Create audit trigger
CREATE TRIGGER price_chart_items_audit
    AFTER INSERT OR UPDATE OR DELETE ON price_chart_items
    FOR EACH ROW
    EXECUTE FUNCTION audit_users_changes();

-- Comments
COMMENT ON TABLE price_chart_items IS 'Custom product prices for each price chart';
COMMENT ON COLUMN price_chart_items.id IS 'Unique identifier for the price chart item';
COMMENT ON COLUMN price_chart_items.price_chart_id IS 'Reference to the price chart';
COMMENT ON COLUMN price_chart_items.product_id IS 'Reference to the product';
COMMENT ON COLUMN price_chart_items.price IS 'Custom price for the product in this price chart';
COMMENT ON COLUMN price_chart_items.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN price_chart_items.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN price_chart_items.created_by IS 'User ID who created this record';
COMMENT ON COLUMN price_chart_items.updated_by IS 'User ID who last updated this record';