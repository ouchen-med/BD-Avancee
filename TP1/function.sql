-- ============================================================================
-- LAB 04: STORED PROCEDURES AND FUNCTIONS
-- Database: Pagila (DVD Rental Database)
-- ============================================================================

-- ============================================================================
-- PRE-LAB SETUP: Verify Database Connection
-- ============================================================================

-- Test your connection by running this query:
SELECT 'Connected to Pagila database!' AS status,
       COUNT(*) AS total_customers,
       (SELECT COUNT(*) FROM film) AS total_films,
       (SELECT COUNT(*) FROM rental) AS total_rentals
FROM customer;

--🔹 ما هو CURSOR FOR UPDATE؟<
-- Expected: Should show counts without errors
-- If you get an error, check your database connection!


-- ============================================================================
-- PART 1: BASIC SCALAR FUNCTIONS
-- Learning: Create functions that return single values
-- ============================================================================

-- Exercise 1.1: Temperature Converter
-- Create a function that converts temperature from Fahrenheit to Celsius
-- Formula: C = (F - 32) × 5/9
-- The function should round the result to 2 decimal places



------(ROLLBACK)-------

CREATE OR REPLACE FUNCTION fahrenheit_to_celsius(temp_f NUMERIC)
RETURNS NUMERIC AS $$
 
BEGIN
    -- TODO: Calculate Celsius from Fahrenheit
    -- Use the formula: (F - 32) × 5/9
    -- Round to 2 decimal places using ROUND(value, 2)
    RETURN ROUND((temp_f - 32) * 5.0 / 9.0, 2);
END;
$$ LANGUAGE plpgsql;

-- Test your function:
 SELECT fahrenheit_to_celsius(32);    -- Expected: 0.00 (freezing)
 SELECT fahrenheit_to_celsius(212);   -- Expected: 100.00 (boiling)
 SELECT fahrenheit_to_celsius(98.6);  -- Expected: 37.00 (body temp)


-- Exercise 1.2: Film Duration Formatter 
-- Create a function that takes film length in minutes and returns formatted string
-- Example: 120 minutes should return "2 hours 0 minutes"
--          95 minutes should return "1 hour 35 minutes"

CREATE OR REPLACE FUNCTION format_film_duration(length_minutes INTEGER)
RETURNS TEXT AS $$
DECLARE
    hours INTEGER;
    minutes INTEGER;
    hour_word TEXT;
BEGIN
    -- TODO: Calculate hours and remaining minutes
    hours := length_minutes / 60;
    minutes := length_minutes % 60;
    
    -- TODO: Set singular or plural for "hour"
    IF hours = 1 THEN
        hour_word := 'hour';
    ELSE
        hour_word := 'hours';
    END IF;
    
    -- TODO: Return formatted string
    RETURN ___ || ' ' || ___ || ' ' || ___ || ' minutes';
END;
$$ LANGUAGE plpgsql;

-- Test your function:
 SELECT title, length, format_film_duration(length) AS formatted_duration
-- FROM film
-- WHERE length IN (46, 120, 185)
-- LIMIT 3;


-- Exercise 1.3: Calculate Rental Days 
-- Create a function that calculates the number of days a rental lasted
-- If return_date is NULL (not returned yet), use CURRENT_DATE
-- Return the number of days as an INTEGER

CREATE OR REPLACE FUNCTION calculate_rental_days(
    rental_date_param TIMESTAMP,
    return_date_param TIMESTAMP
)
RETURNS INTEGER AS $$
DECLARE
    actual_return_date TIMESTAMP;
    days_difference INTEGER;
BEGIN
    -- TODO: If return_date is NULL, use CURRENT_TIMESTAMP
    IF return_date_param IS NULL THEN
        actual_return_date := ___;
    ELSE
        actual_return_date := ___;
    END IF;
    
    -- TODO: Calculate days between dates
    -- HINT: Use DATE_PART('day', timestamp1 - timestamp2) or EXTRACT
    days_difference := ___;
    
    RETURN days_difference;
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT rental_id, rental_date, return_date,
--        calculate_rental_days(rental_date, return_date) AS rental_days
-- FROM rental
-- LIMIT 10;


-- Exercise 1.4: Calculate Late Fee 
-- Create a function to calculate late fees for overdue rentals
-- Business Rules:
--   - Standard rental period: 3 days
--   - Late fee: $1.50 per day overdue
--   - Maximum late fee: $25.00
-- Parameters: rental_days (INTEGER)
-- Return: late_fee (NUMERIC)

CREATE OR REPLACE FUNCTION calculate_late_fee(rental_days INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    standard_period INTEGER := 3;
    daily_late_fee NUMERIC := 1.50;
    max_late_fee NUMERIC := 25.00;
    days_overdue INTEGER;
    calculated_fee NUMERIC;
BEGIN
    -- TODO: Calculate days overdue
    days_overdue := ___;
    
    -- TODO: If not overdue, return 0
    IF days_overdue <= 0 THEN
        RETURN ___;
    END IF;
    
    -- TODO: Calculate fee (days_overdue * daily_late_fee)
    calculated_fee := ___;
    
    -- TODO: Apply maximum cap
    IF calculated_fee > max_late_fee THEN
        calculated_fee := ___;
    END IF;
    
    RETURN ROUND(calculated_fee, 2);
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT calculate_late_fee(2) AS no_fee,      -- Expected: 0.00
--        calculate_late_fee(5) AS small_fee,    -- Expected: 3.00
--        calculate_late_fee(10) AS medium_fee,  -- Expected: 10.50
--        calculate_late_fee(25) AS max_fee;     -- Expected: 25.00 (capped)


-- ============================================================================
-- PART 2: FUNCTIONS WITH DATABASE QUERIES
-- Learning: Query database and return results
-- ============================================================================

-- Exercise 2.1: Get Customer Full Name 
-- Create a function that returns a customer's full name (first + last)
-- Handle the case where customer doesn't exist (return 'Customer not found')

CREATE OR REPLACE FUNCTION get_customer_full_name(cust_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    full_name TEXT;
BEGIN
    -- TODO: Select concatenated first_name and last_name
    SELECT ___ || ' ' || ___
    INTO full_name
    FROM customer
    WHERE customer_id = ___;
    
    -- TODO: Handle customer not found
    IF full_name IS ___ THEN
        RETURN '__________';
    END IF;
    
    RETURN full_name;
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT get_customer_full_name(1);    -- Should return actual name
-- SELECT get_customer_full_name(9999); -- Should return 'Customer not found'


-- Exercise 2.2: Count Customer Rentals 
-- Create a function that returns the total number of rentals for a customer

CREATE OR REPLACE FUNCTION count_customer_rentals(cust_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    rental_count INTEGER;
BEGIN
    -- TODO: Count rentals for the customer
    SELECT ___
    INTO rental_count
    FROM rental
    WHERE customer_id = ___;
    
    RETURN rental_count;
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT customer_id,
--        get_customer_full_name(customer_id) AS customer_name,
--        count_customer_rentals(customer_id) AS total_rentals
-- FROM customer
-- WHERE customer_id IN (1, 2, 3);


-- Exercise 2.3: Get Customer Total Spent 
-- Create a function that calculates total amount spent by a customer
-- Use COALESCE to return 0 if customer has no payments

CREATE OR REPLACE FUNCTION get_customer_total_spent(cust_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    total_spent NUMERIC;
BEGIN
    -- TODO: Sum all payment amounts for customer
    -- Use COALESCE to handle NULL (no payments)
    SELECT ___(SUM(___), 0)
    INTO total_spent
    FROM payment
    WHERE customer_id = ___;
    
    RETURN ROUND(total_spent, 2);
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT customer_id,
--        get_customer_full_name(customer_id) AS name,
--        count_customer_rentals(customer_id) AS rentals,
--        get_customer_total_spent(customer_id) AS total_spent
-- FROM customer
-- ORDER BY total_spent DESC
-- LIMIT 10;


-- Exercise 2.4: Get Film Average Rental Duration 
-- Create a function that calculates average rental duration for a film
-- Return average days as NUMERIC rounded to 2 decimals

CREATE OR REPLACE FUNCTION get_film_avg_rental_duration(film_id_param INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    avg_duration NUMERIC;
BEGIN
    -- TODO: Calculate average rental duration for a film
    -- HINT: Join rental -> inventory -> film
    -- Use calculate_rental_days function you created earlier
    -- Use AVG() aggregate function
    SELECT AVG(___(r.rental_date, r.return_date))
    INTO avg_duration
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    WHERE i.film_id = ___;
    
    -- TODO: Return 0 if no rentals found
    RETURN COALESCE(ROUND(___, 2), 0);
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT f.film_id, f.title,
--        get_film_avg_rental_duration(f.film_id) AS avg_rental_days
-- FROM film f
-- WHERE f.film_id IN (1, 2, 3, 4, 5);


-- ============================================================================
-- PART 3: TABLE-RETURNING FUNCTIONS (SET-RETURNING FUNCTIONS)
-- Learning: Return multiple rows as a result set
-- ============================================================================

-- Exercise 3.1: Get Top Spending Customers 
-- Create a function that returns the top N customers by total spending
-- Return columns: customer_id, customer_name, total_rentals, total_spent

CREATE OR REPLACE FUNCTION get_top_customers(limit_count INTEGER)
RETURNS TABLE(
    customer_id INTEGER,
    customer_name TEXT,
    total_rentals BIGINT,
    total_spent NUMERIC
) AS $$
BEGIN
    -- TODO: Use RETURN QUERY to return a result set
    -- Join customer with rental and payment
    -- Group by customer
    -- Order by total spent descending
    -- Limit to top N
    
    RETURN QUERY
    SELECT 
        c.customer_id,
        ___ || ' ' || ___ AS customer_name,
        COUNT(DISTINCT r.rental_id) AS total_rentals,
        COALESCE(SUM(p.___), 0) AS total_spent
    FROM customer c
    LEFT JOIN rental r ON c.customer_id = r.customer_id
    LEFT JOIN payment p ON r.rental_id = p.rental_id
    GROUP BY ___, ___, ___
    ORDER BY total_spent ___
    LIMIT ___;
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT * FROM get_top_customers(10);

-- Advanced test: Filter results
-- SELECT * FROM get_top_customers(20)
-- WHERE total_spent > 150;


-- Exercise 3.2: Get Films by Category and Rating 
-- Create a function that returns films filtered by category and rating
-- Return: film_id, title, category_name, rating, rental_rate, length

CREATE OR REPLACE FUNCTION get_films_by_category_rating(
    category_name_param TEXT,
    rating_param TEXT
)
RETURNS TABLE(
    film_id INTEGER,
    title TEXT,
    category_name TEXT,
    rating TEXT,
    rental_rate NUMERIC,
    length INTEGER
) AS $$
BEGIN
    -- TODO: Return films matching both category and rating
    -- Join: film -> film_category -> category
    -- Filter by category name and rating
    -- Order by title
    
    RETURN QUERY
    SELECT 
        f.film_id,
        f.___,
        c.name AS category_name,
        f.rating::TEXT,
        f.___,
        f.___
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = ___
      AND f.rating = ___::mpaa_rating
    ORDER BY ___;
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT * FROM get_films_by_category_rating('Action', 'PG-13');
-- SELECT * FROM get_films_by_category_rating('Comedy', 'G');
-- SELECT COUNT(*) FROM get_films_by_category_rating('Horror', 'R');


-- Exercise 3.3: Get Customer Rental History 
-- Create a function that returns detailed rental history for a customer
-- Return: rental_id, rental_date, film_title, rental_rate, return_date

CREATE OR REPLACE FUNCTION get_customer_rental_history(cust_id INTEGER)
RETURNS TABLE(
    rental_id INTEGER,
    rental_date TIMESTAMP,
    film_title TEXT,
    rental_rate NUMERIC,
    return_date TIMESTAMP
) AS $$
BEGIN
    -- TODO: Return rental history for a customer
    -- Join: rental -> inventory -> film
    -- Filter by customer_id
    -- Order by rental_date descending (most recent first)
    
    RETURN QUERY
    SELECT 
        r.rental_id,
        r.___,
        f.title AS film_title,
        f.___,
        r.___
    FROM ___ r
    JOIN ___ i ON r.inventory_id = i.inventory_id
    JOIN ___ f ON i.film_id = f.film_id
    WHERE r.customer_id = ___
    ORDER BY r.rental_date ___;
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT * FROM get_customer_rental_history(1) LIMIT 10;

-- Count total rentals for a customer:
-- SELECT COUNT(*) AS total_rentals
-- FROM get_customer_rental_history(1);


-- ============================================================================
-- PART 4: VALIDATION FUNCTIONS
-- Learning: Implement business rules and data validation
-- ============================================================================

-- Exercise 4.1: Validate Email Format 
-- Create a function that checks if an email string is valid
-- Rules:
--   - Not NULL or empty
--   - Must contain exactly one @
--   - Must have text before @
--   - Must have domain after @ with at least one dot
--   - No spaces allowed

CREATE OR REPLACE FUNCTION is_valid_email(email TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    at_count INTEGER;
    at_position INTEGER;
    domain_part TEXT;
BEGIN
    -- TODO: Check for NULL or empty
    IF email IS NULL OR email = '' THEN
        RETURN ___;
    END IF;
    
    -- TODO: Check for spaces
    IF email LIKE '% %' THEN
        RETURN ___;
    END IF;
    
    -- TODO: Count @ symbols (must be exactly 1)
    at_count := LENGTH(email) - LENGTH(REPLACE(email, '@', ''));
    IF at_count != ___ THEN
        RETURN FALSE;
    END IF;
    
    -- TODO: Get position of @
    at_position := POSITION(___ IN email);
    
    -- TODO: Check text exists before @
    IF at_position = ___ THEN
        RETURN FALSE;
    END IF;
    
    -- TODO: Extract domain part (after @)
    domain_part := SUBSTRING(email FROM at_position + 1);
    
    -- TODO: Check domain has at least 3 characters and contains .
    IF LENGTH(domain_part) < 3 OR domain_part NOT LIKE '%.%' THEN
        RETURN ___;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT is_valid_email('user@example.com');      -- Expected: TRUE
-- SELECT is_valid_email('invalid.email');         -- Expected: FALSE (no @)
-- SELECT is_valid_email('@example.com');          -- Expected: FALSE (nothing before @)
-- SELECT is_valid_email('user@domain');           -- Expected: FALSE (no . in domain)
-- SELECT is_valid_email('user @example.com');     -- Expected: FALSE (has space)
-- SELECT is_valid_email(NULL);                    -- Expected: FALSE


-- Exercise 4.2: Validate Rental Rate
-- Create a function that checks if a rental rate is valid
-- Rules:
--   - Not NULL
--   - Greater than 0
--   - Less than or equal to 50.00 (business maximum)

CREATE OR REPLACE FUNCTION is_valid_rental_rate(rate NUMERIC)
RETURNS BOOLEAN AS $$
BEGIN
    -- TODO: Implement validation rules
    IF rate IS NULL OR rate <= ___ OR rate > ___ THEN
        RETURN ___;
    END IF;
    
    RETURN ___;
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT is_valid_rental_rate(2.99);   -- Expected: TRUE
-- SELECT is_valid_rental_rate(0);      -- Expected: FALSE
-- SELECT is_valid_rental_rate(-1);     -- Expected: FALSE
-- SELECT is_valid_rental_rate(NULL);   -- Expected: FALSE
-- SELECT is_valid_rental_rate(100);    -- Expected: FALSE

-- Use in a query:
-- SELECT film_id, title, rental_rate,
--        is_valid_rental_rate(rental_rate) AS is_valid
-- FROM film
-- WHERE NOT is_valid_rental_rate(rental_rate);


-- Exercise 4.3: Check Film Availability 
-- Create a function that checks if a film has available copies
-- A film is available if it has inventory that is not currently rented
-- Return TRUE if available, FALSE otherwise

CREATE OR REPLACE FUNCTION is_film_available(film_id_param INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    available_count INTEGER;
BEGIN
    -- TODO: Count available inventory for this film
    -- Available = inventory exists AND not currently rented
    -- HINT: LEFT JOIN rental and check for return_date IS NOT NULL
    --       OR rental_id IS NULL (never rented)
    
    SELECT COUNT(*)
    INTO available_count
    FROM inventory i
    LEFT JOIN rental r ON i.inventory_id = r.inventory_id 
        AND r.return_date IS ___
    WHERE i.film_id = ___
        AND r.rental_id IS ___;
    
    RETURN available_count > ___;
END;
$$ LANGUAGE plpgsql;

-- Test your function:
-- SELECT film_id, title,
--        is_film_available(film_id) AS available
-- FROM film
-- ORDER BY film_id
-- LIMIT 20;

-- Count available vs unavailable films:
-- SELECT 
--     COUNT(*) FILTER (WHERE is_film_available(film_id)) AS available_films,
--     COUNT(*) FILTER (WHERE NOT is_film_available(film_id)) AS unavailable_films
-- FROM film;


-- ============================================================================
-- PART 5: BASIC PROCEDURES
-- Learning: Perform actions and modify data
-- ============================================================================

-- Exercise 5.1: Update Customer Email 
-- Create a procedure to update a customer's email address
-- Include validation and error handling

CREATE OR REPLACE PROCEDURE update_customer_email(
    cust_id INTEGER,
    new_email TEXT
)
AS $$
BEGIN
    -- TODO: Validate email format using is_valid_email function
    IF NOT ___(___) THEN
        RAISE EXCEPTION 'Invalid email format: %', ___;
    END IF;
    
    -- TODO: Update the customer email
    UPDATE customer
    SET email = ___,
        last_update = CURRENT_TIMESTAMP
    WHERE customer_id = ___;
    
    -- TODO: Check if update was successful
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer ID % not found', ___;
    END IF;
    
    RAISE NOTICE 'Email updated successfully for customer %', ___;
END;
$$ LANGUAGE plpgsql;

-- Test your procedure:
-- First, check current email:
-- SELECT customer_id, first_name, last_name, email 
-- FROM customer WHERE customer_id = 1;

-- Update email:
-- CALL update_customer_email(1, 'newemail@example.com');

-- Verify update:
-- SELECT customer_id, first_name, last_name, email 
-- FROM customer WHERE customer_id = 1;

-- Test error handling:
-- CALL update_customer_email(1, 'invalid-email');  -- Should raise exception
-- CALL update_customer_email(9999, 'test@example.com');  -- Should raise exception


-- Exercise 5.2: Update Film Rental Rate
-- Create a procedure to update a film's rental rate
-- Include validation using is_valid_rental_rate function

CREATE OR REPLACE PROCEDURE update_film_rental_rate(
    film_id_param INTEGER,
    new_rate NUMERIC
)
AS $$
BEGIN
    -- TODO: Validate rental rate
    IF NOT ___(___) THEN
        RAISE EXCEPTION 'Invalid rental rate: %. Must be between 0 and 50.', ___;
    END IF;
    
    -- TODO: Check if film exists
    IF NOT EXISTS (SELECT 1 FROM film WHERE film_id = ___) THEN
        RAISE EXCEPTION 'Film ID % not found', ___;
    END IF;
    
    -- TODO: Update film rental rate
    UPDATE ___
    SET rental_rate = ___,
        last_update = ___
    WHERE film_id = ___;
    
    RAISE NOTICE 'Film % rental rate updated to $%', film_id_param, new_rate;
END;
$$ LANGUAGE plpgsql;

-- Test your procedure:
-- Check current rate:
-- SELECT film_id, title, rental_rate FROM film WHERE film_id = 1;

-- Update rate:
-- CALL update_film_rental_rate(1, 3.99);

-- Verify:
-- SELECT film_id, title, rental_rate FROM film WHERE film_id = 1;

-- Test validation:
-- CALL update_film_rental_rate(1, -5);     -- Should fail
-- CALL update_film_rental_rate(1, 100);    -- Should fail
-- CALL update_film_rental_rate(9999, 2.99); -- Should fail


-- Exercise 5.3: Deactivate Customer 
-- Create a procedure to deactivate a customer account
-- Log the reason and check if customer is already inactive

CREATE OR REPLACE PROCEDURE deactivate_customer(
    cust_id INTEGER,
    reason TEXT
)
AS $$
DECLARE
    customer_name TEXT;
    current_status BOOLEAN;
BEGIN
    -- TODO: Get customer name and current status
    SELECT first_name || ' ' || last_name, ___::BOOLEAN
    INTO customer_name, current_status
    FROM customer
    WHERE customer_id = ___;
    
    -- TODO: Check if customer exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer ID % not found', ___;
    END IF;
    
    -- TODO: Check if already inactive (active = 0 or activebool = FALSE)
    IF current_status = FALSE THEN
        RAISE NOTICE 'Customer % is already inactive', ___;
        RETURN;
    END IF;
    
    -- TODO: Deactivate customer
    UPDATE customer
    SET active = ___,
        activebool = ___,
        last_update = CURRENT_TIMESTAMP
    WHERE customer_id = ___;
    
    -- TODO: Log the deactivation
    RAISE NOTICE '===================================';
    RAISE NOTICE 'Customer Deactivation Log';
    RAISE NOTICE '===================================';
    RAISE NOTICE 'Customer ID: %', ___;
    RAISE NOTICE 'Customer Name: %', ___;
    RAISE NOTICE 'Deactivation Date: %', CURRENT_TIMESTAMP;
    RAISE NOTICE 'Reason: %', ___;
    RAISE NOTICE '===================================';
END;
$$ LANGUAGE plpgsql;

-- Test your procedure:
-- Find an active customer:
-- SELECT customer_id, first_name, last_name, active, activebool
-- FROM customer
-- WHERE activebool = TRUE
-- LIMIT 1;

-- Deactivate customer (use an actual customer_id from above query):
-- CALL deactivate_customer(1, 'Customer request for account closure');

-- Verify:
-- SELECT customer_id, first_name, last_name, active, activebool
-- FROM customer
-- WHERE customer_id = 1;

-- Try to deactivate again (should notice already inactive):
-- CALL deactivate_customer(1, 'Testing duplicate deactivation');


-- ============================================================================
-- PART 6: ADVANCED PROCEDURES
-- Learning: Complex multi-step operations
-- ============================================================================

-- Exercise 6.1: Calculate and Display Customer Statistics 
-- Create a procedure that displays comprehensive statistics for a customer
-- Should calculate and display: rentals, payments, average, customer tier

CREATE OR REPLACE PROCEDURE display_customer_statistics(cust_id INTEGER)
AS $$
DECLARE
    v_name TEXT;
    v_email TEXT;
    v_rental_count INTEGER;
    v_total_spent NUMERIC;
    v_avg_payment NUMERIC;
    v_tier TEXT;
BEGIN
    -- TODO: Get customer basic info using your get_customer_full_name function
    v_name := ___(___);
    
    -- TODO: Check if customer exists
    IF v_name = 'Customer not found' THEN
        RAISE EXCEPTION 'Customer ID % not found', ___;
    END IF;
    
    -- TODO: Get customer email
    SELECT email INTO v_email
    FROM customer
    WHERE customer_id = ___;
    
    -- TODO: Use your functions to get statistics
    v_rental_count := ___(___);
    v_total_spent := ___(___);
    
    -- TODO: Calculate average payment
    IF v_rental_count > 0 THEN
        v_avg_payment := v_total_spent / ___;
    ELSE
        v_avg_payment := 0;
    END IF;
    
    -- TODO: Determine customer tier based on spending
    IF v_total_spent >= 150 THEN
        v_tier := 'Premium';
    ELSIF v_total_spent >= 100 THEN
        v_tier := 'Gold';
    ELSIF v_total_spent >= 50 THEN
        v_tier := 'Silver';
    ELSE
        v_tier := 'Bronze';
    END IF;
    
    -- TODO: Display formatted report
    RAISE NOTICE '============================================';
    RAISE NOTICE 'CUSTOMER STATISTICS REPORT';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Customer ID:      %', ___;
    RAISE NOTICE 'Name:             %', ___;
    RAISE NOTICE 'Email:            %', ___;
    RAISE NOTICE '--------------------------------------------';
    RAISE NOTICE 'Total Rentals:    %', ___;
    RAISE NOTICE 'Total Spent:      $%', ___;
    RAISE NOTICE 'Average Payment:  $%', ROUND(v_avg_payment, 2);
    RAISE NOTICE 'Customer Tier:    %', ___;
    RAISE NOTICE '============================================';
END;
$$ LANGUAGE plpgsql;

-- Test your procedure:
-- CALL display_customer_statistics(1);
-- CALL display_customer_statistics(5);
-- CALL display_customer_statistics(10);


-- Exercise 6.2: Transfer Inventory Between Stores 
-- Create a procedure to transfer inventory items between stores
-- Include validation for: inventory exists, item not currently rented, target store exists

CREATE OR REPLACE PROCEDURE transfer_inventory(
    inventory_id_param INTEGER,
    target_store_id INTEGER
)
AS $$
DECLARE
    v_film_id INTEGER;
    v_current_store_id INTEGER;
    v_film_title TEXT;
BEGIN
    -- TODO: Get current inventory details
    SELECT i.film_id, i.store_id, f.title
    INTO v_film_id, v_current_store_id, v_film_title
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    WHERE i.inventory_id = ___;
    
    -- TODO: Check if inventory exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inventory ID % not found', ___;
    END IF;
    
    -- TODO: Check if inventory is currently rented
    IF EXISTS (
        SELECT 1 FROM rental
        WHERE inventory_id = ___
          AND return_date IS ___
    ) THEN
        RAISE EXCEPTION 'Cannot transfer: inventory is currently rented';
    END IF;
    
    -- TODO: Check if already at target store
    IF v_current_store_id = target_store_id THEN
        RAISE NOTICE 'Inventory % is already at store %', 
                     inventory_id_param, target_store_id;
        RETURN;
    END IF;
    
    -- TODO: Validate target store exists
    IF NOT EXISTS (SELECT 1 FROM store WHERE store_id = ___) THEN
        RAISE EXCEPTION 'Target store % does not exist', ___;
    END IF;
    
    -- TODO: Perform the transfer
    UPDATE ___
    SET store_id = ___,
        last_update = ___
    WHERE inventory_id = ___;
    
    RAISE NOTICE 'Successfully transferred inventory % (%) from store % to store %',
                 inventory_id_param, v_film_title, 
                 v_current_store_id, target_store_id;
END;
$$ LANGUAGE plpgsql;

-- Test your procedure:
-- Check inventory before transfer:
-- SELECT i.inventory_id, f.title, i.store_id,
--        EXISTS (SELECT 1 FROM rental r 
--                WHERE r.inventory_id = i.inventory_id 
--                  AND r.return_date IS NULL) AS currently_rented
-- FROM inventory i
-- JOIN film f ON i.film_id = f.film_id
-- WHERE i.inventory_id = 1;

-- Transfer inventory:
-- CALL transfer_inventory(1, 2);

-- Verify transfer:
-- SELECT i.inventory_id, f.title, i.store_id
-- FROM inventory i
-- JOIN film f ON i.film_id = f.film_id
-- WHERE i.inventory_id = 1;

-- Test error cases:
-- CALL transfer_inventory(99999, 1);  -- Invalid inventory
-- CALL transfer_inventory(1, 99);     -- Invalid store


-- ============================================================================
-- CLEANUP (Optional - only if you want to remove all your work)
-- ============================================================================

/*
-- Uncomment to drop all functions and procedures created in this lab:

-- Part 1 Functions
DROP FUNCTION IF EXISTS fahrenheit_to_celsius(NUMERIC);
DROP FUNCTION IF EXISTS format_film_duration(INTEGER);
DROP FUNCTION IF EXISTS calculate_rental_days(TIMESTAMP, TIMESTAMP);
DROP FUNCTION IF EXISTS calculate_late_fee(INTEGER);

-- Part 2 Functions
DROP FUNCTION IF EXISTS get_customer_full_name(INTEGER);
DROP FUNCTION IF EXISTS count_customer_rentals(INTEGER);
DROP FUNCTION IF EXISTS get_customer_total_spent(INTEGER);
DROP FUNCTION IF EXISTS get_film_avg_rental_duration(INTEGER);

-- Part 3 Functions
DROP FUNCTION IF EXISTS get_top_customers(INTEGER);
DROP FUNCTION IF EXISTS get_films_by_category_rating(TEXT, TEXT);
DROP FUNCTION IF EXISTS get_customer_rental_history(INTEGER);

-- Part 4 Functions
DROP FUNCTION IF EXISTS is_valid_email(TEXT);
DROP FUNCTION IF EXISTS is_valid_rental_rate(NUMERIC);
DROP FUNCTION IF EXISTS is_film_available(INTEGER);

-- Part 5 Procedures
DROP PROCEDURE IF EXISTS update_customer_email(INTEGER, TEXT);
DROP PROCEDURE IF EXISTS update_film_rental_rate(INTEGER, NUMERIC);
DROP PROCEDURE IF EXISTS deactivate_customer(INTEGER, TEXT);

-- Part 6 Procedures
DROP PROCEDURE IF EXISTS display_customer_statistics(INTEGER);
DROP PROCEDURE IF EXISTS transfer_inventory(INTEGER, INTEGER);

-- Bonus
DROP FUNCTION IF EXISTS calculate_customer_lifetime_value(INTEGER, INTEGER);
DROP PROCEDURE IF EXISTS bulk_update_category_prices(TEXT, NUMERIC);
*/


-- ============================================================================
-- LAB COMPLETION CHECKLIST
-- ============================================================================

/*
Before submitting, verify:

□ Part 1: All 4 basic functions work correctly
□ Part 2: All 4 database query functions work correctly
□ Part 3: All 3 table-returning functions work correctly
□ Part 4: All 3 validation functions work correctly
□ Part 5: All 3 basic procedures work correctly
□ Part 6: Both advanced procedures work correctly
□ Bonus: Attempted bonus challenges (optional)
□ All test queries run without errors
□ Functions return expected data types
□ Procedures display appropriate NOTICE messages
□ Error handling works for invalid inputs
□ Code is properly commented
□ All ___ placeholders are filled in

Congratulations on completing Lab 04! 🎉
*/