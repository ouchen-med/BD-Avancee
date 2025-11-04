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

-- Verify the change in the base table
SELECT customer_id, email 
FROM customer 
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

