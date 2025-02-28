-- Create settings table
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create trigger for updated_at
CREATE TRIGGER settings_updated_at
    BEFORE UPDATE ON settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Enable Row Level Security
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_settings"
    ON settings
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- All authenticated users can read settings
CREATE POLICY "authenticated_read_settings"
    ON settings
    FOR SELECT
    TO authenticated
    USING (true);

-- Create audit function for settings
CREATE OR REPLACE FUNCTION audit_settings_changes()
RETURNS TRIGGER AS $$
DECLARE
    old_data jsonb := null;
    new_data jsonb := null;
BEGIN
    -- Handle different operations with proper NULL checks
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        new_data := to_jsonb(NEW);
    END IF;
    
    IF (TG_OP = 'UPDATE' OR TG_OP = 'DELETE') THEN
        old_data := to_jsonb(OLD);
    END IF;

    INSERT INTO audit_logs (
        table_name,
        record_id,
        action,
        changed_by,
        changes
    ) VALUES (
        'settings',
        CASE
            WHEN TG_OP = 'DELETE' THEN OLD.key::uuid
            ELSE NEW.key::uuid
        END,
        TG_OP,
        CASE
            WHEN TG_OP = 'DELETE' THEN auth.uid()
            WHEN TG_OP = 'INSERT' THEN NEW.created_by
            WHEN TG_OP = 'UPDATE' THEN NEW.updated_by
            ELSE NULL
        END,
        jsonb_build_object(
            'old_data', old_data,
            'new_data', new_data
        )
    );
    
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create audit trigger
CREATE TRIGGER settings_audit
    AFTER INSERT OR UPDATE OR DELETE ON settings
    FOR EACH ROW
    EXECUTE FUNCTION audit_settings_changes();

-- Comments
COMMENT ON TABLE settings IS 'Application-wide configurations';
COMMENT ON COLUMN settings.key IS 'Unique key for the setting';
COMMENT ON COLUMN settings.value IS 'Value of the setting stored as JSONB';
COMMENT ON COLUMN settings.description IS 'Description of the setting';
COMMENT ON COLUMN settings.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN settings.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN settings.created_by IS 'User ID who created this record';
COMMENT ON COLUMN settings.updated_by IS 'User ID who last updated this record';