-- Create dealers table
CREATE TABLE dealers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    name TEXT NOT NULL,
    dealer_code TEXT NOT NULL UNIQUE,
    address TEXT,
    contact TEXT,
    price_chart_id UUID REFERENCES price_charts(id),
    salesperson_id UUID REFERENCES salespersons(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes
CREATE INDEX idx_dealers_user_id ON dealers(user_id);
CREATE INDEX idx_dealers_price_chart_id ON dealers(price_chart_id);
CREATE INDEX idx_dealers_salesperson_id ON dealers(salesperson_id);
CREATE INDEX idx_dealers_dealer_code ON dealers(dealer_code);

-- Create trigger for updated_at
CREATE TRIGGER dealers_updated_at
    BEFORE UPDATE ON dealers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Enable Row Level Security
ALTER TABLE dealers ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_dealers"
    ON dealers
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Dealers can read and update their own data
CREATE POLICY "dealers_read_own"
    ON dealers
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'dealer' AND user_id = auth.uid()) OR
        (auth.jwt() ->> 'role' = 'salesperson' AND salesperson_id = (SELECT id FROM salespersons WHERE user_id = auth.uid()))
    );

CREATE POLICY "dealers_update_own"
    ON dealers
    FOR UPDATE
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'dealer' AND user_id = auth.uid())
    WITH CHECK (auth.jwt() ->> 'role' = 'dealer' AND user_id = auth.uid());

-- Manufacturing can read all dealers
CREATE POLICY "manufacturing_read_dealers"
    ON dealers
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

-- Create audit trigger
CREATE TRIGGER dealers_audit
    AFTER INSERT OR UPDATE OR DELETE ON dealers
    FOR EACH ROW
    EXECUTE FUNCTION audit_users_changes();

-- Add soft delete function
CREATE OR REPLACE FUNCTION soft_delete_dealer()
RETURNS TRIGGER AS $$
BEGIN
    NEW.deleted_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dealers_soft_delete
    BEFORE DELETE ON dealers
    FOR EACH ROW
    WHEN (OLD.deleted_at IS NULL)
    EXECUTE FUNCTION soft_delete_dealer();

-- Comments
COMMENT ON TABLE dealers IS 'Dealer information for the manufacturing company';
COMMENT ON COLUMN dealers.id IS 'Unique identifier for the dealer';
COMMENT ON COLUMN dealers.user_id IS 'Reference to the user account for this dealer';
COMMENT ON COLUMN dealers.name IS 'Dealer name';
COMMENT ON COLUMN dealers.dealer_code IS 'Unique dealer code for identification';
COMMENT ON COLUMN dealers.address IS 'Dealer physical address';
COMMENT ON COLUMN dealers.contact IS 'Dealer contact information';
COMMENT ON COLUMN dealers.price_chart_id IS 'Reference to the price chart assigned to this dealer';
COMMENT ON COLUMN dealers.salesperson_id IS 'Reference to the salesperson assigned to this dealer';
COMMENT ON COLUMN dealers.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN dealers.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN dealers.created_by IS 'User ID who created this record';
COMMENT ON COLUMN dealers.updated_by IS 'User ID who last updated this record';
COMMENT ON COLUMN dealers.deleted_at IS 'Timestamp when the dealer was soft-deleted, NULL if active';