-- Create orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dealer_id UUID NOT NULL REFERENCES dealers(id),
    status TEXT NOT NULL CHECK (status IN ('processing', 'production', 'completed', 'canceled')),
    total_price NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE,
    version INTEGER NOT NULL DEFAULT 1
);

-- Create indexes
CREATE INDEX idx_orders_dealer_id ON orders(dealer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Create trigger for updated_at
CREATE TRIGGER orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Create trigger for version increment (optimistic locking)
CREATE OR REPLACE FUNCTION increment_version()
RETURNS TRIGGER AS $$
BEGIN
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_increment_version
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- Enable Row Level Security
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_orders"
    ON orders
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Dealers can read and update their own orders
CREATE POLICY "dealers_read_own_orders"
    ON orders
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM dealers WHERE dealers.id = orders.dealer_id AND dealers.user_id = auth.uid()))
    );

CREATE POLICY "dealers_insert_own_orders"
    ON orders
    FOR INSERT
    TO authenticated
    WITH CHECK (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM dealers WHERE dealers.id = orders.dealer_id AND dealers.user_id = auth.uid()))
    );

CREATE POLICY "dealers_update_own_orders"
    ON orders
    FOR UPDATE
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM dealers WHERE dealers.id = orders.dealer_id AND dealers.user_id = auth.uid()) AND
         status = 'processing')
    )
    WITH CHECK (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM dealers WHERE dealers.id = orders.dealer_id AND dealers.user_id = auth.uid()) AND
         status = 'processing')
    );

-- Salespersons can read orders from their dealers
CREATE POLICY "salespersons_read_dealer_orders"
    ON orders
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'salesperson' AND 
         EXISTS (SELECT 1 FROM dealers 
                 WHERE dealers.id = orders.dealer_id AND 
                       dealers.salesperson_id = (SELECT id FROM salespersons WHERE user_id = auth.uid())))
    );

-- Manufacturing can read and update order status
CREATE POLICY "manufacturing_read_orders"
    ON orders
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

CREATE POLICY "manufacturing_update_order_status"
    ON orders
    FOR UPDATE
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing')
    WITH CHECK (
        auth.jwt() ->> 'role' = 'manufacturing' AND 
        (status IN ('production', 'completed') AND 
         (SELECT status FROM orders WHERE id = orders.id) != 'canceled')
    );

-- Add soft delete function
CREATE OR REPLACE FUNCTION soft_delete_order()
RETURNS TRIGGER AS $$
BEGIN
    NEW.deleted_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_soft_delete
    BEFORE DELETE ON orders
    FOR EACH ROW
    WHEN (OLD.deleted_at IS NULL)
    EXECUTE FUNCTION soft_delete_order();

-- Create audit trigger
CREATE TRIGGER orders_audit
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION audit_users_changes();

-- Comments
COMMENT ON TABLE orders IS 'Orders placed by dealers';
COMMENT ON COLUMN orders.id IS 'Unique identifier for the order';
COMMENT ON COLUMN orders.dealer_id IS 'Reference to the dealer who placed the order';
COMMENT ON COLUMN orders.status IS 'Order status: processing, production, completed, or canceled';
COMMENT ON COLUMN orders.total_price IS 'Total price of the order';
COMMENT ON COLUMN orders.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN orders.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN orders.created_by IS 'User ID who created this record';
COMMENT ON COLUMN orders.updated_by IS 'User ID who last updated this record';
COMMENT ON COLUMN orders.deleted_at IS 'Timestamp when the order was soft-deleted, NULL if active';
COMMENT ON COLUMN orders.version IS 'Version number for optimistic locking';