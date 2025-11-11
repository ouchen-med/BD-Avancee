-- ============================================================================
-- PostgreSQL Indexing Performance Lab
-- ============================================================================
-- Lab Duration: 60-90 minutes
-- Difficulty: Beginner to Intermediate
-- Database: Pagila (PostgreSQL sample database)
-- 
-- Lab Objectives:
--   1. Create and manage indexes
--   2. Understand different types of indexes (B-tree, function-based)
--   3. Identify slow queries using EXPLAIN ANALYZE
--   4. Measure query performance improvements
--
-- Prerequisites:
--   - PostgreSQL installed locally on Windows
--   - Pagila sample database loaded
--   - SQL client (pgAdmin, DBeaver, or psql)
--
-- ============================================================================
-- PRE-LAB CHECKLIST
-- ============================================================================
-- Before starting this lab, verify the following:
--
-- [ ] PostgreSQL is running on your local machine
--      → Open Services (services.msc) and check "postgresql-x64-XX" is Running
--      → Or run: pg_isready -h localhost
--
-- [ ] You can connect to the Pagila database
--      → Test connection in your SQL client
--      → Connection string: postgresql://postgres:password@localhost:5432/pagila
--
-- [ ] Pagila database is loaded with data
--      → Run: SELECT COUNT(*) FROM film;
--      → Expected result: 1000 films
--
-- [ ] You have permission to create indexes
--      → Run: SELECT current_user, current_database();
--      → Ensure you're connected as a superuser or database owner
--
-- [ ] Your SQL client can display EXPLAIN ANALYZE results
--      → Test with: EXPLAIN ANALYZE SELECT 1;
--      → Should show execution plan details
--
-- ✓ All checks passed? Great! You're ready to begin.
-- ============================================================================


-- ============================================================================
-- VISUAL LEARNING AIDS & CONCEPTUAL ANALOGIES
-- ============================================================================
--
-- 📚 INDEX ANALOGY: The Library Book System
-- ──────────────────────────────────────────────────────────────────────────
-- 
-- Without an Index (Sequential Scan):
--   Imagine searching for a specific book in a library with NO catalog system.
--   You must walk through EVERY AISLE and check EVERY BOOK until you find it.
--   In a library with 100,000 books, this takes HOURS! 😰
--
-- With an Index (Index Scan):
--   Now imagine the library has a card catalog (or computer system).
--   You look up the book title in the catalog → it tells you "Aisle 42, Shelf 7"
--   You walk directly there and grab the book in SECONDS! 🎯
--
-- That's exactly what a database index does!
-- ──────────────────────────────────────────────────────────────────────────
--
--
-- 🌲 B-TREE INDEX STRUCTURE (Visualized)
-- ──────────────────────────────────────────────────────────────────────────
--
--                         [M]                    ← Root Node
--                        /   \
--                       /     \
--                  [A-L]       [N-Z]             ← Internal Nodes
--                  /  \         /  \
--                 /    \       /    \
--            [A-F] [G-L]  [N-S] [T-Z]           ← Leaf Nodes
--              ↓     ↓      ↓     ↓
--           [Data] [Data] [Data] [Data]         ← Actual Row Pointers
--
-- How it works:
-- 1. Start at the root: "Is 'MATRIX' < 'M'?" → NO, go right
-- 2. Internal node: "Is 'MATRIX' < 'N'?" → YES, go left  
-- 3. Leaf node: "Is 'MATRIX' between 'A-F'?" → NO, next leaf → Found!
-- 4. Follow pointer to actual row
--
-- Efficiency: Finding 1 row in 1,000,000 rows takes only ~20 comparisons!
-- ──────────────────────────────────────────────────────────────────────────
--
--
-- ⚡ SEQUENTIAL SCAN vs INDEX SCAN (Performance Visualization)
-- ──────────────────────────────────────────────────────────────────────────
--
-- Sequential Scan (Full Table Scan):
-- ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
-- │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │ ✓ │  Checks EVERY row
-- └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
-- Time: O(n) - Linear time complexity
-- Example: 1000 rows = 1000 checks
--
-- Index Scan (Using B-Tree Index):
-- ┌───┐
-- │ ✓ │ ← Root
-- └─┬─┘
--   │
-- ┌─▼─┐
-- │ ✓ │ ← Internal Node
-- └─┬─┘
--   │
-- ┌─▼─┐
-- │ ✓ │ ← Leaf Node → [Target Row]
-- └───┘
-- Time: O(log n) - Logarithmic time complexity
-- Example: 1000 rows = ~10 checks (100x faster!)
-- ──────────────────────────────────────────────────────────────────────────
--
--
-- 🔍 FUNCTION-BASED INDEX ANALOGY
-- ──────────────────────────────────────────────────────────────────────────
--
-- Regular Index: An alphabetical catalog that sorts "Apple, Banana, Cherry"
-- 
-- Function-Based Index: A catalog that TRANSFORMS first, then sorts
--   Example: UPPER() function index
--   Stores: "APPLE, BANANA, CHERRY" (all uppercase)
--   
--   Why useful?
--   Query: WHERE UPPER(name) = 'APPLE'
--   Without function index: Must convert EVERY row to uppercase, then search
--   With function index: Pre-converted! Direct lookup! ⚡
-- ──────────────────────────────────────────────────────────────────────────
--
--
-- 📊 COMPOSITE INDEX ANALOGY: The Phone Book
-- ──────────────────────────────────────────────────────────────────────────
--
-- Composite Index on (last_name, first_name):
--   Like a phone book sorted by LAST name, then FIRST name:
--
--   SMITH, Alice
--   SMITH, Bob
--   SMITH, Charlie
--   WILSON, Alice
--   WILSON, David
--
-- Fast Searches:
--   ✓ WHERE last_name = 'SMITH'  (uses index)
--   ✓ WHERE last_name = 'SMITH' AND first_name = 'Bob'  (uses index perfectly!)
--
-- Slow Searches:
--   ✗ WHERE first_name = 'Alice'  (can't use index efficiently)
--   Why? You can't quickly find all "Alice"s in a phone book without 
--        checking every page!
--
-- Rule: Composite indexes work LEFT to RIGHT!
-- ──────────────────────────────────────────────────────────────────────────
--
-- ============================================================================


-- ============================================================================
-- PART 1: UNDERSTANDING YOUR DATABASE STRUCTURE
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Step 1.1: List All Tables
-- This shows you the available tables and their owners in the public schema
-- ----------------------------------------------------------------------------

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- QUESTION: How many tables do you see? 
-- Write down the names of at least 5 tables.
-- ANSWER: ___________________________________________________________


-- ----------------------------------------------------------------------------
-- Step 1.2: Check Existing Indexes
-- Indexes speed up queries by creating a quick lookup structure
-- Let's see what indexes already exist on some key tables
-- ----------------------------------------------------------------------------

SELECT tablename, indexname, indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
AND tablename IN ('actor', 'film', 'customer')
ORDER BY tablename, indexname;

-- QUESTION: What indexes already exist on the 'film' table?
-- ANSWER: ___________________________________________________________
------------------------------------------------
SELECT
   *
FROM
    pg_indexes
WHERE
    tablename = 'film';

------------------------------------------------
-- ----------------------------------------------------------------------------
-- Step 1.3: Examine the Film Table Structure
-- This shows column names, data types, and whether they allow NULL values
-- ----------------------------------------------------------------------------

SELECT column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'film'
ORDER BY ordinal_position;

-- Count total records in the film table
SELECT COUNT(*) AS total_films FROM film;

-- QUESTION: How many films are in the database?
-- ANSWER: ___________________________________________________________


-- ============================================================================
-- PART 2: QUERY PERFORMANCE WITHOUT INDEXES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Step 2.1: Search Without an Index
-- Let's search for a film by title and see how the database processes this
-- EXPLAIN ANALYZE shows us how PostgreSQL executes the query
-- ----------------------------------------------------------------------------

-- First, let's see what the film title actually looks like
SELECT title FROM film WHERE title LIKE 'ACADEMY%' LIMIT 1;

-- Remove any existing index on title (to start fresh)
DROP INDEX IF EXISTS  idx_film_title;

-- Search for a film by title WITHOUT an index
EXPLAIN ANALYZE
SELECT * FROM film 
WHERE title = 'ACADEMY DINOSAUR';

-- UNDERSTANDING THE OUTPUT:
-- - Seq Scan = Sequential Scan (reads the entire table row by row)
-- - cost=0.00..67.50 = Estimated cost (startup..total)
-- - actual time=X..Y = Real execution time in milliseconds
-- - rows=1 = Number of rows expected to match
-- - Rows Removed by Filter = How many rows were checked but didn't match

-- QUESTIONS:
-- 1. What was the execution time? ___________
-- 2. How many rows were removed by the filter? ___________
-- 3. Why did PostgreSQL use a Sequential Scan? ___________


-- ============================================================================
-- PART 3: QUERY PERFORMANCE WITH INDEXES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Step 3.1: Create an Index on Title
-- A B-tree index creates a sorted structure for quick lookups
-- ----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_film_title ON film(title);

-- Verify the index was created


SELECT tablename, indexname, indexdef
FROM pg_indexes 
WHERE schemaname = 'public'
AND tablename = 'film'
AND indexname = 'idx_film_title';

-- QUESTION: What type of index was created? (Check the 'indexdef' column)
-- ANSWER: ___________________________________________________________

  (b-tree)
-- ----------------------------------------------------------------------------
-- Step 3.2: Search WITH the Index
-- Run the same query again and compare the performance
-- ----------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT * FROM film 
WHERE title = 'ACADEMY DINOSAUR';

-- QUESTIONS:
-- 1. What changed in the query plan? (Look for "Index Scan")
   ANSWER: ___________Using idx_film_title________________________________________________
-- 
-- 2. What is the new execution time? _____:0.146ms______
-- 
-- 3. Calculate the speedup: (Old Time / New Time) = 4 x faster


-- ----------------------------------------------------------------------------
-- Step 3.3: Advanced EXPLAIN Options
-- PostgreSQL offers additional options for more detailed analysis
-- ----------------------------------------------------------------------------

-- VERBOSE option shows column details
EXPLAIN (ANALYZE, VERBOSE)
SELECT * FROM film 
WHERE title = 'ACADEMY DINOSAUR';

-- BUFFERS option shows memory usage
-- "shared hit" = data found in memory (fast)
-- "read" = data read from disk (slower)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM film 
WHERE title = 'ACADEMY DINOSAUR';

-- Combine both options for maximum detail
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM film 
WHERE title = 'ACADEMY DINOSAUR';

-- QUESTION: How many buffers were hit? (Look for 'Buffers: shared hit=X')
-- ANSWER: _______________  Buffers: shared hit=3____________________________________________


-- ============================================================================
-- PART 4: ANALYZING MULTI-TABLE JOINS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Step 4.1: Simple Join Query
-- This finds all films in English and sorts them by title
-- ----------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT
    f.title,
    l.name AS language
FROM film f
JOIN language l ON f.language_id = l.language_id
WHERE l.name = 'English'
ORDER BY f.title;

-- QUESTION: What is the execution time for this join query?
-- ANSWER: ________________________2.674ms___________________________________


-- ----------------------------------------------------------------------------
-- Step 4.2: Aggregation Query
-- Count films by language with filtering
-- GROUP BY aggregates data, COUNT(*) totals each group
-- ----------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT
    l.name AS language,
    COUNT(*) AS film_count
FROM film f
JOIN language l ON f.language_id = l.language_id
WHERE l.name IN ('English', 'Italian', 'Japanese')
GROUP BY l.name
ORDER BY film_count DESC;

-- QUESTION: How does the query plan handle the GROUP BY operation?
-- ANSWER: ___________________________________________________________


-- ============================================================================
-- PART 5: COMPLEX QUERY OPTIMIZATION (ADVANCED)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Step 5.1: Analyze a Complex Reporting Query (BEFORE Optimization)
-- This query generates rental statistics by category and month
-- It joins 5 tables and uses EXTRACT to get year/month from dates
-- ----------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT
    c.name AS category,
    EXTRACT(YEAR FROM r.rental_date) AS rental_year,
    EXTRACT(MONTH FROM r.rental_date) AS rental_month,
    COUNT(*) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE UPPER(c.name) IN ('ACTION', 'COMEDY', 'DRAMA')
GROUP BY
    c.name,
    EXTRACT(YEAR FROM r.rental_date),
    EXTRACT(MONTH FROM r.rental_date)
ORDER BY category, rental_year, rental_month;

-- QUESTIONS:
-- 1. Record the Planning Time: 2.275ms
-- 2. Record the Execution Time:30.363 ms
-- 3. What is the most time-consuming operation? 
--    (Look for the highest cost in the plan)
--    ANSWER: ___________________________________________________________


-- ----------------------------------------------------------------------------
-- Step 5.2: Understanding the Performance Issues
-- 
-- WHY IS THIS QUERY SLOW?
-- 1. SORTING PROBLEM: The database must sort a large amount of data for 
--    the GROUP BY, which is very time-consuming
-- 2. FUNCTION PROBLEM: The UPPER(c.name) function must be applied to 
--    every row in the category table
--
-- THE SOLUTION: Create targeted indexes!
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
-- Step 5.3: Create Strategic Indexes
-- 
-- Index 1: Function-based index on category name
-- This matches our WHERE UPPER(c.name) condition exactly
-- ----------------------------------------------------------------------------

DROP INDEX IF EXISTS idx_category_upper_name;
CREATE INDEX idx_category_upper_name ON category (UPPER(name));

-- Verify the index creation
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename = 'category'
AND indexname = 'idx_category_upper_name';

-- QUESTION: What makes the idx_category_upper_name index special?
-- (Hint: Look at the function used)
-- ANSWER: ___________________________________________________________


-- ----------------------------------------------------------------------------
-- Index 2: Index on rental_date for sorting and grouping
-- This pre-sorts the data, eliminating the slow sort operation
-- ----------------------------------------------------------------------------

DROP INDEX IF EXISTS idx_rental_date;
CREATE INDEX idx_rental_date ON rental (rental_date);

-- Verify the index creation
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename = 'rental'
AND indexname = 'idx_rental_date';


-- ----------------------------------------------------------------------------
-- Step 5.4: Re-run the Query (AFTER Optimization)
-- Run the same complex query again with our new indexes
-- ----------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT
    c.name AS category,
    EXTRACT(YEAR FROM r.rental_date) AS rental_year,
    EXTRACT(MONTH FROM r.rental_date) AS rental_month,
    COUNT(*) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE UPPER(c.name) IN ('ACTION', 'COMEDY', 'DRAMA')
GROUP BY
    c.name,
    EXTRACT(YEAR FROM r.rental_date),
    EXTRACT(MONTH FROM r.rental_date)
ORDER BY category, rental_year, rental_month;

-- QUESTIONS:
-- 1. Record the new Planning Time: _____ ms
-- 2. Record the new Execution Time: _____ ms
-- 3. Calculate the improvement: 
--    (Old Time - New Time) / Old Time × 100 = _____ %
-- 4. What changed in the query plan?
--    ANSWER: ___________________________________________________________


-- ============================================================================
-- PART 6: UNDERSTANDING SCALABILITY
-- ============================================================================

-- Check actual rental table size
SELECT COUNT(*) AS total_rentals FROM rental;

-- ----------------------------------------------------------------------------
-- Why Indexes Matter for Large Datasets
--
-- CURRENT DATA SIZE: ~16,000 rows in the rental table
--
-- SCENARIO: What if we had 5 MILLION rows?
--
-- WITHOUT Indexes (5M rows):
--   - Full table scan required
--   - Massive, slow disk-based sort
--   - ESTIMATED EXECUTION TIME: 30-180 SECONDS ⏱️
--
-- WITH Indexes (5M rows):
--   - Efficient index scan
--   - No sorting needed (data pre-sorted)
--   - ESTIMATED EXECUTION TIME: 50-200 MILLISECONDS ⚡
--
-- PERFORMANCE IMPROVEMENT: Up to 3,600x faster!
-- ----------------------------------------------------------------------------


-- ============================================================================
-- LAB EXERCISES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exercise 1: Create Your Own Index
-- Create an index on the customer table for the last_name column 
-- and measure the performance difference
-- ----------------------------------------------------------------------------

-- Step 1: Run EXPLAIN ANALYZE on a query searching by last_name (BEFORE index)
-- YOUR CODE HERE:

EXPLAIN ANALYZE
SELECT * FROM customer WHERE last_name = 'SMITH';


-- Step 2: Create an index on last_name
-- YOUR CODE HERE:

CREATE INDEX idx_customer_last_name ON customer(last_name);


-- Step 3: Run EXPLAIN ANALYZE again (AFTER index) and compare
-- YOUR CODE HERE:

EXPLAIN ANALYZE
SELECT * FROM customer WHERE last_name = 'SMITH';


-- QUESTIONS:
-- 1. Execution time BEFORE index: _____ ms
-- 2. Execution time AFTER index: _____ ms
-- 3. Performance improvement: _____ x faster


-- ----------------------------------------------------------------------------
-- Exercise 2: Multi-Column Index (Composite Index)
-- Research and create a composite index on customer(first_name, last_name)
-- Hint: CREATE INDEX idx_name ON table(column1, column2);
-- ----------------------------------------------------------------------------

-- YOUR CODE HERE:

DROP INDEX IF EXISTS idx_customer_name;
CREATE INDEX idx_customer_name ON customer(first_name, last_name);


-- Test your composite index with a query that uses both columns:
-- YOUR CODE HERE:

EXPLAIN ANALYZE
SELECT * FROM customer 
WHERE first_name = 'MARY' AND last_name = 'SMITH';




-- ----------------------------------------------------------------------------
-- Exercise 3: Analyze a Query of Your Choice
-- Choose any query that interests you from the Pagila database
-- Analyze its performance and determine if an index would help
-- ----------------------------------------------------------------------------

-- Example: Find all rentals for a specific customer
-- Your query here:
--Analyze:


EXPLAIN ANALYZE
SELECT r.rental_date, f.title
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
WHERE r.customer_id = 1
ORDER BY r.rental_date DESC;


-- Your EXPLAIN ANALYZE (BEFORE optimization):
-- (Results will appear above)


-- Your index creation (if needed):
-- Check if customer_id needs an index

DROP INDEX IF EXISTS idx_rental_customer_id;
CREATE INDEX idx_rental_customer_id ON rental(customer_id);


-- Your EXPLAIN ANALYZE (AFTER optimization):

EXPLAIN ANALYZE
SELECT r.rental_date, f.title
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
WHERE r.customer_id = 1
ORDER BY r.rental_date DESC;




-- ============================================================================
-- SUMMARY
-- ============================================================================

-- In this lab, you learned:
-- ✅ How to use EXPLAIN ANALYZE to understand query performance
-- ✅ The difference between Sequential Scan and Index Scan
-- ✅ How to create B-tree indexes
-- ✅ How to create function-based indexes (e.g., UPPER())
-- ✅ Why indexes dramatically improve performance on large datasets
-- ✅ How to read and interpret PostgreSQL query plans


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================

-- 1. Indexes create sorted lookup structures that eliminate full table scans
-- 2. EXPLAIN ANALYZE is your best friend for performance tuning
-- 3. Function-based indexes match functions in WHERE clauses exactly
-- 4. Indexes shine with scale - small datasets may not show dramatic improvements
-- 5. Not all queries need indexes - sometimes a sequential scan is optimal


-- ============================================================================
-- CLEAN UP (OPTIONAL)
-- ============================================================================

-- If you want to remove the indexes created in this lab:

-- DROP INDEX IF EXISTS idx_film_title;
-- DROP INDEX IF EXISTS idx_category_upper_name;
-- DROP INDEX IF EXISTS idx_rental_date;
-- DROP INDEX IF EXISTS idx_customer_last_name;
-- DROP INDEX IF EXISTS idx_customer_name;
-- DROP INDEX IF EXISTS idx_rental_customer_id;


-- ============================================================================
-- NEXT STEPS
-- ============================================================================

-- - Experiment with different types of indexes (GiST, GIN, BRIN)
-- - Learn about partial indexes (indexes with WHERE clauses)
-- - Study index maintenance and bloat
-- - Explore query optimization techniques beyond indexing
-- - Research composite index column ordering strategies

-- Great job completing this lab! 🎉

-- ============================================================================
-- END OF LAB
-- ============================================================================