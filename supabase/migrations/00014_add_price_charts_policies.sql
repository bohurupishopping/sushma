-- Add dealer and salesperson policies for price_charts table

-- Dealers can read their assigned price charts
CREATE POLICY "dealers_read_assigned_price_charts"
    ON price_charts
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'dealer' AND 
         EXISTS (SELECT 1 FROM dealers WHERE dealers.price_chart_id = price_charts.id AND dealers.user_id = auth.uid()))
    );

-- Salespersons can read price charts assigned to their dealers
CREATE POLICY "salespersons_read_dealer_price_charts"
    ON price_charts
    FOR SELECT
    TO authenticated
    USING (
        (auth.jwt() ->> 'role' = 'salesperson' AND 
         EXISTS (SELECT 1 FROM dealers 
                 WHERE dealers.price_chart_id = price_charts.id AND 
                       dealers.salesperson_id = (SELECT id FROM salespersons WHERE user_id = auth.uid())))
    );

-- Comments
COMMENT ON POLICY "dealers_read_assigned_price_charts" ON price_charts IS 'Allows dealers to read their assigned price charts';
COMMENT ON POLICY "salespersons_read_dealer_price_charts" ON price_charts IS 'Allows salespersons to read price charts assigned to their dealers';