-- ============================================================================
-- Lab 03: Introduction to PL/pgSQL and Cursors
-- ============================================================================
-- Difficulty: Intermediate
-- Database: Pagila (PostgreSQL sample database)
-- 
-- Lab Objectives:
--   1. Understand and use PL/pgSQL DO blocks
--   2. Declare and use variables with proper data types
--   3. Use control structures (IF, LOOP, FOR, WHILE)
--   4. Implement basic and parameterized cursors
--   5. Process result sets row-by-row with cursors
--   6. Handle exceptions and errors properly
--
-- Prerequisites:
--   - PostgreSQL installed locally on Windows
--   - Pagila sample database loaded
--   - Completion of Labs 01 and 02 recommended
--   - SQL client (pgAdmin, DBeaver, or psql)
--
-- ============================================================================


-- ============================================================================
-- PRE-LAB CHECKLIST
-- ============================================================================
-- Before starting this lab, verify the following:
--
-- [ ] PostgreSQL is running on your local machine
-- [ ] You can connect to the Pagila database
-- [ ] Pagila database has data:
--      → Run: SELECT COUNT(*) FROM customer; (Expected: 599 customers)
--      → Run: SELECT COUNT(*) FROM rental; (Expected: 16,044 rentals)
-- [ ] Test a simple DO block:
--      → Run: DO $$ BEGIN RAISE NOTICE 'Ready!'; END $$;
--      → Should see "NOTICE: Ready!" in output
--
-- ✓ All checks passed? Great! You're ready to begin.
-- ============================================================================

-- ============================================================================
-- PART 1: PL/pgSQL BASICS (25 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exercise 1.1: First DO Block with Variables (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Declares a variable for customer first name
-- 2. Declares a variable for total rentals (INTEGER)
-- 3. Assigns the values from customer_id = 1
-- 4. Displays: "Customer [name] has [count] rentals"
--
-- Expected output: "Customer MARY has 32 rentals"
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    cust_name VARCHAR(100);           -- Customer first name
    rental_count INTEGER;             -- Total number of rentals
BEGIN
    -- Query customer data and count rentals
    SELECT c.first_name, COUNT(r.rental_id)
    INTO cust_name, rental_count
    FROM customer c
    LEFT JOIN rental r ON c.customer_id = r.customer_id
    WHERE c.customer_id = 5  -- Fill in the customer_id
    GROUP BY c.first_name;
    
    -- Display the result
RAISE NOTICE 'Customer % has % rentals', cust_name, rental_count;

END $$;




-- ----------------------------------------------------------------------------
-- Exercise 1.2: Using %TYPE for Type Safety (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Uses %TYPE to declare variables matching the customer table columns
-- 2. Retrieves customer_id, first_name, last_name, email for customer_id = 5
-- 3. Displays all information in a formatted message
--
-- Hint: customer_name customer.first_name%TYPE;
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    cust_id customer.customer_id%TYPE;        -- Use %TYPE for type safety
    cust_fname customer.first_name%TYPE;            -- Fill in the column name
    cust_lname customer.last_name%TYPE;
    cust_email customer.last_name%TYPE;            -- Fill in the column name
BEGIN
    -- Retrieve customer data
    SELECT customer_id, first_name, last_name, email
    INTO cust_id, cust_fname, cust_lname,cust_email        -- Fill in the variables
    FROM customer
    WHERE customer_id = 5;
    
    -- Display formatted information
    RAISE NOTICE 'Customer #%: % % - Email: %', 
        cust_id, cust_fname, cust_lname, cust_email;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 1.3: Aggregation with SELECT INTO (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that calculates and displays:
-- 1. Total number of films in the database
-- 2. Average rental rate
-- 3. Maximum rental rate
-- 4. Minimum rental rate
--
-- Display all results in a formatted report
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    total_films INTEGER;
    avg_rate NUMERIC(5,2);
    max_rate NUMERIC(5,2);
    min_rate NUMERIC(5,2);
BEGIN
    -- Calculate aggregates
    SELECT COUNT(*), AVG(rental_rate), MAX(rental_rate), MIN(rental_rate)
    INTO total_films, avg_rate, max_rate, min_rate  -- Fill in the variables
    FROM film;
    
    -- Display formatted report
    RAISE NOTICE '=== FILM RENTAL STATISTICS ===';
    RAISE NOTICE 'Total Films: %', total_films;
    RAISE NOTICE 'Average Rental Rate: $%', avg_rate;
    RAISE NOTICE 'Maximum Rental Rate: $%', max_rate;
    RAISE NOTICE 'Minimum Rental Rate: $%', min_rate;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 1.4: Conditional Logic with IF statements (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Retrieves the rental_rate for film_id = 1
-- 2. Categorizes the film as:
--    - "Budget" if rate < 2.00
--    - "Standard" if rate >= 2.00 and < 4.00
--    - "Premium" if rate >= 4.00
-- 3. Displays: "Film [title] is a [category] rental at $[rate]"
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    film_title film.title%TYPE;
    film_rate film.rental_rate%TYPE;
    rate_category VARCHAR(20);
BEGIN
    -- Get film information
    SELECT title, rental_rate
    INTO film_title, film_rate  -- Fill in the variables
    FROM film
    WHERE film_id = 1;
    
    -- Categorize based on rental rate
    IF film_rate < 2.00 THEN  -- Fill in the threshold
        rate_category := 'Budget';
    ELSIF film_rate >= 2.00 AND film_rate <  4.00 THEN  -- Fill in threshold
        rate_category := 'Standard';  -- Fill in the category name
    ELSE
        rate_category := 'Premium';
    END IF;
    
    -- Display result
    RAISE NOTICE 'Film "%" is a % rental at $%', 
        film_title, rate_category, film_rate;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 1.5: Simple FOR Loop (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Uses a FOR loop to iterate from 1 to 10
-- 2. For each number, calculates its square
-- 3. Displays: "The square of [n] is [n²]"
-- 4. After the loop, displays the sum of all squares
--
-- Hint: Sum of squares from 1 to 10 is 385
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    i INTEGER;
    square_value INTEGER;
    sum_of_squares INTEGER := 0;  -- Initialize to zero
BEGIN
    RAISE NOTICE '=== CALCULATING SQUARES ===';
    
    -- Loop through numbers 1 to 10
    FOR i IN 1..10 LOOP
        square_value := i * i;  -- Calculate square (fill in)
        sum_of_squares := sum_of_squares + square_value;  -- Add to sum (fill in)
        
        RAISE NOTICE 'The square of % is %', i, square_value;
    END LOOP;
    
    -- Display final sum
    RAISE NOTICE '';
    RAISE NOTICE 'Sum of all squares: %', sum_of_squares;
END $$;


-- ============================================================================
-- PART 2: WORKING WITH QUERY RESULTS (25 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exercise 2.1: FOR Loop with RECORD Type (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Uses a FOR loop to iterate through all film categories
-- 2. For each category, displays the category name
-- 3. Counts and displays the total number of categories
--
-- Expected: 16 categories
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    category_rec RECORD;  -- Holds each category row
    category_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== FILM CATEGORIES ===';
    
    -- Loop through all categories
    FOR category_rec IN 
        SELECT category_id, name
        FROM ___  -- Fill in the table name
        ORDER BY name
    LOOP
        category_count := category_count + 1;
        RAISE NOTICE '%: %', category_count, category_rec.___);  -- Fill in column
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Total categories: %', ___;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 2.2: Processing with Accumulation (7 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that analyzes the first 50 payments:
-- 1. Counts total payments processed
-- 2. Calculates total payment amount
-- 3. Counts payments over $5.00 (high value)
-- 4. Counts payments under $2.00 (low value)
-- 5. Displays a complete summary report
--
-- Use a FOR loop to process payments
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    payment_rec RECORD;
    total_count INTEGER := 0;
    total_amount NUMERIC(10,2) := 0;
    high_value_count INTEGER := 0;
    low_value_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== PAYMENT ANALYSIS ===';
    RAISE NOTICE '';
    
    FOR payment_rec IN 
        SELECT payment_id, amount
        FROM payment
        ORDER BY payment_date
        LIMIT ___  -- Fill in the limit
    LOOP
        total_count := total_count + 1;
        total_amount := total_amount + payment_rec.___);  -- Fill in column
        
        -- Categorize payment
        IF payment_rec.amount >= 5.00 THEN
            ___ := ___ + 1;  -- Increment high value counter
        ELSIF payment_rec.amount < ___ THEN  -- Fill in threshold
            low_value_count := low_value_count + 1;
        END IF;
    END LOOP;
    
    -- Display summary
    RAISE NOTICE '=== SUMMARY ===';
    RAISE NOTICE 'Total payments: %', ___;
    RAISE NOTICE 'Total amount: $%', total_amount;
    RAISE NOTICE 'High value (>=$5): %', high_value_count;
    RAISE NOTICE 'Low value (<$2): %', ___;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 2.3: Customer Spending Analysis (8 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that analyzes customer spending:
-- 1. For the first 20 customers (by customer_id)
-- 2. Calculate total amount spent by each customer
-- 3. Categorize customers as:
--    - "VIP" if total > $150
--    - "Regular" if total between $75 and $150
--    - "Occasional" if total < $75
-- 4. Count customers in each category
-- 5. Display individual customer info and final summary
--
-- Hint: Join customer with payment table
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    -- TODO: Declare variables
    
BEGIN
    -- TODO: Initialize counters
    
    -- TODO: FOR loop through customers with their spending
    
    -- TODO: Categorize and count
    
    -- TODO: Display results
    
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 2.4: WHILE Loop for Factorial Calculation (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Calculates the factorial of 7 using a WHILE loop
-- 2. Displays each step of the calculation
-- 3. Displays the final result
--
-- Example output:
-- "1! = 1"
-- "2! = 2"
-- "3! = 6"
-- ...
-- "7! = 5040"
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    counter INTEGER := 1;
    factorial INTEGER := 1;
    target INTEGER := 7;  -- Calculate 7!
BEGIN
    RAISE NOTICE '=== CALCULATING FACTORIAL OF % ===', target;
    
    WHILE counter <= ___ LOOP  -- Fill in the target
        factorial := factorial * ___);  -- Multiply by counter
        RAISE NOTICE '%! = %', counter, ___);  -- Display result
        counter := counter + ___);  -- Increment counter
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Final result: %! = %', target, factorial;
END $$;


-- ============================================================================
-- PART 3: CURSOR BASICS (20 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exercise 3.1: Simple Cursor with FOR Loop (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Declares a cursor for films with rental_rate > 3.00
-- 2. Uses FOR loop to iterate through the cursor
-- 3. Displays film title and rental rate
-- 4. Limits results to 10 films
-- 5. Counts and displays total films processed
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    -- Declare cursor for premium films
    premium_films_cursor CURSOR FOR
        SELECT film_id, title, rental_rate
        FROM film
        WHERE rental_rate > ___  -- Fill in the threshold
        ORDER BY rental_rate DESC
        LIMIT 10;
    
    film_rec RECORD;
    film_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== PREMIUM FILMS ===';
    RAISE NOTICE '';
    
    -- Loop through cursor
    FOR film_rec IN ___ LOOP  -- Fill in cursor name
        film_count := film_count + 1;
        RAISE NOTICE '%: "%" - $%', 
            film_count, film_rec.___, film_rec.rental_rate;  -- Fill in column
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Total films processed: %', ___;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 3.2: Direct Query in FOR Loop (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that lists stores with their addresses:
-- 1. Use a direct query in FOR loop (no cursor declaration)
-- 2. Join store, address, city, and country tables
-- 3. Display store_id, full address, and city/country
-- 4. Count total stores
--
-- This is the SIMPLEST cursor pattern - use it when possible!
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    store_rec RECORD;
    store_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== STORE LOCATIONS ===';
    RAISE NOTICE '';
    
    -- Direct query in FOR loop (no cursor declaration needed!)
    FOR store_rec IN
        SELECT s.store_id, a.address, ci.city, co.country
        FROM store s
        JOIN ___ a ON s.address_id = a.address_id  -- Fill in table
        JOIN city ci ON a.city_id = ci.city_id
        JOIN country co ON ci.country_id = co.___  -- Fill in column
        ORDER BY s.store_id
    LOOP
        store_count := store_count + 1;
        RAISE NOTICE 'Store #%: %, %, %', 
            store_rec.___, 
            store_rec.address,
            store_rec.___,  -- Fill in column
            store_rec.country;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Total stores: %', store_count;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 3.3: Manual Cursor Management (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block using manual cursor control:
-- 1. DECLARE a cursor for active customers (activebool = TRUE)
-- 2. OPEN the cursor
-- 3. FETCH rows in a LOOP until no more rows
-- 4. Display customer_id, first_name, last_name
-- 5. CLOSE the cursor
-- 6. Limit to first 15 customers
--
-- This demonstrates the complete cursor lifecycle!
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    -- Declare cursor
    active_customers_cursor CURSOR FOR
        SELECT customer_id, first_name, last_name
        FROM customer
        WHERE activebool = ___  -- Fill in TRUE
        ORDER BY customer_id
        LIMIT 15;
    
    customer_rec RECORD;
    customer_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== ACTIVE CUSTOMERS ===';
    RAISE NOTICE '';
    
    -- Step 1: OPEN the cursor
    ___ active_customers_cursor;  -- Fill in OPEN keyword
    
    -- Step 2: LOOP with FETCH
    LOOP
        -- Fetch next row
        ___ active_customers_cursor INTO customer_rec;  -- Fill in FETCH
        
        -- Exit when no more rows
        EXIT WHEN NOT ___;  -- Fill in FOUND
        
        customer_count := customer_count + 1;
        RAISE NOTICE '%: % % (ID: %)', 
            customer_count,
            customer_rec.first_name,
            customer_rec.___,  -- Fill in last_name
            customer_rec.customer_id;
    END LOOP;
    
    -- Step 3: CLOSE the cursor
    ___ active_customers_cursor;  -- Fill in CLOSE keyword
    
    RAISE NOTICE '';
    RAISE NOTICE 'Total active customers processed: %', customer_count;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 3.4: Cursor with Conditional Processing (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that processes rentals:
-- 1. Create a cursor for rentals from the last 30 days (from max rental_date)
-- 2. For each rental, check if it's been returned
-- 3. Count returned vs not returned
-- 4. Display rental details and status
-- 5. Limit to 20 rentals
-- 6. Display summary: total, returned, not returned
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    -- TODO: Declare variables and cursor
    
BEGIN
    -- TODO: Process rentals with cursor
    
    -- TODO: Categorize returned vs not returned
    
    -- TODO: Display summary
    
END $$;


-- ============================================================================
-- PART 4: PARAMETERIZED CURSORS (15 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exercise 4.1: Single Parameter Cursor (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block with a parameterized cursor:
-- 1. Declare cursor that accepts a rating parameter
-- 2. Query films matching that rating
-- 3. First, use the cursor for 'PG' rated films (limit 5)
-- 4. Display film title, rating, and rental rate
-- 5. Then reuse the SAME cursor for 'R' rated films (limit 5)
--
-- This shows cursor reusability!
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    -- Parameterized cursor with ONE parameter
    films_by_rating CURSOR(p_rating film.rating%TYPE) FOR
        SELECT film_id, title, rating, rental_rate
        FROM film
        WHERE rating = ___  -- Fill in the parameter name
        ORDER BY title
        LIMIT 5;
    
    film_rec RECORD;
BEGIN
    RAISE NOTICE '=== PG RATED FILMS ===';
    FOR film_rec IN films_by_rating('___') LOOP  -- Fill in 'PG'
        RAISE NOTICE '"%": % - $%', 
            film_rec.title, film_rec.___, film_rec.rental_rate;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== R RATED FILMS ===';
    FOR film_rec IN films_by_rating('___') LOOP  -- Fill in 'R'
        RAISE NOTICE '"%": % - $%', 
            film_rec.___, film_rec.rating, film_rec.rental_rate;
    END LOOP;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 4.2: Multiple Parameter Cursor (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block with a cursor accepting TWO parameters:
-- 1. Cursor parameters: minimum rental rate and minimum length
-- 2. Find films matching both criteria
-- 3. Test with: rate >= 2.99 AND length >= 120 minutes
-- 4. Display title, rental rate, and length
-- 5. Limit to 10 films
-- 6. Calculate and display average rental rate of these films
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    -- TODO: Declare cursor with multiple parameters
    
    -- TODO: Declare variables for calculations
    
BEGIN
    -- TODO: Use cursor with parameters
    
    -- TODO: Calculate average rate
    
    -- TODO: Display results
    
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 4.3: City-Based Customer Cursor (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Creates a cursor accepting a city name parameter
-- 2. Finds all customers in that city
-- 3. First test with 'London' (limit 5 customers)
-- 4. Then reuse for 'Woodridge' (limit 5 customers)
-- 5. Display customer name, email, and city
-- 6. Count total customers in each city
--
-- Hint: Need to join customer → address → city tables
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    -- TODO: Declare parameterized cursor
    
    -- TODO: Declare variables
    
BEGIN
    -- TODO: Process London customers
    
    -- TODO: Process Woodridge customers
    
    -- TODO: Display counts
    
END $$;


-- ============================================================================
-- PART 5: ADVANCED CURSOR SCENARIOS (15 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exercise 5.1: Nested Cursors (7 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block with nested cursors:
-- 1. Outer cursor: Iterate through first 3 film categories
-- 2. Inner cursor: For each category, get top 3 highest-rated films
--    (Use rental_rate as a proxy for "rating")
-- 3. Display category name
-- 4. Display each film's title and rental rate (indented)
-- 5. Count total categories and total films processed
--
-- WARNING: Nested cursors can be slow - use carefully!
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    -- TODO: Declare outer cursor for categories
    
    -- TODO: Declare inner parameterized cursor for films
    
    -- TODO: Declare counters and RECORD variables
    
BEGIN
    -- TODO: Outer loop through categories
    
        -- TODO: Inner loop through films in each category
    
    -- TODO: Display totals
    
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 5.2: Early Exit from Cursor (4 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Searches for the first customer who has spent more than $150
-- 2. Use cursor to iterate through customers with their total spending
-- 3. When found, display customer info and EXIT the loop immediately
-- 4. Display how many customers were checked before finding one
-- 5. If no customer found after checking 50, display "Not found in first 50"
--
-- Hint: Use EXIT WHEN condition inside loop
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    customer_rec RECORD;
    customers_checked INTEGER := 0;
    high_spender_found BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=== SEARCHING FOR HIGH SPENDER (>$150) ===';
    RAISE NOTICE '';
    
    FOR customer_rec IN
        SELECT c.customer_id, c.first_name, c.last_name,
               COALESCE(SUM(p.amount), 0) AS total_spent
        FROM customer c
        LEFT JOIN payment p ON c.customer_id = p.customer_id
        GROUP BY c.customer_id, c.first_name, c.last_name
        ORDER BY c.customer_id
        LIMIT 50
    LOOP
        customers_checked := customers_checked + 1;
        
        -- Check if this customer spent more than $150
        IF customer_rec.total_spent > ___ THEN  -- Fill in threshold
            RAISE NOTICE 'FOUND! Customer: % % (ID: %)', 
                customer_rec.first_name,
                customer_rec.___,  -- Fill in last_name
                customer_rec.customer_id;
            RAISE NOTICE 'Total spent: $%', customer_rec.total_spent;
            RAISE NOTICE 'Customers checked: %', ___);  -- Fill in counter
            
            high_spender_found := ___);  -- Set to TRUE
            ___ WHEN high_spender_found;  -- Fill in EXIT keyword
        END IF;
    END LOOP;
    
    -- If no high spender found
    IF NOT high_spender_found THEN
        RAISE NOTICE 'No customer spending over $150 found in first 50 customers.';
        RAISE NOTICE 'Total customers checked: %', customers_checked;
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 5.3: Cursor with Progress Tracking (4 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Processes first 100 payments
-- 2. Every 25 payments, displays a progress message
-- 3. Accumulates total payment amount
-- 4. At the end, displays:
--    - Total payments processed
--    - Total amount
--    - Average payment
--
-- Output example:
-- "Processed 25 payments..."
-- "Processed 50 payments..."
-- "Processed 75 payments..."
-- "Processed 100 payments..."
-- "Complete! Total: $[amount], Average: $[avg]"
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    payment_rec RECORD;
    payment_count INTEGER := 0;
    total_amount NUMERIC(10,2) := 0;
    avg_amount NUMERIC(10,2);
BEGIN
    RAISE NOTICE '=== PROCESSING PAYMENTS WITH PROGRESS TRACKING ===';
    RAISE NOTICE '';
    
    FOR payment_rec IN
        SELECT payment_id, amount
        FROM payment
        ORDER BY payment_date
        LIMIT ___  -- Fill in 100
    LOOP
        payment_count := payment_count + 1;
        total_amount := total_amount + payment_rec.___);  -- Fill in amount
        
        -- Show progress every 25 payments
        IF payment_count % ___ = 0 THEN  -- Fill in 25
            RAISE NOTICE 'Processed % payments...', ___);  -- Fill in counter
        END IF;
    END LOOP;
    
    -- Calculate average
    IF payment_count > 0 THEN
        avg_amount := total_amount / ___);  -- Divide by count
    ELSE
        avg_amount := 0;
    END IF;
    
    -- Display final summary
    RAISE NOTICE '';
    RAISE NOTICE '=== COMPLETE ===';
    RAISE NOTICE 'Total payments: %', payment_count;
    RAISE NOTICE 'Total amount: $%', ___);  -- Fill in total
    RAISE NOTICE 'Average payment: $%', ROUND(avg_amount, 2);
END $$;


-- ============================================================================
-- PART 6: EXCEPTION HANDLING (10 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exercise 6.1: Handling NO_DATA_FOUND (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Attempts to SELECT INTO STRICT for customer_id = 99999 (doesn't exist)
-- 2. Catches the NO_DATA_FOUND exception
-- 3. Displays an error message
-- 4. Falls back to customer_id = 1
-- 5. Displays the fallback customer's information
-- 6. Displays success message
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    cust_id customer.customer_id%TYPE;
    cust_fname customer.first_name%TYPE;
    cust_lname customer.last_name%TYPE;
    invalid_id INTEGER := 99999;
    fallback_id INTEGER := 1;
BEGIN
    -- Try to select non-existent customer
    SELECT customer_id, first_name, last_name
    INTO ___ cust_id, cust_fname, cust_lname  -- Add STRICT keyword
    FROM customer
    WHERE customer_id = ___);  -- Use invalid_id
    
    RAISE NOTICE 'Found customer: % %', cust_fname, cust_lname;
    
EXCEPTION
    WHEN ___ THEN  -- Fill in exception name
        RAISE NOTICE 'ERROR: Customer ID % not found!', invalid_id;
        RAISE NOTICE 'Attempting fallback to customer ID %...', fallback_id;
        
        -- Fallback query
        SELECT customer_id, first_name, last_name
        INTO cust_id, cust_fname, cust_lname
        FROM customer
        WHERE customer_id = ___);  -- Use fallback_id
        
        RAISE NOTICE 'SUCCESS: Fallback customer - % %', cust_fname, cust_lname;
END $$;


-- ----------------------------------------------------------------------------
-- Exercise 6.2: Handling TOO_MANY_ROWS (5 points)
-- ----------------------------------------------------------------------------
-- TODO: Write a DO block that:
-- 1. Uses SELECT INTO STRICT for customers with first_name LIKE 'MARY%'
-- 2. This will return multiple rows and raise TOO_MANY_ROWS exception
-- 3. Catch the exception
-- 4. Display how many rows matched (use a separate query)
-- 5. Display the message: "Please provide more specific criteria"
-- 6. Show the first 3 matching customer names
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    cust_id customer.customer_id%TYPE;
    cust_fname customer.first_name%TYPE;
    cust_lname customer.last_name%TYPE;
    match_count INTEGER;
    sample_rec RECORD;
BEGIN
    -- This will fail with TOO_MANY_ROWS
    SELECT customer_id, first_name, last_name
    INTO ___ cust_id, cust_fname, cust_lname  -- Add STRICT
    FROM customer
    WHERE first_name LIKE '___';  -- Fill in 'MARY%'
    
    RAISE NOTICE 'Customer: % %', cust_fname, cust_lname;
    
EXCEPTION
    WHEN ___ THEN  -- Fill in TOO_MANY_ROWS
        RAISE NOTICE 'ERROR: Multiple customers found!';
        
        -- Count how many matched
        SELECT COUNT(*)
        INTO match_count
        FROM customer
        WHERE first_name LIKE 'MARY%';
        
        RAISE NOTICE 'Found % customers matching this criteria', ___);  -- Fill in count
        RAISE NOTICE 'Please provide more specific criteria.';
        RAISE NOTICE '';
        RAISE NOTICE 'Sample matches (first 3):';
        
        -- Show first 3 matches
        FOR sample_rec IN
            SELECT first_name, last_name
            FROM customer
            WHERE first_name LIKE '___'  -- Fill in 'MARY%'
            ORDER BY last_name
            LIMIT ___  -- Fill in 3
        LOOP
            RAISE NOTICE '  - % %', sample_rec.first_name, sample_rec.last_name;
        END LOOP;
END $$;


-- ============================================================================
-- END OF LAB 03
-- ============================================================================