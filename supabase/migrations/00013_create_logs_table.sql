-- Create logs table
CREATE TABLE logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type TEXT NOT NULL,
    user_id UUID REFERENCES users(id),
    description TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    details JSONB
);

-- Create indexes
CREATE INDEX idx_logs_event_type ON logs(event_type);
CREATE INDEX idx_logs_user_id ON logs(user_id);
CREATE INDEX idx_logs_timestamp ON logs(timestamp);

-- Enable Row Level Security
ALTER TABLE logs ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_logs"
    ON logs
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Manufacturing can read logs
CREATE POLICY "manufacturing_read_logs"
    ON logs
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

-- Users can read their own logs
CREATE POLICY "users_read_own_logs"
    ON logs
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Comments
COMMENT ON TABLE logs IS 'Application events for monitoring and debugging';
COMMENT ON COLUMN logs.id IS 'Unique identifier for the log entry';
COMMENT ON COLUMN logs.event_type IS 'Type of event being logged';
COMMENT ON COLUMN logs.user_id IS 'User ID associated with the event, if applicable';
COMMENT ON COLUMN logs.description IS 'Description of the event';
COMMENT ON COLUMN logs.timestamp IS 'Timestamp when the event occurred';
COMMENT ON COLUMN logs.details IS 'Additional details about the event stored as JSONB';