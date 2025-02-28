-- Create price_charts table
CREATE TABLE price_charts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes
CREATE INDEX idx_price_charts_code ON price_charts(code);

-- Create trigger for updated_at
CREATE TRIGGER price_charts_updated_at
    BEFORE UPDATE ON price_charts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Enable Row Level Security
ALTER TABLE price_charts ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_price_charts"
    ON price_charts
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Manufacturing can read all price charts
CREATE POLICY "manufacturing_read_price_charts"
    ON price_charts
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

-- Note: Dealer and Salesperson policies will be added in a later migration after dealers table is created

-- Create audit trigger
CREATE TRIGGER price_charts_audit
    AFTER INSERT OR UPDATE OR DELETE ON price_charts
    FOR EACH ROW
    EXECUTE FUNCTION audit_users_changes();

-- Comments
COMMENT ON TABLE price_charts IS 'Price charts for dealers with custom pricing';
COMMENT ON COLUMN price_charts.id IS 'Unique identifier for the price chart';
COMMENT ON COLUMN price_charts.code IS 'Unique code for the price chart';
COMMENT ON COLUMN price_charts.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN price_charts.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN price_charts.created_by IS 'User ID who created this record';
COMMENT ON COLUMN price_charts.updated_by IS 'User ID who last updated this record';