-- Create salespersons table
CREATE TABLE salespersons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes
CREATE INDEX idx_salespersons_user_id ON salespersons(user_id);

-- Create trigger for updated_at
CREATE TRIGGER salespersons_updated_at
    BEFORE UPDATE ON salespersons
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Enable Row Level Security
ALTER TABLE salespersons ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_salespersons"
    ON salespersons
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Salespersons can read and update their own data
CREATE POLICY "salespersons_read_own"
    ON salespersons
    FOR SELECT
    TO authenticated
    USING ((auth.jwt() ->> 'role' = 'salesperson' AND user_id = auth.uid()));

CREATE POLICY "salespersons_update_own"
    ON salespersons
    FOR UPDATE
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'salesperson' AND user_id = auth.uid())
    WITH CHECK (auth.jwt() ->> 'role' = 'salesperson' AND user_id = auth.uid());

-- Manufacturing can read all salespersons
CREATE POLICY "manufacturing_read_salespersons"
    ON salespersons
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

-- Create audit trigger
CREATE TRIGGER salespersons_audit
    AFTER INSERT OR UPDATE OR DELETE ON salespersons
    FOR EACH ROW
    EXECUTE FUNCTION audit_users_changes();

-- Comments
COMMENT ON TABLE salespersons IS 'Salesperson information for the manufacturing company';
COMMENT ON COLUMN salespersons.id IS 'Unique identifier for the salesperson';
COMMENT ON COLUMN salespersons.user_id IS 'Reference to the user account for this salesperson';
COMMENT ON COLUMN salespersons.name IS 'Salesperson name';
COMMENT ON COLUMN salespersons.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN salespersons.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN salespersons.created_by IS 'User ID who created this record';
COMMENT ON COLUMN salespersons.updated_by IS 'User ID who last updated this record';