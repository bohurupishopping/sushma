-- Create order_items table
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id),
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price NUMERIC NOT NULL CHECK (price > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Create indexes
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Create trigger for updated_at
CREATE TRIGGER order_items_updated_at
    BEFORE UPDATE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Enable Row Level Security
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_order_items"
    ON order_items
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Dealers can read and manage their own order items
CREATE POLICY "dealers_read_own_order_items"
    ON order_items
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM orders 
                 WHERE orders.id = order_items.order_id AND
                 EXISTS (SELECT 1 FROM dealers 
                         WHERE dealers.id = orders.dealer_id AND 
                         dealers.user_id = auth.uid())))
    );

CREATE POLICY "dealers_insert_own_order_items"
    ON order_items
    FOR INSERT
    TO authenticated
    WITH CHECK (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM orders 
                 WHERE orders.id = order_items.order_id AND
                 orders.status = 'processing' AND
                 EXISTS (SELECT 1 FROM dealers 
                         WHERE dealers.id = orders.dealer_id AND 
                         dealers.user_id = auth.uid())))
    );

CREATE POLICY "dealers_update_own_order_items"
    ON order_items
    FOR UPDATE
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM orders 
                 WHERE orders.id = order_items.order_id AND
                 orders.status = 'processing' AND
                 EXISTS (SELECT 1 FROM dealers 
                         WHERE dealers.id = orders.dealer_id AND 
                         dealers.user_id = auth.uid())))
    )
    WITH CHECK (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM orders 
                 WHERE orders.id = order_items.order_id AND
                 orders.status = 'processing' AND
                 EXISTS (SELECT 1 FROM dealers 
                         WHERE dealers.id = orders.dealer_id AND 
                         dealers.user_id = auth.uid())))
    );

-- Salespersons can read order items from their dealers
CREATE POLICY "salespersons_read_dealer_order_items"
    ON order_items
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'salesperson' AND 
         EXISTS (SELECT 1 FROM orders 
                 WHERE orders.id = order_items.order_id AND
                 EXISTS (SELECT 1 FROM dealers 
                         WHERE dealers.id = orders.dealer_id AND 
                         dealers.salesperson_id = (SELECT id FROM salespersons WHERE user_id = auth.uid()))))
    );

-- Manufacturing can read all order items
CREATE POLICY "manufacturing_read_order_items"
    ON order_items
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

-- Create audit trigger
CREATE TRIGGER order_items_audit
    AFTER INSERT OR UPDATE OR DELETE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION audit_users_changes();

-- Comments
COMMENT ON TABLE order_items IS 'Individual items within each order';
COMMENT ON COLUMN order_items.id IS 'Unique identifier for the order item';
COMMENT ON COLUMN order_items.order_id IS 'Reference to the order';
COMMENT ON COLUMN order_items.product_id IS 'Reference to the product';
COMMENT ON COLUMN order_items.quantity IS 'Quantity of the product ordered';
COMMENT ON COLUMN order_items.price IS 'Price of the product at the time of order';
COMMENT ON COLUMN order_items.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN order_items.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN order_items.created_by IS 'User ID who created this record';
COMMENT ON COLUMN order_items.updated_by IS 'User ID who last updated this record';