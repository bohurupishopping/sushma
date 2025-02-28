-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    password TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'manufacturing', 'salesperson', 'dealer')),
    phone TEXT,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create index for email lookups
CREATE INDEX idx_users_email ON users(email);

-- Create index for role-based queries
CREATE INDEX idx_users_role ON users(role);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all"
    ON users
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Users can read their own data
CREATE POLICY "users_read_own"
    ON users
    FOR SELECT
    TO authenticated
    USING (id = auth.uid());

-- Users can update their own data except role
CREATE POLICY "users_update_own"
    ON users
    FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Create audit trigger
CREATE OR REPLACE FUNCTION audit_users_changes()
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

    -- Create audit_logs table if it doesn't exist yet
    -- This is needed because the migration runs before 00010_create_audit_logs_table.sql
    CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        table_name TEXT NOT NULL,
        record_id UUID NOT NULL,
        action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
        changed_by UUID,
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        changes JSONB NOT NULL
    );

    INSERT INTO audit_logs (
        table_name,
        record_id,
        action,
        changed_by,
        changes
    ) VALUES (
        'users',
        CASE
            WHEN TG_OP = 'DELETE' THEN OLD.id
            ELSE NEW.id
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

CREATE TRIGGER users_audit
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION audit_users_changes();

-- Comments
COMMENT ON TABLE users IS 'User accounts for the manufacturing company application';
COMMENT ON COLUMN users.id IS 'Unique identifier for the user';
COMMENT ON COLUMN users.email IS 'User email address, must be unique';
COMMENT ON COLUMN users.password IS 'Hashed password';
COMMENT ON COLUMN users.role IS 'User role: admin, manufacturing, salesperson, or dealer';
COMMENT ON COLUMN users.phone IS 'User phone number';
COMMENT ON COLUMN users.preferences IS 'User preferences stored as JSONB';
COMMENT ON COLUMN users.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN users.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN users.created_by IS 'User ID who created this record';
COMMENT ON COLUMN users.updated_by IS 'User ID who last updated this record';