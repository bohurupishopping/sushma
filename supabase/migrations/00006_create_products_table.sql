-- Create products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    sku TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_category ON products(category);

-- Create trigger for updated_at
CREATE TRIGGER products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Enable Row Level Security
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_products"
    ON products
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- All authenticated users can read active products
CREATE POLICY "authenticated_read_products"
    ON products
    FOR SELECT
    TO authenticated
    USING (deleted_at IS NULL);

-- Manufacturing can read all products including deleted ones
CREATE POLICY "manufacturing_read_all_products"
    ON products
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

-- Add soft delete function
CREATE OR REPLACE FUNCTION soft_delete_product()
RETURNS TRIGGER AS $$
BEGIN
    NEW.deleted_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_soft_delete
    BEFORE DELETE ON products
    FOR EACH ROW
    WHEN (OLD.deleted_at IS NULL)
    EXECUTE FUNCTION soft_delete_product();

-- Create audit function for products
CREATE OR REPLACE FUNCTION audit_products_changes()
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
        'products',
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

-- Create audit trigger
CREATE TRIGGER products_audit
    AFTER INSERT OR UPDATE OR DELETE ON products
    FOR EACH ROW
    EXECUTE FUNCTION audit_products_changes();

-- Comments
COMMENT ON TABLE products IS 'Products available for ordering';
COMMENT ON COLUMN products.id IS 'Unique identifier for the product';
COMMENT ON COLUMN products.name IS 'Product name';
COMMENT ON COLUMN products.description IS 'Product description';
COMMENT ON COLUMN products.category IS 'Product category';
COMMENT ON COLUMN products.sku IS 'Stock keeping unit - product identifier';
COMMENT ON COLUMN products.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN products.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN products.created_by IS 'User ID who created this record';
COMMENT ON COLUMN products.updated_by IS 'User ID who last updated this record';
COMMENT ON COLUMN products.deleted_at IS 'Timestamp when the product was soft-deleted, NULL if active';