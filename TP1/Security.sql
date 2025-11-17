-- ============================================================================
-- Lab 09: Database Administration Basics - User Management and Security
-- ============================================================================
-- Lab Duration: 90-120 minutes
-- Difficulty: Intermediate
-- Database: Pagila (PostgreSQL sample database)
-- 
-- Lab Objectives:
--   1. Create and manage PostgreSQL users and roles
--   2. Grant and revoke database privileges
--   3. Organize database objects using schemas
--   4. Implement Row-Level Security (RLS) policies
--   5. Practice security verification and auditing
--
-- Prerequisites:
--   - PostgreSQL installed and running
--   - Pagila sample database loaded
--   - Connected as 'postgres' superuser
--
-- ============================================================================

-- ============================================================================
-- PRE-LAB CHECKLIST
-- ============================================================================
-- Before starting this lab, verify the following:
--
-- [ ] You are connected to the 'pagila' database
--      → Run: SELECT current_database();
--      → Expected result: pagila
--
-- [ ] You are connected as 'postgres' superuser
--      → Run: SELECT current_user;
--      → Expected result: postgres
--
-- [ ] You can view existing roles
--      → Run: SELECT COUNT(*) FROM pg_roles;
--      → Should return multiple roles
--
-- ✓ All checks passed? Great! You're ready to begin.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SECTION 1: INITIAL VERIFICATION
-- ----------------------------------------------------------------------------
-- Let's verify our connection and explore the current security state

-- VERIFY: Current database and user
SELECT current_database() AS database, current_user AS user;
-- Expected: database = pagila, user = postgres

-- EXPLORE: View all existing roles
SELECT 
    rolname,
    rolsuper,
    rolcreatedb,
    rolcanlogin,
    rolconnlimit
FROM pg_roles
ORDER BY rolname;

-- EXPLANATION:
-- rolname: Name of the role
-- rolsuper: Is this a superuser? (t = true, f = false)
-- rolcreatedb: Can create databases?
-- rolcanlogin: Can login? (if true, it's a "user")
-- rolconnlimit: Connection limit (-1 = unlimited)

-- ============================================================================
-- EXERCISE 1: BASIC USER CREATION AND PRIVILEGES (25 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1: Create a Basic User (5 points)
-- ----------------------------------------------------------------------------

-- TODO: Create a user named 'app_user' with password 'app_pass123'
CREATE USER app_user WITH PASSWORD '1234';

-- TODO: Grant CONNECT privilege on database 'pagila'
GRANT CONNECT ON DATABASE pagila TO app_user;

-- CHECKPOINT: Verify user was created
 --TODO: Query pg_roles to verify app_user exists
 SELECT rolname, rolcanlogin, rolsuper
 FROM pg_roles
WHERE rolname = 'app_user';

-- Expected output:
--  rolname  | rolcanlogin | rolsuper
-- ----------+-------------+----------
--  app_user | t           | f


-- ----------------------------------------------------------------------------
-- 1.2: Grant SELECT Privileges (10 points)
-- ----------------------------------------------------------------------------

-- TODO: Grant SELECT privilege on 'film' table to app_user
GRANT SELECT ON film TO app_user;

-- TODO: Grant SELECT privilege on 'actor' table to app_user
 GRANT SELECT ON actor TO app_user;

-- TODO: Grant SELECT privilege on 'customer' table to app_user
 GRANT SELECT ON customer TO app_user;

-- CHECKPOINT: Verify privileges were granted
-- TODO: Query information_schema.table_privileges
SELECT 
   grantee,
   table_schema,
     table_name,
   privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'app_user'
 ORDER BY table_name, privilege_type;

-- Expected: Should see SELECT on film, actor, customer

-- TEST AS APP_USER:
-- To test, you need to open a NEW connection as app_user
-- In psql: \c pagila app_user
-- Password: app_pass123

-- TEST: Try these queries (should work)
SELECT film_id, title FROM film LIMIT 5;
SELECT actor_id, first_name, last_name FROM actor LIMIT 5;

-- TEST: Try this query (should FAIL - no permission)
 SELECT * FROM payment LIMIT 5;
-- Expected error: permission denied for table payment

-- Switch back to postgres:
-- In psql: \c pagila postgres


-- ----------------------------------------------------------------------------
-- 1.3: Grant INSERT Privileges (10 points)
-- ----------------------------------------------------------------------------

-- TODO: Grant INSERT privilege on 'film' table to app_user
GRANT INSERT ON film TO app_user;

-- TODO: Grant USAGE on the film_film_id_seq sequence
-- Why? Because the film_id is SERIAL (auto-incrementing)
GRANT USAGE, SELECT ON SEQUENCE film_film_id_seq TO app_user;

-- CHECKPOINT: Verify INSERT privilege
 SELECT 
     grantee,
     table_name,
     privilege_type
 FROM information_schema.table_privileges
 WHERE grantee = 'app_user' AND table_name = 'film'
 ORDER BY privilege_type;

-- Expected: Should see both SELECT and INSERT  

-- TEST AS APP_USER:
-- Switch to app_user: \c pagila app_user

-- TEST: Try to insert a test film (should work now)
INSERT INTO film (title, language_id, rental_duration, rental_rate, replacement_cost)
 VALUES ('Test Film for Lab', 1, 3, 4.99, 19.99);

-- TEST: Verify the insert worked
SELECT film_id, title FROM film WHERE title = 'Test Film for Lab';

-- Switch back to postgres: \c pagila postgres

-- CHALLENGE QUESTION (Answer in comments):
-- Q: Why did we need to grant USAGE on the sequence?
-- A: [Your answer here]


-- ============================================================================
-- EXERCISE 2: ROLE-BASED ACCESS CONTROL (30 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1: Create a view_reader Role (10 points)
-- ----------------------------------------------------------------------------

-- CONCEPT: Instead of granting privileges to each user individually,
-- create ROLES with specific privileges, then grant roles to users.
-- This makes management much easier!

-- TODO: Create a role named 'view_reader' (NOT a user, just a role)
CREATE ROLE view_reader;

-- TODO: Grant SELECT on views to view_reader role
 GRANT SELECT ON actor_info TO view_reader;
 GRANT SELECT ON film_list TO view_reader;
 GRANT SELECT ON customer_list TO view_reader;
 GRANT SELECT ON sales_by_film_category TO view_reader;
 GRANT SELECT ON staff_list TO view_reader;

-- TODO: Grant the view_reader role to app_user
 GRANT view_reader TO app_user;

-- CHECKPOINT: Verify role membership
 SELECT 
     r.rolname AS role_name,
     m.rolname AS member_name
 FROM pg_roles r
 JOIN pg_auth_members am ON r.oid = am.roleid
 JOIN pg_roles m ON am.member = m.oid
 WHERE m.rolname = 'app_user';

-- Expected: app_user should be a member of view_reader

-- TEST AS APP_USER:
-- Switch to app_user: \c pagila app_user

-- TEST: Query a view (should work now)
 SELECT * FROM film_list LIMIT 5;
 SELECT * FROM actor_info LIMIT 5;

-- Switch back: \c pagila postgres


-- ----------------------------------------------------------------------------
-- 2.2: Create an analyst_role (10 points)
-- ----------------------------------------------------------------------------

-- TODO: Create a role named 'analyst_role'
 CREATE ROLE analyst_role;

-- TODO: Grant SELECT on ALL tables in public schema to analyst_role
-- This is a shortcut for granting SELECT on every table
 GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyst_role;

-- TODO: Create a new user named 'analyst_user' with password 'analyst_pass'
 CREATE USER analyst_user WITH PASSWORD 'analyst_pass';
 ALTER USER analyst_user WITH PASSWORD '12345';


-- TODO: Grant CONNECT privilege
 GRANT CONNECT ON DATABASE pagila TO analyst_user;

-- TODO: Grant USAGE on public schema
 GRANT USAGE ON SCHEMA public TO analyst_user;

-- TODO: Grant analyst_role to analyst_user
 

GRANT analyst_role TO analyst_user;

-- CHECKPOINT: Verify analyst_user was created and has the role
 SELECT 
     r.rolname AS role_name,
     m.rolname AS member_name
 FROM pg_roles r
 JOIN pg_auth_members am ON r.oid = am.roleid
 JOIN pg_roles m ON am.member = m.oid
 WHERE m.rolname = 'analyst_user';

-- TEST AS ANALYST_USER:
-- Switch to analyst_user:

-- TEST: Query any table (should work - has SELECT on all tables)
 SELECT * FROM payment LIMIT 5;
 SELECT * FROM rental LIMIT 5;
 SELECT * FROM inventory LIMIT 5;

-- Switch back: \c pagila postgres


-- ----------------------------------------------------------------------------
-- 2.3: Verify Role Memberships (10 points)
-- ----------------------------------------------------------------------------

-- TODO: Create a comprehensive query showing all role memberships
-- for the users we created
 SELECT 
     m.rolname AS user_name,
     r.rolname AS role_name,
     r.rolcanlogin AS role_can_login
 FROM pg_roles r
 JOIN pg_auth_members am ON r.oid = am.roleid
 JOIN pg_roles m ON am.member = m.oid
 WHERE m.rolname IN ('app_user', 'analyst_user')
ORDER BY user_name, role_name;

-- DOCUMENT: Write in comments what you learned about role hierarchy
-- Your notes:
-- 
-- DOCUMENT: Write in comments what you learned about role hierarchy
-- Your notes:

-- In PostgreSQL, roles represent users or groups of users.
-- Each role can have specific privileges on databases, tables, or sequences.
-- Roles can have a **hierarchy**, meaning one role can be a member of another role.
-- Membership in another role allows a user to **inherit the privileges** granted to the higher-level role.
-- Example: if there is a role "read_only" that grants SELECT on some tables,
-- any user who is a member of this role automatically gets the same privileges.
-- Using role hierarchy simplifies privilege management instead of granting
-- each privilege individually to every user.


-- ============================================================================
-- EXERCISE 3: SCHEMA MANAGEMENT AND ORGANIZATION (20 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1: Create a New Schema (5 points)
-- ----------------------------------------------------------------------------

-- CONCEPT: Schemas are like folders for database objects.
-- They provide organization AND security boundaries.

-- TODO: Create a schema named 'app_data'
CREATE SCHEMA app_data;

-- TODO: Grant USAGE on schema to app_user (allows access, but not creation)
 GRANT USAGE ON SCHEMA app_data TO app_user;

-- CHECKPOINT: Verify schema was created
 SELECT schema_name, schema_owner
 FROM information_schema.schemata
 WHERE schema_name = 'app_data';

-- In psql, you can also use: \dn+ app_data


-- ----------------------------------------------------------------------------
-- 3.2: Control Schema Privileges (10 points)
-- ----------------------------------------------------------------------------

-- TEST: Can app_user create a table in app_data schema?
-- Switch to app_user: \c pagila app_user

-- TRY: Create a table (should FAIL - no CREATE privilege)
 CREATE TABLE app_data.test_table (
     id SERIAL PRIMARY KEY,
     name VARCHAR(100)
 );
-- Expected error: permission denied for schema app_data

-- Switch back: \c pagila postgres

-- TODO: Grant CREATE privilege on schema app_data to app_user
-- CHECKPOINT: Verify CREATE privilege was granted
 SELECT 
     n.nspname AS schema_name,
     r.rolname AS grantee,
     p.privilege_type
 FROM pg_namespace n,
      aclexplode(n.nspacl) p
 JOIN pg_roles r ON p.grantee = r.oid
 WHERE n.nspname = 'app_data' AND r.rolname = 'app_user';

-- TEST AS APP_USER:
-- Switch to app_user:

-- TODO: Create table user_preferences in app_data schema
 CREATE TABLE app_data.user_preferences (
     user_id SERIAL PRIMARY KEY,
     username VARCHAR(100),
     theme VARCHAR(50),
     language VARCHAR(10)
 );

-- TODO: Insert test data
 INSERT INTO app_data.user_preferences (username, theme, language)
 VALUES ('alice', 'dark', 'en'), ('bob', 'light', 'fr');

-- VERIFY: Query the table
 SELECT * FROM app_data.user_preferences;

-- Switch back: \c pagila postgres


-- ----------------------------------------------------------------------------
-- 3.3: Test Schema Isolation (5 points)
-- ----------------------------------------------------------------------------

-- TEST AS ANALYST_USER:
-- Switch to analyst_user: \c pagila analyst_user

-- TRY: Query app_data.user_preferences (should FAIL - no privileges)
 SELECT * FROM app_data.user_preferences;
-- Expected error: permission denied

-- Switch back: \c pagila postgres

-- DOCUMENT: Explain why analyst_user couldn't access app_data schema
-- Your explanation:
-- 


-- ============================================================================
-- EXERCISE 4: ROW-LEVEL SECURITY (RLS) (25 points)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 4.1: Create Tasks Table with RLS (10 points)
-- ----------------------------------------------------------------------------

-- CONCEPT: Row-Level Security (RLS) filters which ROWS a user can see.
-- Even if a user has SELECT privilege on a table, RLS can restrict
-- which rows they can actually access.

-- TODO: Create tasks table in app_data schema
-- CREATE TABLE app_data.tasks (
--     task_id SERIAL PRIMARY KEY,
--     task_name VARCHAR(200) NOT NULL,
--     description TEXT,
--     assigned_to VARCHAR(100) NOT NULL,
--     completed BOOLEAN DEFAULT FALSE,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- TODO: Enable Row-Level Security on the tasks table
-- ALTER TABLE app_data.tasks ENABLE ROW LEVEL SECURITY;

-- CHECKPOINT: Verify RLS is enabled
-- SELECT 
--     schemaname,
--     tablename,
--     rowsecurity
-- FROM pg_tables
-- WHERE tablename = 'tasks' AND schemaname = 'app_data';

-- Expected: rowsecurity = t (true)

-- In psql, you can also use: \d+ app_data.tasks


-- ----------------------------------------------------------------------------
-- 4.2: Create RLS Policy (10 points)
-- ----------------------------------------------------------------------------

-- CONCEPT: A policy defines WHICH rows are visible to WHICH users.
-- The policy we'll create: users can only see rows where assigned_to matches their username.

-- TODO: Create a policy named 'user_tasks_policy'
-- CREATE POLICY user_tasks_policy ON app_data.tasks
--     FOR ALL
--     USING (assigned_to = current_user);

-- EXPLANATION:
-- - FOR ALL: Policy applies to all operations (SELECT, INSERT, UPDATE, DELETE)
-- - USING (assigned_to = current_user): Only show rows where assigned_to equals the logged-in user
-- - current_user: Special PostgreSQL function that returns the current username

-- CHECKPOINT: Verify policy was created
-- SELECT 
--     schemaname,
--     tablename,
--     policyname,
--     permissive,
--     roles,
--     cmd,
--     qual
-- FROM pg_policies
-- WHERE tablename = 'tasks' AND schemaname = 'app_data';

-- TODO: Grant privileges on tasks table
-- GRANT SELECT, INSERT, UPDATE, DELETE ON app_data.tasks TO app_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON app_data.tasks TO analyst_user;
-- GRANT USAGE, SELECT ON SEQUENCE app_data.tasks_task_id_seq TO app_user;
-- GRANT USAGE, SELECT ON SEQUENCE app_data.tasks_task_id_seq TO analyst_user;


-- ----------------------------------------------------------------------------
-- 4.3: Test RLS Policies (5 points)
-- ----------------------------------------------------------------------------

-- TODO: Insert test data as postgres (superuser)
-- Note: postgres can insert data for any user (bypasses RLS)
-- INSERT INTO app_data.tasks (task_name, description, assigned_to)
-- VALUES 
--     ('Complete security lab', 'Finish Exercise 4', 'app_user'),
--     ('Review RLS concepts', 'Understand RLS policies', 'app_user'),
--     ('Analyze query performance', 'Run EXPLAIN ANALYZE', 'analyst_user'),
--     ('Write report', 'Document findings', 'analyst_user');

-- VERIFY: As postgres, view all tasks (should see all 4)
-- SELECT task_id, task_name, assigned_to FROM app_data.tasks ORDER BY task_id;

-- TEST AS APP_USER:
-- Switch to app_user: \c pagila app_user

-- QUERY: View tasks (should only see tasks assigned to app_user)
-- SELECT task_id, task_name, assigned_to FROM app_data.tasks ORDER BY task_id;
-- Expected: Only 2 rows (both assigned_to = 'app_user')

-- TRY: Insert a task for yourself (should work)
-- INSERT INTO app_data.tasks (task_name, description, assigned_to)
-- VALUES ('My new task', 'Testing RLS INSERT', 'app_user');

-- TRY: Insert a task for someone else (will insert, but policy prevents violation)
-- INSERT INTO app_data.tasks (task_name, description, assigned_to)
-- VALUES ('Task for analyst', 'This should fail policy check', 'analyst_user');
-- Expected: Error because policy check fails on INSERT

-- Switch back: \c pagila postgres

-- TEST AS ANALYST_USER:
-- Switch to analyst_user: \c pagila analyst_user

-- QUERY: View tasks (should only see tasks assigned to analyst_user)
-- SELECT task_id, task_name, assigned_to FROM app_data.tasks ORDER BY task_id;
-- Expected: Only 2 rows (both assigned_to = 'analyst_user')

-- TRY: Update app_user's task (should have no effect - can't see those rows)
-- UPDATE app_data.tasks 
-- SET completed = TRUE 
-- WHERE assigned_to = 'app_user';
-- Result: UPDATE 0 (can't see rows with assigned_to = 'app_user')

-- Switch back: \c pagila postgres

-- DOCUMENT: Explain how RLS works and why it's useful
-- Your explanation:
-- 
-- 
-- 


-- ============================================================================
-- VERIFICATION AND MONITORING QUERIES
-- ============================================================================

-- Run these queries to verify your work:

-- 1. Check all users created in this lab
SELECT 
    rolname,
    rolcanlogin,
    rolsuper,
    rolcreatedb,
    rolconnlimit
FROM pg_roles
WHERE rolname IN ('app_user', 'analyst_user', 'view_reader', 'analyst_role')
ORDER BY rolname;

-- 2. Check all role memberships
SELECT 
    r.rolname AS role_name,
    m.rolname AS member_name
FROM pg_roles r
JOIN pg_auth_members am ON r.oid = am.roleid
JOIN pg_roles m ON am.member = m.oid
WHERE m.rolname IN ('app_user', 'analyst_user')
ORDER BY m.rolname, r.rolname;

-- 3. Check all table privileges for our users
SELECT 
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE grantee IN ('app_user', 'analyst_user', 'view_reader', 'analyst_role')
ORDER BY grantee, table_schema, table_name, privilege_type;

-- 4. Check schema privileges
SELECT 
    n.nspname AS schema_name,
    r.rolname AS grantee,
    p.privilege_type
FROM pg_namespace n,
     aclexplode(n.nspacl) p
JOIN pg_roles r ON p.grantee = r.oid
WHERE n.nspname = 'app_data' AND r.rolname IN ('app_user', 'analyst_user')
ORDER BY schema_name, grantee, privilege_type;

-- 5. Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'app_data'
ORDER BY tablename, policyname;

-- 6. Check active connections
SELECT 
    usename,
    application_name,
    client_addr,
    state,
    query_start,
    state_change
FROM pg_stat_activity
WHERE usename IN ('app_user', 'analyst_user')
ORDER BY usename, query_start DESC;


-- ============================================================================
-- CLEANUP SCRIPT
-- ============================================================================
-- Run this when you're done to remove all lab objects

-- IMPORTANT: Make sure you're connected as postgres!
-- \c pagila postgres

-- Terminate any active connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename IN ('app_user', 'analyst_user') 
AND pid <> pg_backend_pid();

-- Drop RLS policies
DROP POLICY IF EXISTS user_tasks_policy ON app_data.tasks;

-- Drop objects in app_data schema
DROP TABLE IF EXISTS app_data.tasks CASCADE;
DROP TABLE IF EXISTS app_data.user_preferences CASCADE;
DROP SCHEMA IF EXISTS app_data CASCADE;

-- Revoke all privileges
REVOKE ALL PRIVILEGES ON DATABASE pagila FROM app_user;
REVOKE ALL PRIVILEGES ON DATABASE pagila FROM analyst_user;
REVOKE view_reader FROM app_user;
REVOKE analyst_role FROM analyst_user;

-- Drop roles and users
DROP ROLE IF EXISTS view_reader;
DROP ROLE IF EXISTS analyst_role;
DROP USER IF EXISTS app_user;
DROP USER IF EXISTS analyst_user;

-- Clean up test data from film table
DELETE FROM film WHERE title = 'Test Film for Lab';

-- Verify cleanup
SELECT rolname 
FROM pg_roles 
WHERE rolname IN ('app_user', 'analyst_user', 'view_reader', 'analyst_role');
-- Expected: 0 rows

SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name = 'app_data';
-- Expected: 0 rows

-- ============================================================================
-- LAB COMPLETE!
-- ============================================================================
-- Congratulations! You have successfully:
-- ✓ Created users with different privilege levels
-- ✓ Implemented role-based access control (RBAC)
-- ✓ Organized database objects using schemas
-- ✓ Implemented Row-Level Security (RLS) policies
-- ✓ Verified security settings using system catalogs
--
-- Key Takeaways:
-- 1. Users are roles with LOGIN privilege
-- 2. Roles make privilege management easier and more maintainable
-- 3. Schemas provide organization and security boundaries
-- 4. RLS provides fine-grained row-level access control
-- 5. Always test privileges by actually connecting as the user
-- 6. Use principle of least privilege - grant only what's needed
-- ============================================================================