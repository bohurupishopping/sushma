Overview
This database supports a multi-role application for a manufacturing company, connecting a single dataset across separate apps for:

Dealers: Place and manage orders with custom pricing, view transactions.
Salespersons: View orders from their assigned dealers.
Admins: Full control over orders, dealers, pricing, and transactions.
Manufacturing Department: Access to order statuses (expandable).
The structure leverages Supabase's features (e.g., UUIDs, row-level security) and includes enhancements such as indexing, constraints, auditing, soft deletes, optimistic locking, and partitioning plans.

Tables
1. users
Purpose: Manages user authentication and roles.
Fields:
id (UUID, Primary Key)
email (text, unique)
password (text, hashed)
role (text: 'admin', 'manufacturing', 'salesperson', 'dealer')
phone (text)
preferences (jsonb)
created_at (timestamp)
updated_at (timestamp)
created_by (UUID, Foreign Key to users.id)
updated_by (UUID, Foreign Key to users.id)
2. dealers
Purpose: Stores dealer information, linking to users, price charts, and salespersons.
Fields:
id (UUID, Primary Key)
user_id (UUID, Foreign Key to users.id)
name (text)
dealer_code (text, unique)
address (text)
contact (text)
price_chart_id (UUID, Foreign Key to price_charts.id)
salesperson_id (UUID, Foreign Key to salespersons.id)
created_at (timestamp)
updated_at (timestamp)
created_by (UUID, Foreign Key to users.id)
updated_by (UUID, Foreign Key to users.id)
deleted_at (timestamp, nullable)
3. salespersons
Purpose: Stores salesperson information, linking to users.
Fields:
id (UUID, Primary Key)
user_id (UUID, Foreign Key to users.id)
name (text)
created_at (timestamp)
updated_at (timestamp)
created_by (UUID, Foreign Key to users.id)
updated_by (UUID, Foreign Key to users.id)
4. price_charts
Purpose: Defines unique price charts for dealers.
Fields:
id (UUID, Primary Key)
code (text, unique)
created_at (timestamp)
updated_at (timestamp)
created_by (UUID, Foreign Key to users.id)
updated_by (UUID, Foreign Key to users.id)
5. products
Purpose: Lists all products available for ordering.
Fields:
id (UUID, Primary Key)
name (text)
description (text)
category (text)
sku (text)
created_at (timestamp)
updated_at (timestamp)
created_by (UUID, Foreign Key to users.id)
updated_by (UUID, Foreign Key to users.id)
deleted_at (timestamp, nullable)
6. price_chart_items
Purpose: Stores custom product prices for each price chart.
Fields:
id (UUID, Primary Key)
price_chart_id (UUID, Foreign Key to price_charts.id)
product_id (UUID, Foreign Key to products.id)
price (numeric, CHECK (price > 0))
created_at (timestamp)
updated_at (timestamp)
created_by (UUID, Foreign Key to users.id)
updated_by (UUID, Foreign Key to users.id)
7. orders
Purpose: Stores orders placed by dealers.
Fields:
id (UUID, Primary Key)
dealer_id (UUID, Foreign Key to dealers.id)
status (text: 'processing', 'production', 'completed', 'canceled')
total_price (numeric)
created_at (timestamp)
updated_at (timestamp)
created_by (UUID, Foreign Key to users.id)
updated_by (UUID, Foreign Key to users.id)
deleted_at (timestamp, nullable)
version (integer)
8. order_items
Purpose: Stores individual items within each order.
Fields:
id (UUID, Primary Key)
order_id (UUID, Foreign Key to orders.id)
product_id (UUID, Foreign Key to products.id)
quantity (integer)
price (numeric)
created_at (timestamp)
updated_at (timestamp)
created_by (UUID, Foreign Key to users.id)
updated_by (UUID, Foreign Key to users.id)
9. transactions
Purpose: Tracks financial transactions for dealers.
Fields:
id (UUID, Primary Key)
dealer_id (UUID, Foreign Key to dealers.id)
order_id (UUID, Foreign Key to orders.id, nullable)
amount (numeric, CHECK (amount > 0))
date (timestamp)
remaining_due (numeric)
type (text)
currency (text)
created_at (timestamp)
updated_at (timestamp)
created_by (UUID, Foreign Key to users.id)
updated_by (UUID, Foreign Key to users.id)
version (integer)
10. audit_logs
Purpose: Records changes to key tables for auditing.
Fields:
id (UUID, Primary Key)
table_name (text)
record_id (UUID)
action (text: 'INSERT', 'UPDATE', 'DELETE')
changed_by (UUID, Foreign Key to users.id)
timestamp (timestamp)
changes (jsonb)
11. settings
Purpose: Stores application-wide configurations.
Fields:
key (text, unique)
value (text or jsonb)
description (text)
12. logs
Purpose: Captures application events for monitoring and debugging.
Fields:
id (UUID, Primary Key)
event_type (text)
user_id (UUID, Foreign Key to users.id)
description (text)
timestamp (timestamp)
Relationships
users ↔ dealers (1:1 via user_id)
users ↔ salespersons (1:1 via user_id)
dealers → price_charts (N:1 via price_chart_id)
dealers → salespersons (N:1 via salesperson_id)
price_charts → price_chart_items (1:N via price_chart_id)
products → price_chart_items (1:N via product_id)
dealers → orders (1:N via dealer_id)
orders → order_items (1:N via order_id)
orders → transactions (1:N via order_id)
dealers → transactions (1:N via dealer_id)
Indexes
To improve query performance:

orders: dealer_id, status
order_items: order_id, product_id
transactions: dealer_id, order_id
price_chart_items: price_chart_id, product_id
Constraints
Foreign Key Constraints: Enforced across all relationships to maintain referential integrity.
Unique Constraints:
email in users
dealer_code in dealers
code in price_charts
key in settings
Check Constraints:
price > 0 in price_chart_items
amount > 0 in transactions
Additional Features
Soft Deletes: Implemented with deleted_at (timestamp, nullable) in orders, dealers, and products to retain historical data without permanent deletion.
Auditing:
created_by and updated_by fields (Foreign Key to users.id) in all tables to track who made changes.
audit_logs table to log insertions, updates, and deletions with detailed change history.
Optimistic Locking: version (integer) in orders and transactions to prevent concurrent modification conflicts.
Partitioning: Plan to partition orders and transactions by date or dealer_id as the database grows, ensuring scalability.
Application Logging: logs table to capture application events (e.g., user actions, errors) for monitoring and debugging.
Flexible Configurations: settings table with a key-value structure (using jsonb for complex values) to store application-wide settings.
Implementation Notes
Supabase Compatibility: Uses UUIDs as primary keys and timestamp fields, aligning with Supabase's conventions. Row-level security (RLS) can be applied based on role in users to restrict access.
Scalability: Indexes and partitioning plans ensure performance as data volume increases.
Security: Passwords are hashed, and auditing tracks all changes for accountability.
Maintainability: Soft deletes and detailed logging simplify data recovery and troubleshooting.

