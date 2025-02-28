-- Create audit_logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    changed_by UUID REFERENCES users(id),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changes JSONB NOT NULL
);

-- Create indexes
CREATE INDEX idx_audit_logs_table_name ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_record_id ON audit_logs(record_id);
CREATE INDEX idx_audit_logs_changed_by ON audit_logs(changed_by);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);

-- Enable Row Level Security
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_audit_logs"
    ON audit_logs
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Manufacturing can read audit logs
CREATE POLICY "manufacturing_read_audit_logs"
    ON audit_logs
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

-- Comments
COMMENT ON TABLE audit_logs IS 'Records changes to key tables for auditing';
COMMENT ON COLUMN audit_logs.id IS 'Unique identifier for the audit log entry';
COMMENT ON COLUMN audit_logs.table_name IS 'Name of the table that was changed';
COMMENT ON COLUMN audit_logs.record_id IS 'ID of the record that was changed';
COMMENT ON COLUMN audit_logs.action IS 'Type of action: INSERT, UPDATE, or DELETE';
COMMENT ON COLUMN audit_logs.changed_by IS 'User ID who made the change';
COMMENT ON COLUMN audit_logs.timestamp IS 'Timestamp when the change occurred';
COMMENT ON COLUMN audit_logs.changes IS 'JSON representation of the changes made';