-- Lab 01: Views and Materialized Views
-- Estimated Time: 90 minutes

-- ==========================================
-- Exercise 1: Simple Views
-- ==========================================

-- 1.1: Create customer_info view
-- TODO: Create a view showing customer ID, first name, last name, email, full address (address, city, country), and active status.
CREATE OR REPLACE VIEW customer_info AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    a.address,
    ci.city,
    co.country,
    c.activebool AS is_active
FROM
    customer c
JOIN
    address a ON c.address_id = a.address_id
JOIN
    city ci ON a.city_id = ci.city_id
JOIN
    country co ON ci.country_id = co.country_id;

-- Verify the view was created successfully
SELECT schemaname, viewname, viewowner
FROM pg_views
WHERE viewname = 'customer_info';



-- 1.2: Create film_catalog view
-- TODO: Create a view that shows film title, description, release year, rating, and length in a readable format.
CREATE OR REPLACE VIEW film_catalog AS
SELECT
    title,
    description,
    release_year,
    rating,
    length || ' min' AS duration
FROM
    film;

-- Test queries for Exercise 1:
SELECT * FROM customer_info LIMIT 3;
SELECT * FROM film_catalog WHERE rating = 'G' LIMIT 3;


-- ==========================================
-- Exercise 2: Updatable Views
-- ==========================================
-- An updatable view is a view that allows INSERT, UPDATE, and DELETE operations.
-- For a view to be updatable, it must generally adhere to these rules:
-- 1. The view must reference only one table in its FROM clause.
-- 2. The view must not contain GROUP BY, HAVING, LIMIT, DISTINCT, or window functions.
-- 3. The select list must not contain aggregates or subqueries.

-- 2.1: Create a simple, updatable view for active customers in store 1
-- TODO: Create a view that only shows the customer_id, first_name, last_name, and email for active customers at store_id 1.
CREATE OR REPLACE VIEW store_1_active_customers AS
SELECT
    customer_id,
    first_name,
    last_name,
    email
FROM
    customer
WHERE
    store_id = 1 AND activebool = true;

-- 2.2: Test the updatability of the view
-- TODO: Write an UPDATE statement to change the email address of a customer through the view.
-- First, let's identify a valid customer in this view
SELECT customer_id, first_name, last_name, email 
FROM store_1_active_customers 
LIMIT 3;

-- Now update using the first available customer
UPDATE store_1_active_customers
SET email = 'updated.email@sakilacustomer.org'
WHERE customer_id = (SELECT MIN(customer_id) FROM store_1_active_customers);

-- Verify the change in the base table
SELECT customer_id, email 
FROM customer 
WHERE customer_id = (SELECT MIN(customer_id) FROM store_1_active_customers);


-- ==========================================
-- Exercise 3: Data Integrity with CHECK OPTION
-- ==========================================
-- The WITH CHECK OPTION clause ensures that all rows inserted or updated through the view
-- must conform to the view's WHERE clause conditions.

-- 3.1: Create a secure updatable view with a check option
-- TODO: Create a view for customers of store_id 2, including the store_id column.
-- Use WITH LOCAL CHECK OPTION to prevent rows from being moved out of the view's scope.
CREATE OR REPLACE VIEW store_2_customers_secure AS
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    store_id
FROM
    customer
WHERE
    store_id = 2
WITH LOCAL CHECK OPTION;

-- 3.2: Test the check option
-- This update should SUCCEED because it doesn't violate the `store_id = 2` condition.
UPDATE store_2_customers_secure
SET email = 'patricia.johnson.new@sakilacustomer.org'
WHERE customer_id = (SELECT MIN(customer_id) FROM store_2_customers_secure);
  
-- 3.3: Test the constraint violation
-- This update should FAIL with error: "new row violates check option for view"
-- because it attempts to change the store_id to a value (1) that doesn't meet the view's WHERE clause.
-- TODO: Uncomment the following lines and run to observe the error:
/*
UPDATE store_2_customers_secure
SET store_id = 1
WHERE customer_id = (SELECT MIN(customer_id) FROM store_2_customers_secure);
*/

-- Expected Error Message:
-- ERROR: new row violates check option for view "store_2_customers_secure"
-- DETAIL: Failing row contains (customer_id, ..., store_id=1, ...)


-- ==========================================
-- Exercise 4: Complex Multi-table Views
-- ==========================================

-- 4.1: Create rental_details view
-- TODO: Create a view that joins rental, inventory, film, and customer to show rental date,
-- film title, customer name, and return date.
CREATE OR REPLACE VIEW rental_details AS
SELECT
    r.rental_id,
    r.rental_date,
    r.return_date,
    c.first_name || ' ' || c.last_name AS customer_name,
    f.title
FROM
    rental r
JOIN
    inventory i ON r.inventory_id = i.inventory_id
JOIN
    film f ON i.film_id = f.film_id
JOIN
    customer c ON r.customer_id = c.customer_id;

-- Test query for Exercise 4:
SELECT * FROM rental_details WHERE rental_date > '2005-07-01' LIMIT 5;


-- ==========================================
-- Exercise 5: Materialized Views
-- ==========================================

-- 5.1: Create film_stats materialized view
-- TODO: Create a materialized view that stores statistics for each film category,
-- including the number of films, average rental rate, and average length.
CREATE MATERIALIZED VIEW film_stats AS
SELECT
    c.name AS category,
    COUNT(f.film_id) AS total_films,
    ROUND(AVG(f.rental_rate)::numeric, 2) AS avg_rental_rate,
    ROUND(AVG(f.length)::numeric, 2) AS avg_length
FROM
    film_category fc
JOIN
    film f ON fc.film_id = f.film_id
JOIN
    category c ON fc.category_id = c.category_id
GROUP BY
    c.name;

-- Test query for Exercise 5:
-- Note: You must refresh the materialized view before querying it for the first time.
REFRESH MATERIALIZED VIEW film_stats;
SELECT * FROM film_stats ORDER BY total_films DESC;


-- ==========================================
-- Exercise 6: Refresh Strategies and Performance
-- ==========================================

-- 6.1: Manual refresh testing
-- TODO: Write commands to refresh the materialized view created above.
REFRESH MATERIALIZED VIEW film_stats;

-- 6.2: Performance comparison
-- TODO: Use EXPLAIN ANALYZE to compare the query performance between a complex regular view
-- and its materialized counterpart.

-- Step 1: Create a complex regular view for sales by category.
CREATE OR REPLACE VIEW sales_by_category_view AS
SELECT
    c.name AS category,
    SUM(p.amount) AS total_sales
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film_category fc ON i.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name;

-- Step 2: Create an equivalent materialized view.
CREATE MATERIALIZED VIEW sales_by_category_materialized AS
SELECT
    c.name AS category,
    SUM(p.amount) AS total_sales
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film_category fc ON i.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name;

REFRESH MATERIALIZED VIEW sales_by_category_materialized;

-- Step 3: Analyze the performance difference. 
-- Run these queries and compare the execution times and plan costs.
EXPLAIN ANALYZE SELECT * FROM sales_by_category_view ORDER BY total_sales DESC;
EXPLAIN ANALYZE SELECT * FROM sales_by_category_materialized ORDER BY total_sales DESC;

-- Notice:
-- - The regular view performs all joins and aggregations on every query
-- - The materialized view simply reads pre-computed results (much faster)
-- - Look at "Execution Time" in the EXPLAIN ANALYZE output


-- ==========================================
-- Cleanup Section
-- ==========================================
-- Run this section after completing the lab to clean up all created objects

/*
-- Drop all views (CASCADE removes dependent objects)
DROP VIEW IF EXISTS customer_info CASCADE;
DROP VIEW IF EXISTS film_catalog CASCADE;
DROP VIEW IF EXISTS store_1_active_customers CASCADE;
DROP VIEW IF EXISTS store_2_customers_secure CASCADE;
DROP VIEW IF EXISTS rental_details CASCADE;
DROP VIEW IF EXISTS sales_by_category_view CASCADE;

-- Drop all materialized views
DROP MATERIALIZED VIEW IF EXISTS film_stats;
DROP MATERIALIZED VIEW IF EXISTS sales_by_category_materialized;
*/


-- ==========================================
-- Analysis Questions
-- ==========================================
/*
1.  Which of your regular views are updatable and why?
    Answer: The `store_1_active_customers` and `store_2_customers_secure` views are updatable 
    because they:
    - Reference a single base table (customer)
    - Do not use aggregations, GROUP BY, DISTINCT, or window functions
    - Have a clear one-to-one mapping between view rows and table rows
    - All selected columns map directly to base table columns
    
    Views like `customer_info` are NOT updatable because they join multiple tables,
    making it ambiguous which table should be updated.

2.  What are the performance differences between regular and materialized views in Exercise 6?
    Answer: The regular view (`sales_by_category_view`) must execute all joins and aggregations 
    on every query, which is computationally expensive. The materialized view 
    (`sales_by_category_materialized`) stores pre-computed results, so queries simply read 
    from disk - typically 10-100x faster. The tradeoff is that materialized views show 
    stale data until refreshed and consume storage space.

3.  How does the `WITH CHECK OPTION` clause in Exercise 3 improve data integrity?
    Answer: It prevents data modifications through the view that would create rows not visible
    through that same view. For example, it prevented us from changing a customer's `store_id`
    to a value that didn't match the view's WHERE clause (store_id = 2). This maintains 
    logical consistency and prevents "phantom updates" where data disappears from a view 
    after being modified through it.
*/