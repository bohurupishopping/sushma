-- Create transactions table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dealer_id UUID NOT NULL REFERENCES dealers(id),
    order_id UUID REFERENCES orders(id),
    amount NUMERIC NOT NULL CHECK (amount > 0),
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    remaining_due NUMERIC NOT NULL,
    type TEXT NOT NULL,
    currency TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    version INTEGER NOT NULL DEFAULT 1
);

-- Create indexes
CREATE INDEX idx_transactions_dealer_id ON transactions(dealer_id);
CREATE INDEX idx_transactions_order_id ON transactions(order_id);
CREATE INDEX idx_transactions_date ON transactions(date);

-- Create trigger for updated_at
CREATE TRIGGER transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Create trigger for version increment (optimistic locking)
CREATE TRIGGER transactions_increment_version
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION increment_version();

-- Enable Row Level Security
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Admin can do everything
CREATE POLICY "admins_all_transactions"
    ON transactions
    FOR ALL
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Dealers can read their own transactions
CREATE POLICY "dealers_read_own_transactions"
    ON transactions
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM dealers WHERE dealers.id = transactions.dealer_id AND dealers.user_id = auth.uid()))
    );

-- Salespersons can read transactions from their dealers
CREATE POLICY "salespersons_read_dealer_transactions"
    ON transactions
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'salesperson' AND 
         EXISTS (SELECT 1 FROM dealers 
                 WHERE dealers.id = transactions.dealer_id AND 
                       dealers.salesperson_id = (SELECT id FROM salespersons WHERE user_id = auth.uid())))
    );

-- Manufacturing can read all transactions
CREATE POLICY "manufacturing_read_transactions"
    ON transactions
    FOR SELECT
    TO authenticated
    USING (auth.jwt() ->> 'role' = 'manufacturing');

-- Create audit trigger
CREATE TRIGGER transactions_audit
    AFTER INSERT OR UPDATE OR DELETE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION audit_users_changes();

-- Comments
COMMENT ON TABLE transactions IS 'Financial transactions for dealers';
COMMENT ON COLUMN transactions.id IS 'Unique identifier for the transaction';
COMMENT ON COLUMN transactions.dealer_id IS 'Reference to the dealer';
COMMENT ON COLUMN transactions.order_id IS 'Reference to the order (optional)';
COMMENT ON COLUMN transactions.amount IS 'Transaction amount';
COMMENT ON COLUMN transactions.date IS 'Transaction date';
COMMENT ON COLUMN transactions.remaining_due IS 'Remaining amount due after this transaction';
COMMENT ON COLUMN transactions.type IS 'Transaction type';
COMMENT ON COLUMN transactions.currency IS 'Transaction currency';
COMMENT ON COLUMN transactions.created_at IS 'Timestamp when the record was created';
COMMENT ON COLUMN transactions.updated_at IS 'Timestamp when the record was last updated';
COMMENT ON COLUMN transactions.created_by IS 'User ID who created this record';
COMMENT ON COLUMN transactions.updated_by IS 'User ID who last updated this record';
COMMENT ON COLUMN transactions.version IS 'Version number for optimistic locking';