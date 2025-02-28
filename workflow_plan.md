**The workflow describes the lifecycle of key activities in the app**

Dealer Management: Admin creates and manages dealers.
Pricing Setup: Admin defines custom pricing for dealers.
Order Creation: Dealers place orders with custom pricing.
Order Processing: Admin and Manufacturing manage order statuses; Salespersons monitor progress.
Banking: Transactions are recorded and tracked.
Auditing & Logging: Changes and events are logged automatically.

1. Dealer Management Workflow
Goal: Admin sets up and manages dealers and salespersons.

Steps:
Admin logs in (users table with role = 'admin').
Create Salesperson:
Admin adds a new salesperson to salespersons (e.g., name, links to a new users entry with role = 'salesperson').
created_by and created_at are set automatically.
Create Dealer:
Admin adds a new dealer to dealers (e.g., name, dealer_code, address, contact).
Links to a new users entry with role = 'dealer'.
Assigns a salesperson_id from salespersons.
Sets price_chart_id (created in Pricing Setup).
created_by and created_at are recorded.
Update/Delete Dealer:
Admin edits dealer details (e.g., changes address) → updated_by and updated_at updated.
Soft delete if needed → deleted_at set (no permanent deletion).
Audit: All actions (insert, update, delete) logged in audit_logs with changed_by and changes.
2. Pricing Setup Workflow
Goal: Admin configures custom pricing for dealers.

Steps:
Admin creates a price chart:
Adds a new entry to price_charts (e.g., code = 'PC001') → created_by and created_at set.
Add products and prices:
Admin adds products to products (name, category, SKU) if not already present.
Adds entries to price_chart_items (links price_chart_id, product_id, sets price) → created_by set.
Assign to dealer:
Updates dealers.price_chart_id with the new price_charts.id.
Update pricing:
Admin modifies price in price_chart_items → updated_by and updated_at updated.
Audit: Changes logged in audit_logs.
3. Order Creation Workflow
Goal: Dealers place orders with custom pricing.

Steps:
Dealer logs in (users with role = 'dealer').
Select products:
Dealer views available products from products.
Selects a product → system fetches price from price_chart_items using dealers.price_chart_id.
Enter quantity:
Dealer inputs quantity → system calculates total_price (price × quantity).
Submit order:
New entry in orders:
dealer_id = dealer’s ID.
status = 'processing' (default).
total_price = calculated total.
created_by = dealer’s user_id.
Add items to order_items:
order_id = new order’s ID.
product_id, quantity, price (locked at order time).
created_by = dealer’s user_id.
Log: Order creation logged in logs (e.g., event_type = 'order_created').
Audit: Insert logged in audit_logs.
4. Order Processing Workflow
Goal: Orders are tracked and updated by Admin, Manufacturing, and Salespersons.

Steps:
Dealer views/cancels:
Dealer checks orders (filtered by dealer_id).
Cancels order → updates status to 'canceled' → updated_by set.
Salesperson monitors:
Salesperson views orders for their dealers (filtered by dealers.salesperson_id).
Read-only access, no updates.
Admin updates:
Views all orders in a table.
Edits details (e.g., total_price) or deletes (sets deleted_at) → version incremented, updated_by set.
Changes status (e.g., 'processing' → 'production' → 'completed').
Manufacturing tracks (optional):
Views orders with status = 'production' for processing (expandable).
Concurrency check:
Updates to orders or transactions check version to prevent conflicts.
Audit & Log:
Updates/deletes logged in audit_logs.
Status changes logged in logs (e.g., event_type = 'order_status_updated').
5. Banking Workflow
Goal: Transactions are recorded and monitored.

Steps:
Admin records payment:
Adds a new entry to transactions:
dealer_id, order_id (optional), amount, date, type (e.g., 'payment'), currency.
Calculates remaining_due based on orders.total_price and prior transactions.
created_by = admin’s user_id.
Dealer views transactions:
Sees all transactions filtered by dealer_id (purchase date, amount, remaining due).
Update transaction (Admin only):
Modifies amount or remaining_due → version incremented, updated_by set.
Audit: Inserts/updates logged in audit_logs.
6. Auditing & Logging Workflow
Goal: Track changes and events for accountability and debugging.

Steps:
Automatic auditing:
Any insert, update, or delete in key tables (orders, dealers, etc.) triggers an entry in audit_logs:
table_name, record_id, action, changed_by, changes (JSON of old vs. new values).
Event logging:
App events (e.g., login, order creation) logged in logs:
event_type, user_id, description, timestamp.
Admin review:
Admin queries audit_logs and logs for reports or troubleshooting.
Role-Based Access Summary
Dealer:
Create/cancel orders (orders, order_items).
View orders and transactions (orders, transactions filtered by dealer_id).
Salesperson:
View orders for their dealers (orders via dealers.salesperson_id).
Admin:
Full control: manage dealers, salespersons, price_charts, products, orders, transactions, settings.
Update statuses, edit/delete records.
Manufacturing (expandable):
View orders with status = 'production'.
Key Features in Action
Order Creation: Dealers fetch prices from price_chart_items, submit to orders and order_items.
Custom Pricing: price_charts and price_chart_items ensure dealer-specific pricing.
Concurrency: version fields in orders and transactions prevent overwrite conflicts.
Scalability: Indexes and partitioning plans handle growth in orders and transactions.
Security: Auditing (audit_logs) and soft deletes (deleted_at) ensure accountability and data retention.