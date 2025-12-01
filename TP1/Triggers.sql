-- ============================================================================
-- Lab 06: Database Triggers - Beginner-Friendly Version (IMPROVED)
-- Database: Pagila (DVD Rental Database)
-- ============================================================================

-- ============================================================================
-- LEARNING OBJECTIVES
-- ============================================================================
-- After completing this lab, you will be able to:
-- 1. Understand what triggers are and when to use them
-- 2. Create BEFORE and AFTER triggers
-- 3. Work with NEW and OLD variables
-- 4. Distinguish between statement-level and row-level triggers
-- 5. Implement basic audit trails and data validation
-- 6. Debug and troubleshoot trigger issues
-- ============================================================================

-- ============================================================================
-- WHAT ARE TRIGGERS?
-- ============================================================================
-- Triggers = Automatic actions that fire when data changes in your database
-- 
-- Think of them as "database robots" that watch for events and respond:
--   - You UPDATE a customer's email
--   - Trigger automatically logs the change
--   - Trigger validates the email format
--   - All without extra application code!
--
-- KEY CONCEPT: Triggers always have 2 parts in PostgreSQL:
--   1. FUNCTION (what to do)
--   2. TRIGGER (when to do it)
-- ============================================================================


-- ============================================================================
-- TRIGGER SYNTAX REFERENCE
-- ============================================================================
/*
STEP 1: Create the FUNCTION (what to do)
────────────────────────────────────────
CREATE OR REPLACE FUNCTION function_name()
RETURNS TRIGGER AS $$
BEGIN
    -- Your code here
    -- Use NEW to access new row data
    -- Use OLD to access old row data
    RETURN NEW;  -- ⚠️ REQUIRED! (or OLD, or NULL)
END;
$$ LANGUAGE plpgsql;


STEP 2: Create the TRIGGER (when to do it)
────────────────────────────────────────────
CREATE TRIGGER trigger_name
    {BEFORE | AFTER} {INSERT | UPDATE | DELETE}
    ON table_name
    {FOR EACH ROW | FOR EACH STATEMENT}
    EXECUTE FUNCTION function_name();


KEY ELEMENTS:
─────────────
TIMING:
  BEFORE  → Runs before data changes (can modify or cancel)
  AFTER   → Runs after data changes (for logging/updates)

EVENTS:
  INSERT  → When new rows are added
  UPDATE  → When rows are modified
  DELETE  → When rows are removed

LEVEL:
  FOR EACH ROW       → Fires once per affected row (has NEW/OLD)
  FOR EACH STATEMENT → Fires once per SQL statement (no NEW/OLD)

SPECIAL VARIABLES:
  NEW     → The new row data (INSERT, UPDATE)
  OLD     → The original row data (UPDATE, DELETE)
  TG_OP   → Operation type: 'INSERT', 'UPDATE', or 'DELETE'

RETURN VALUES:
  RETURN NEW;   → Proceed with the new data
  RETURN OLD;   → Use for DELETE triggers
  RETURN NULL;  → Cancel the operation (BEFORE triggers only)
*/
-- ============================================================================


-- ============================================================================
-- QUICK REFERENCE CARD
-- ============================================================================
/*
┌─────────────────┬──────────┬─────────────────────────────┐
│ Operation       │ Has NEW? │ Has OLD?                    │
├─────────────────┼──────────┼─────────────────────────────┤
│ INSERT          │ ✓ YES    │ ✗ NO                        │
│ UPDATE          │ ✓ YES    │ ✓ YES                       │
│ DELETE          │ ✗ NO     │ ✓ YES                       │
└─────────────────┴──────────┴─────────────────────────────┘

┌─────────────────┬──────────────────────────────────────┐
│ Timing          │ When to Use                          │
├─────────────────┼──────────────────────────────────────┤
│ BEFORE          │ Validate, modify, or cancel          │
│ AFTER           │ Audit, notify, update other tables   │
└─────────────────┴──────────────────────────────────────┘

RETURN VALUES GUIDE:
  RETURN NEW;   → Continue with operation (INSERT/UPDATE)
  RETURN OLD;   → Use for DELETE triggers
  RETURN NULL;  → Cancel operation (BEFORE only)
*/
-- ============================================================================


-- ============================================================================
-- SETUP: Create Practice Tables
-- ============================================================================

-- Employee table for simple examples
CREATE TABLE IF NOT EXISTS employee (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    salary NUMERIC(10,2),
    hire_date DATE DEFAULT CURRENT_DATE,
    last_modified_by VARCHAR(50),
    last_modified_at TIMESTAMP
);

--test table:
SELECT * FROM employee;
--- fin test:

-- Insert sample employees
INSERT INTO employee (first_name, last_name, email, salary) VALUES
('John', 'Doe', 'john.doe@company.com', 50000),
('Jane', 'Smith', 'jane.smith@company.com', 55000),
('Bob', 'Johnson', 'bob.johnson@company.com', 60000)
ON CONFLICT DO NOTHING;

-- Audit table for employee salary changes
CREATE TABLE IF NOT EXISTS employee_salary_audit (
    audit_id SERIAL PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    old_salary NUMERIC(10,2),
    new_salary NUMERIC(10,2),
    changed_by VARCHAR(50) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit table for customer email changes (from Pagila)
CREATE TABLE IF NOT EXISTS customer_email_audit (
    audit_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    old_email VARCHAR(255),
    new_email VARCHAR(255),
    changed_by VARCHAR(50) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PART 1: STATEMENT-LEVEL TRIGGER (Simple Example)
-- ============================================================================
-- EXAMPLE: Business Hours Validation
-- Prevents updates to employee table outside of work hours (9 AM - 5 PM)
-- This is a STATEMENT-LEVEL trigger - fires ONCE per SQL statement
-- ============================================================================

-- Step 1: Create the function
CREATE OR REPLACE FUNCTION check_business_hours()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    current_hour INTEGER;
    -- For testing purposes, you can override the hour here
    -- Set test_hour to NULL to use actual system time
    -- Set test_hour to a number (0-23) to simulate that hour
    test_hour INTEGER := 12;  -- Change to 8 or 18 to test blocking
BEGIN
    -- Use test_hour if set, otherwise use actual time
    IF test_hour IS NOT NULL THEN
        current_hour := test_hour;
        RAISE NOTICE 'TESTING MODE: Simulating hour %', current_hour;
    ELSE
        current_hour := EXTRACT(HOUR FROM CURRENT_TIMESTAMP);
        RAISE NOTICE 'Using actual hour: %', current_hour;
    END IF;
    
    -- Block updates outside 9 AM - 5 PM
    IF current_hour < NULL OR current_hour >= 17 THEN
        RAISE EXCEPTION 'Employee updates only allowed during business hours (9 AM - 5 PM). Current hour: %', 
            current_hour
        USING HINT = 'Please try again during business hours.';
    END IF;
    
    -- If we reach here, it's during working hours - allow the operation
    RAISE NOTICE 'Access granted: within business hours';
    RETURN NULL;  -- For statement-level triggers, return NULL
END;
$$;

----------------------
SELECT trigger_name 
FROM information_schema.triggers
WHERE event_object_table = 'employee';
----------------------------

-- Step 2: Create the trigger
CREATE TRIGGER enforce_business_hours
    BEFORE UPDATE ON employee
    FOR EACH STATEMENT  -- ← STATEMENT-LEVEL: fires once per UPDATE statement
    EXECUTE FUNCTION check_business_hours();


-- Test the statement-level trigger:

-- Display current time
SELECT TO_CHAR(CURRENT_TIMESTAMP, 'HH24:MI:SS') AS current_time,
       EXTRACT(HOUR FROM CURRENT_TIMESTAMP) AS current_hour;

-- Test DURING working hours (modify test_hour in function to 10 to simulate)

SELECT salary AS old_salary
FROM employee
WHERE employee_id = 1;

BEGIN;

    UPDATE employee 
    SET salary = salary + 1000 
    WHERE employee_id = 1;

    SELECT 'Update succeeded during business hours!' AS result;

    SELECT salary AS new_salary
    FROM employee
    WHERE employee_id = 1;

COMMIT;

ROLLBACK;

-- Test OUTSIDE working hours (modify test_hour in function to 18 to simulate)
-- Expected: EXCEPTION with message blocking the update
-- To test: Change test_hour to 18 in the function above, then run:
-- BEGIN;
    UPDATE employee SET salary = salary + 1000 WHERE employee_id = 1;
ROLLBACK;


-- ============================================================================
-- UNDERSTANDING: Statement-Level vs Row-Level
-- ============================================================================
/*
STATEMENT-LEVEL TRIGGER (FOR EACH STATEMENT):
──────────────────────────────────────────────
SQL: UPDATE employee SET salary = salary + 1000 WHERE department = 'Sales';
     (This affects 5 employees)

┌─────────┐
│ Row 1   │
└─────────┘
┌─────────┐
│ Row 2   │    ┌──────────────────────────────────┐
└─────────┘    │                                  │
┌─────────┐───▶│  Trigger fires ONCE for all rows │
│ Row 3   │    │  (NO access to NEW/OLD)          │
└─────────┘    └──────────────────────────────────┘
┌─────────┐
│ Row 4   │
└─────────┘
┌─────────┐
│ Row 5   │
└─────────┘

Result: Trigger executed 1 time
Access: NO access to NEW/OLD row data
Use for: Bulk validation, access control, operation logging


ROW-LEVEL TRIGGER (FOR EACH ROW):
──────────────────────────────────
SQL: UPDATE employee SET salary = salary + 1000 WHERE department = 'Sales';
     (This affects 5 employees)

┌─────────┐    ┌──────────────┐
│ Row 1   │───▶│ Trigger fires│  (has NEW.salary, OLD.salary)
└─────────┘    └──────────────┘

┌─────────┐    ┌──────────────┐
│ Row 2   │───▶│ Trigger fires│  (has NEW.salary, OLD.salary)
└─────────┘    └──────────────┘

┌─────────┐    ┌──────────────┐
│ Row 3   │───▶│ Trigger fires│  (has NEW.salary, OLD.salary)
└─────────┘    └──────────────┘

┌─────────┐    ┌──────────────┐
│ Row 4   │───▶│ Trigger fires│  (has NEW.salary, OLD.salary)
└─────────┘    └──────────────┘

┌─────────┐    ┌──────────────┐
│ Row 5   │───▶│ Trigger fires│  (has NEW.salary, OLD.salary)
└─────────┘    └──────────────┘

Result: Trigger executed 5 times (once per row)
Access: Full access to NEW and OLD row data
Use for: Row-specific validation, audit trails, calculations
*/
-- ============================================================================


-- ============================================================================
-- PART 2: ROW-LEVEL AFTER TRIGGER - Audit Trail
-- ============================================================================
-- EXAMPLE: Employee Salary Change Audit
-- Logs WHO changed a salary, WHEN, and the BEFORE/AFTER values
-- This is a ROW-LEVEL trigger - fires once PER ROW that changes
-- ============================================================================

-- Step 1: Create the audit function
CREATE OR REPLACE FUNCTION audit_salary_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert audit record with old and new salary
    INSERT INTO employee_salary_audit (
        employee_id, 
        old_salary, 
        new_salary, 
        changed_by,
        changed_at
    )
    VALUES (
        NEW.employee_id,
        OLD.salary,      -- OLD.salary = value before update
        NEW.salary,      -- NEW.salary = value after update
        CURRENT_USER,
        CURRENT_TIMESTAMP
    );
    
    -- Log what happened (helpful for debugging)
    RAISE NOTICE 'Salary changed for employee %: $% → $%', 
        NEW.employee_id, OLD.salary, NEW.salary;
    
    RETURN NEW;  -- ⚠️ REQUIRED for AFTER UPDATE trigger
END;
$$;

-- Step 2: Create the trigger
CREATE TRIGGER track_salary_changes
    AFTER UPDATE OF salary ON employee  -- Only fires when salary column changes
    FOR EACH ROW  -- ← ROW-LEVEL: fires once per updated row
    EXECUTE FUNCTION audit_salary_changes();


-- Test the row-level audit trigger:
BEGIN;
    -- View current salaries
    SELECT employee_id, first_name, last_name, salary FROM employee;
    
    -- Update ONE employee
    UPDATE employee 
    SET salary = 65000 
    WHERE employee_id = 1;
    
    -- Check audit log - ONE entry
    SELECT * FROM employee_salary_audit ORDER BY changed_at DESC LIMIT 3;
    
    -- Update MULTIPLE employees
    UPDATE employee 
    SET salary = salary + 5000 
    WHERE employee_id IN (2, 3);
    
    -- Check audit log - TWO new entries (one per row!)
    SELECT * FROM employee_salary_audit ORDER BY changed_at DESC LIMIT 3;
    
ROLLBACK;


-- ============================================================================
-- TODO EXERCISE 1: Complete the tracking trigger
-- ============================================================================
-- Goal: Track WHO modified employee records and WHEN
-- Instructions: Complete the function below to:
--   1. Set last_modified_by to CURRENT_USER
--   2. Set last_modified_at to CURRENT_TIMESTAMP
--   3. Return NEW (required!)
-- ============================================================================

CREATE OR REPLACE FUNCTION track_employee_modifications()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Set the last_modified_by column to CURRENT_USER
    NEW.last_modified_by := CURRENT_USER;
    
    -- Set the last_modified_at column to CURRENT_TIMESTAMP
    NEW.last_modified_at := CURRENT_TIMESTAMP;
    
    -- Return NEW (required!)
    RETURN NEW;
END;
$$;

-- Create the trigger (already provided)
CREATE TRIGGER auto_track_modifications
    BEFORE UPDATE ON employee
    FOR EACH ROW
    EXECUTE FUNCTION track_employee_modifications();

-- Test your trigger:
 BEGIN;
     UPDATE employee SET salary = 70000 WHERE employee_id = 1;
     SELECT employee_id, salary, last_modified_by, last_modified_at 
    FROM employee WHERE employee_id = 1;
ROLLBACK;


-- ============================================================================
-- SOLUTION FOR EXERCISE 1 (Uncomment to see answer)
-- ============================================================================
/*
CREATE OR REPLACE FUNCTION track_employee_modifications()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Set the last_modified_by column to CURRENT_USER
    NEW.last_modified_by := CURRENT_USER;
    
    -- Set the last_modified_at column to CURRENT_TIMESTAMP
    NEW.last_modified_at := CURRENT_TIMESTAMP;
    
    -- Return NEW (required!)
    RETURN NEW;
END;
$$;
*/
-- ============================================================================


-- ============================================================================
-- PART 3: ROW-LEVEL BEFORE TRIGGER - Data Validation
-- ============================================================================
-- EXAMPLE: Salary Validation
-- Prevents negative salaries and enforces minimum wage
-- BEFORE triggers can MODIFY data or CANCEL operations
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_employee_salary()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if salary is NULL
    IF NEW.salary IS NULL THEN
        RAISE EXCEPTION 'Salary cannot be NULL for employee % %', 
            NEW.first_name, NEW.last_name;
    END IF;
    
    -- Check if salary is negative
    IF NEW.salary < 0 THEN
        RAISE EXCEPTION 'Salary cannot be negative: $%', NEW.salary
        USING HINT = 'Please enter a valid positive salary amount.';
    END IF;
    
    -- Check minimum wage ($15,000 per year)
    IF NEW.salary < 15000 THEN
        RAISE EXCEPTION 'Salary $% is below minimum wage ($15,000)', NEW.salary
        USING HINT = 'Minimum annual salary is $15,000.';
    END IF;
    
    RETURN NEW;  -- Allow the operation to proceed
END;
$$;

CREATE TRIGGER check_salary_valid
    BEFORE INSERT OR UPDATE ON employee
    FOR EACH ROW
    EXECUTE FUNCTION validate_employee_salary();


-- Test salary validation:

-- Test 1: Valid salary (should succeed)
BEGIN;
    UPDATE employee SET salary = 55000 WHERE employee_id = 1;
    SELECT 'Valid salary accepted!' AS result;
ROLLBACK;

-- Test 2: Negative salary (should fail)
BEGIN;
    UPDATE employee SET salary = -1000 WHERE employee_id = 1;
ROLLBACK;

-- Test 3: Below minimum wage (should fail)
BEGIN;
    UPDATE employee SET salary = 10000 WHERE employee_id = 1;
ROLLBACK;


-- ============================================================================
-- TODO EXERCISE 2: Create an email validation trigger
-- ============================================================================
-- Goal: Validate email format before saving to employee table
-- Requirements:
--   1. Email must contain '@' character
--   2. Email must contain '.' after the '@'
--   3. Email cannot be empty
-- Hint: Use POSITION() function or LIKE operator
-- ============================================================================


CREATE OR REPLACE FUNCTION validate_employee_email()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    at_pos INTEGER;
    dot_pos INTEGER;
BEGIN
    IF NEW.email IS NULL OR TRIM(NEW.email) = '' THEN
        RAISE EXCEPTION 'Email cannot be empty';
    END IF;

    at_pos := POSITION('@' IN NEW.email);
    IF at_pos = 0 THEN
        RAISE EXCEPTION 'Email must contain @';
    END IF;

    dot_pos := POSITION('.' IN SUBSTRING(NEW.email FROM at_pos));
    IF dot_pos = 0 THEN
        RAISE EXCEPTION 'Email must contain a dot (.) after @';
    END IF;

    RETURN NEW;
END;
$$;

ROLLBACK;

-- TODO: Create the trigger (uncomment and complete)
 CREATE TRIGGER check_email_format
    BEFORE INSERT OR UPDATE OF email ON employee
    FOR EACH ROW
     EXECUTE FUNCTION validate_employee_email();

-- Test your email validation:
 BEGIN;
     UPDATE employee SET email = 'invalid-email' WHERE employee_id = 1;  -- Should fail
 ROLLBACK;

 BEGIN;
    UPDATE employee SET email = 'valid@email.com' WHERE employee_id = 1;  -- Should succeed
ROLLBACK;


-- ============================================================================
-- SOLUTION FOR EXERCISE 2 (Uncomment to see answer)
-- ============================================================================
/*
CREATE OR REPLACE FUNCTION validate_employee_email()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    at_pos INTEGER;
    dot_after_at INTEGER;
BEGIN
    -- Check if email is NULL or empty
    IF NEW.email IS NULL OR TRIM(NEW.email) = '' THEN
        RAISE EXCEPTION 'Email cannot be empty';
    END IF;
    
    -- Check if email contains '@'
    IF POSITION('@' IN NEW.email) = 0 THEN
        RAISE EXCEPTION 'Email must contain @ symbol'
        USING HINT = 'Valid email format: user@domain.com';
    END IF;
    
    -- Check if email contains '.' after '@'
    at_pos := POSITION('@' IN NEW.email);
    dot_after_at := POSITION('.' IN SUBSTRING(NEW.email FROM at_pos));
    
    IF dot_after_at = 0 THEN
        RAISE EXCEPTION 'Email must contain a domain with . after @'
        USING HINT = 'Valid email format: user@domain.com';
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER check_email_format
    BEFORE INSERT OR UPDATE OF email ON employee
    FOR EACH ROW
    EXECUTE FUNCTION validate_employee_email();
*/
-- ============================================================================


-- ============================================================================
-- PART 4: ROW-LEVEL BEFORE TRIGGER - Data Cleanup
-- ============================================================================
-- EXAMPLE: Automatic Data Normalization (from Pagila demo)
-- Automatically cleans customer data before saving
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_customer_data()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Trim whitespace from names
    NEW.first_name := TRIM(NEW.first_name);
    NEW.last_name := TRIM(NEW.last_name);
    
    -- Convert email to lowercase
    NEW.email := LOWER(TRIM(NEW.email));
    
    -- Capitalize first letter of names
    NEW.first_name := INITCAP(NEW.first_name);
    NEW.last_name := INITCAP(NEW.last_name);
    
    RAISE NOTICE 'Customer data cleaned: % %', NEW.first_name, NEW.last_name;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER clean_customer_data
    BEFORE INSERT OR UPDATE ON customer
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_customer_data();


-- Test data cleanup:
BEGIN;
    -- Insert messy data
    INSERT INTO customer (store_id, first_name, last_name, email, address_id)
    VALUES (1, '  JOHN  ', 'DOE  ', '  JOHN.DOE@EMAIL.COM  ', 1);
    
    -- Check what was saved - all cleaned up!
    SELECT first_name, last_name, email 
    FROM customer 
    WHERE email = 'john.doe@email.com';
ROLLBACK;


-- ============================================================================
-- TODO EXERCISE 3: Create automatic timestamp trigger
-- ============================================================================
-- Goal: Automatically update last_update column whenever customer is modified
-- Requirements:
--   1. Trigger should fire BEFORE UPDATE
--   2. Set NEW.last_update to CURRENT_TIMESTAMP
--   3. Return NEW
-- ============================================================================

CREATE OR REPLACE FUNCTION auto_update_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- TODO: Set NEW.last_update to CURRENT_TIMESTAMP
    -- Hint: NEW.last_update := CURRENT_TIMESTAMP;
    
    -- TODO: Return NEW
    -- Hint: RETURN NEW;

  
    -- Set NEW.last_update to CURRENT_TIMESTAMP
    NEW.last_update := CURRENT_TIMESTAMP;
    
    -- Return NEW
    RETURN NEW;
END;
$$;
    


-- TODO: Create the trigger (uncomment and complete)
-- CREATE TRIGGER customer_auto_timestamp
--     BEFORE UPDATE ON customer
--     FOR EACH ROW
--     EXECUTE FUNCTION auto_update_timestamp();

CREATE TRIGGER customer_auto_timestamp
    BEFORE UPDATE ON customer
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_timestamp();
-- ============================================================================
-- SOLUTION FOR EXERCISE 3 (Uncomment to see answer)
-- ============================================================================
/*
CREATE OR REPLACE FUNCTION auto_update_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Set NEW.last_update to CURRENT_TIMESTAMP
    NEW.last_update := CURRENT_TIMESTAMP;
    
    -- Return NEW
    RETURN NEW;
END;
$$;

CREATE TRIGGER customer_auto_timestamp
    BEFORE UPDATE ON customer
    FOR EACH ROW
    EXECUTE FUNCTION auto_update_timestamp();
*/
-- ============================================================================


-- ============================================================================
-- PART 5: ROW-LEVEL AFTER TRIGGER - Customer Email Audit (Pagila)
-- ============================================================================
-- EXAMPLE: Track all customer email changes
-- ============================================================================

CREATE OR REPLACE FUNCTION log_customer_email_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only log if email actually changed
    IF OLD.email IS DISTINCT FROM NEW.email THEN
        -- Insert audit record
        INSERT INTO customer_email_audit (customer_id, old_email, new_email)
        VALUES (OLD.customer_id, OLD.email, NEW.email);
        
        RAISE NOTICE 'Email change logged for customer %: % → %', 
            OLD.customer_id, OLD.email, NEW.email;
    END IF;
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER audit_customer_email
    AFTER UPDATE OF email ON customer
    FOR EACH ROW
    EXECUTE FUNCTION log_customer_email_change();


-- Test customer email audit:
BEGIN;
    -- Check current email
    SELECT customer_id, email FROM customer WHERE customer_id = 1;
    
    -- Change email
    UPDATE customer SET email = 'newemail@example.com' WHERE customer_id = 1;
    
    -- Check audit log
    SELECT * FROM customer_email_audit WHERE customer_id = 1 
    ORDER BY changed_at DESC LIMIT 1;
ROLLBACK;


-- ============================================================================
-- TODO EXERCISE 4: Inventory check trigger (Pagila)
-- ============================================================================
-- Goal: Prevent film rental_rate from being set too low or too high
-- Requirements:
--   1. Rental rate must be between $0.50 and $10.00
--   2. Raise descriptive exceptions for invalid values
--   3. Use BEFORE trigger to prevent bad data
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_rental_rate()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- TODO: Check if rental_rate is NULL
    -- Hint: IF NEW.rental_rate IS NULL THEN
    --           RAISE EXCEPTION 'Rental rate cannot be NULL';
    --       END IF;
    
    -- TODO: Check if rental_rate < 0.50 (too low)
    -- Hint: IF NEW.rental_rate < 0.50 THEN
    --           RAISE EXCEPTION 'Rental rate $% is too low. Minimum is $0.50', NEW.rental_rate;
    --       END IF;
    
    -- TODO: Check if rental_rate > 10.00 (too high)
    -- Hint: IF NEW.rental_rate > 10.00 THEN
    --           RAISE EXCEPTION 'Rental rate $% is too high. Maximum is $10.00', NEW.rental_rate;
    --       END IF;
    
    -- TODO: Return NEW if all validations pass
    -- Hint: RETURN NEW;
    
END;
$$;

-- TODO: Create the trigger
-- CREATE TRIGGER check_rental_rate
--     BEFORE INSERT OR UPDATE OF rental_rate ON film
--     FOR EACH ROW
--     EXECUTE FUNCTION validate_rental_rate();


-- ============================================================================
-- SOLUTION FOR EXERCISE 4 (Uncomment to see answer)
-- ============================================================================
/*
CREATE OR REPLACE FUNCTION validate_rental_rate()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if rental_rate is NULL
    IF NEW.rental_rate IS NULL THEN
        RAISE EXCEPTION 'Rental rate cannot be NULL';
    END IF;
    
    -- Check if rental_rate < 0.50 (too low)
    IF NEW.rental_rate < 0.50 THEN
        RAISE EXCEPTION 'Rental rate $% is too low. Minimum is $0.50', NEW.rental_rate
        USING HINT = 'Rental rates must be at least $0.50';
    END IF;
    
    -- Check if rental_rate > 10.00 (too high)
    IF NEW.rental_rate > 10.00 THEN
        RAISE EXCEPTION 'Rental rate $% is too high. Maximum is $10.00', NEW.rental_rate
        USING HINT = 'Rental rates cannot exceed $10.00';
    END IF;
    
    -- Return NEW if all validations pass
    RETURN NEW;
END;
$$;

CREATE TRIGGER check_rental_rate
    BEFORE INSERT OR UPDATE OF rental_rate ON film
    FOR EACH ROW
    EXECUTE FUNCTION validate_rental_rate();
*/
-- ============================================================================


-- ============================================================================
-- PART 6: Understanding NEW and OLD
-- ============================================================================
/*
AVAILABILITY OF NEW AND OLD BY OPERATION:
─────────────────────────────────────────

INSERT:
  NEW exists (the new row being inserted)
  OLD does NOT exist (no previous data)
  Example: NEW.salary = 50000

UPDATE:
  NEW exists (the updated values)
  OLD exists (the original values)
  Example: OLD.salary = 50000, NEW.salary = 55000

DELETE:
  NEW does NOT exist (nothing new)
  OLD exists (the row being deleted)
  Example: OLD.salary = 50000
  

COMMON MISTAKE:
───────────────
-- ❌ WRONG: Using NEW in DELETE trigger
CREATE FUNCTION bad_delete() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO log VALUES (NEW.id);  -- ERROR! NEW doesn't exist
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- ✅ CORRECT: Use OLD in DELETE trigger
CREATE FUNCTION good_delete() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO log VALUES (OLD.id);  -- Correct!
    RETURN OLD;
END; $$ LANGUAGE plpgsql;
*/
-- ============================================================================


-- ============================================================================
-- TODO EXERCISE 5: Handle multiple operations with TG_OP
-- ============================================================================
-- Goal: Create a comprehensive audit trigger for employee table
-- Requirements:
--   1. Handle INSERT, UPDATE, and DELETE
--   2. Use TG_OP to detect which operation occurred
--   3. Store appropriate data based on operation type
-- ============================================================================

CREATE TABLE IF NOT EXISTS employee_audit_log (
    audit_id SERIAL PRIMARY KEY,
    employee_id INTEGER,
    operation CHAR(1),  -- 'I'nsert, 'U'pdate, 'D'elete
    old_data JSONB,
    new_data JSONB,
    changed_by VARCHAR(50) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION audit_employee_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- TODO: Check if TG_OP = 'DELETE'
    --       Insert OLD data with operation 'D'
    --       Return OLD
    -- Hint: IF TG_OP = 'DELETE' THEN
    --           INSERT INTO employee_audit_log (employee_id, operation, old_data)
    --           VALUES (OLD.employee_id, 'D', row_to_json(OLD)::jsonb);
    --           RETURN OLD;
    --       END IF;
    
    -- TODO: Check if TG_OP = 'UPDATE'
    --       Insert both OLD and NEW data with operation 'U'
    --       Return NEW
    -- Hint: ELSIF TG_OP = 'UPDATE' THEN
    --           INSERT INTO employee_audit_log (employee_id, operation, old_data, new_data)
    --           VALUES (NEW.employee_id, 'U', row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
    --           RETURN NEW;
    --       END IF;
    
    -- TODO: Check if TG_OP = 'INSERT'
    --       Insert NEW data with operation 'I'
    --       Return NEW
    -- Hint: ELSIF TG_OP = 'INSERT' THEN
    --           INSERT INTO employee_audit_log (employee_id, operation, new_data)
    --           VALUES (NEW.employee_id, 'I', row_to_json(NEW)::jsonb);
    --           RETURN NEW;
    --       END IF;
    
    RETURN NULL;
END;
$$;

-- TODO: Create the trigger
-- CREATE TRIGGER employee_audit_trigger
--     AFTER INSERT OR UPDATE OR DELETE ON employee
--     FOR EACH ROW
--     EXECUTE FUNCTION audit_employee_changes();


-- ============================================================================
-- SOLUTION FOR EXERCISE 5 (Uncomment to see answer)
-- ============================================================================
/*
CREATE OR REPLACE FUNCTION audit_employee_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if TG_OP = 'DELETE'
    IF TG_OP = 'DELETE' THEN
        INSERT INTO employee_audit_log (employee_id, operation, old_data)
        VALUES (OLD.employee_id, 'D', row_to_json(OLD)::jsonb);
        RAISE NOTICE 'Employee % deleted', OLD.employee_id;
        RETURN OLD;
    END IF;
    
    -- Check if TG_OP = 'UPDATE'
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO employee_audit_log (employee_id, operation, old_data, new_data)
        VALUES (NEW.employee_id, 'U', row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        RAISE NOTICE 'Employee % updated', NEW.employee_id;
        RETURN NEW;
    END IF;
    
    -- Check if TG_OP = 'INSERT'
    IF TG_OP = 'INSERT' THEN
        INSERT INTO employee_audit_log (employee_id, operation, new_data)
        VALUES (NEW.employee_id, 'I', row_to_json(NEW)::jsonb);
        RAISE NOTICE 'Employee % inserted', NEW.employee_id;
        RETURN NEW;
    END IF;
    
    RETURN NULL;
END;
$$;

CREATE TRIGGER employee_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON employee
    FOR EACH ROW
    EXECUTE FUNCTION audit_employee_changes();
*/
-- ============================================================================


-- ============================================================================
-- COMMON BEGINNER MISTAKES (AND HOW TO FIX THEM!)
-- ============================================================================
/*
❌ MISTAKE 1: Forgetting RETURN
═══════════════════════════════
CREATE FUNCTION bad_trigger() RETURNS TRIGGER AS $$
BEGIN
    NEW.salary := NEW.salary * 1.1;
    -- Missing RETURN NEW;
END; $$ LANGUAGE plpgsql;

ERROR: control reached end of trigger procedure without RETURN

✅ FIX: Always include RETURN statement
CREATE FUNCTION good_trigger() RETURNS TRIGGER AS $$
BEGIN
    NEW.salary := NEW.salary * 1.1;
    RETURN NEW;  -- ← Required!
END; $$ LANGUAGE plpgsql;


❌ MISTAKE 2: Using NEW in DELETE trigger
═════════════════════════════════════════
CREATE FUNCTION bad_delete() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO log VALUES (NEW.id);  -- NEW doesn't exist!
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

ERROR: record "new" is not assigned yet

✅ FIX: Use OLD for DELETE triggers
CREATE FUNCTION good_delete() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO log VALUES (OLD.id);  -- Correct!
    RETURN OLD;  -- ← Use OLD for DELETE
END; $$ LANGUAGE plpgsql;


❌ MISTAKE 3: Using OLD in INSERT trigger
═════════════════════════════════════════
CREATE FUNCTION bad_insert() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.salary IS NULL THEN  -- OLD doesn't exist!
        NEW.salary := 30000;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

✅ FIX: Only NEW exists in INSERT
CREATE FUNCTION good_insert() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary IS NULL THEN  -- Correct!
        NEW.salary := 30000;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;


❌ MISTAKE 4: Creating infinite loops
══════════════════════════════════════
CREATE FUNCTION infinite_loop() RETURNS TRIGGER AS $$
BEGIN
    -- This UPDATE will trigger this same trigger again!
    UPDATE employee SET last_update = NOW() WHERE employee_id = NEW.employee_id;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

✅ FIX: Modify NEW directly in BEFORE trigger
CREATE FUNCTION no_loop() RETURNS TRIGGER AS $$
BEGIN
    NEW.last_update := NOW();  -- Modifies in-memory, no UPDATE needed
    RETURN NEW;
END; $$ LANGUAGE plpgsql;


❌ MISTAKE 5: Wrong RETURN for AFTER triggers
══════════════════════════════════════════════
AFTER triggers should return NEW, OLD, or NULL - the value doesn't matter
because the operation already happened. But you still must RETURN something!

-- All of these are valid for AFTER triggers:
RETURN NEW;   -- Most common
RETURN OLD;   -- Also fine
RETURN NULL;  -- Also works


❌ MISTAKE 6: Forgetting to enable trigger
═══════════════════════════════════════════
After creating a trigger, check if it's enabled:

SELECT trigger_name, status 
FROM information_schema.triggers 
WHERE event_object_table = 'employee';

If disabled, enable it:
ALTER TABLE employee ENABLE TRIGGER trigger_name;
*/
-- ============================================================================


-- ============================================================================
-- DEBUGGING TRIGGERS
-- ============================================================================
/*
When triggers don't work as expected, use these techniques:

1. ADD RAISE NOTICE STATEMENTS
   ════════════════════════════
   See what's happening inside your trigger:
   
   CREATE FUNCTION debug_trigger() RETURNS TRIGGER AS $$
   BEGIN
       RAISE NOTICE 'Trigger fired! Operation: %', TG_OP;
       RAISE NOTICE 'OLD salary: %, NEW salary: %', OLD.salary, NEW.salary;
       RAISE NOTICE 'Employee ID: %', NEW.employee_id;
       RETURN NEW;
   END; $$ LANGUAGE plpgsql;


2. CHECK IF TRIGGER EXISTS AND IS ENABLED
   ═══════════════════════════════════════
   SELECT 
       trigger_name,
       event_manipulation AS event,
       action_timing AS timing,
       action_statement
   FROM information_schema.triggers
   WHERE event_object_table = 'employee'
   ORDER BY trigger_name;


3. CHECK TRIGGER EXECUTION ORDER
   ══════════════════════════════
   Multiple triggers on same table fire in alphabetical order!
   
   -- These will fire in this order:
   CREATE TRIGGER a_first_trigger ...
   CREATE TRIGGER b_second_trigger ...
   CREATE TRIGGER c_third_trigger ...


4. TEMPORARILY DISABLE TRIGGER
   ════════════════════════════
   -- Disable to test without trigger
   ALTER TABLE employee DISABLE TRIGGER check_salary_valid;
   
   -- Run your tests
   UPDATE employee SET salary = -1000 WHERE employee_id = 1;
   
   -- Re-enable
   ALTER TABLE employee ENABLE TRIGGER check_salary_valid;


5. VIEW TRIGGER SOURCE CODE
   ═════════════════════════
   SELECT pg_get_functiondef(oid) 
   FROM pg_proc 
   WHERE proname = 'validate_employee_salary';


6. TEST IN TRANSACTION WITH ROLLBACK
   ═══════════════════════════════════
   Always test triggers safely:
   
   BEGIN;
       UPDATE employee SET salary = 100000 WHERE employee_id = 1;
       SELECT * FROM employee_salary_audit ORDER BY audit_id DESC LIMIT 1;
   ROLLBACK;  -- ← Undo everything!
*/
-- ============================================================================


-- ============================================================================
-- PERFORMANCE CONSIDERATIONS
-- ============================================================================
/*
⚠️ TRIGGERS CAN IMPACT PERFORMANCE!

SLOW: Trigger updates another table with complex JOIN
──────────────────────────────────────────────────────
CREATE FUNCTION slow_trigger() RETURNS TRIGGER AS $$
BEGIN
    -- This runs for EVERY row and does complex JOIN
    UPDATE summary_table s
    SET total = (
        SELECT SUM(amount) 
        FROM transactions t 
        JOIN accounts a ON t.account_id = a.account_id
        WHERE a.customer_id = NEW.customer_id
    )
    WHERE s.customer_id = NEW.customer_id;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

BETTER: Keep trigger logic simple, do complex work elsewhere
─────────────────────────────────────────────────────────────
CREATE FUNCTION fast_trigger() RETURNS TRIGGER AS $$
BEGIN
    -- Just insert into queue for background processing
    INSERT INTO update_queue (customer_id) VALUES (NEW.customer_id);
    RETURN NEW;
END; $$ LANGUAGE plpgsql;


PERFORMANCE TIPS:
═════════════════
✓ Keep trigger logic SIMPLE and FAST
✓ Avoid complex JOINs and subqueries in triggers
✓ Use AFTER triggers for logging (doesn't slow down main operation)
✓ Consider statement-level triggers instead of row-level when possible
✓ Be careful with triggers that update other tables
✓ Test performance with realistic data volumes

RULE OF THUMB: If trigger takes >100ms, consider alternative approaches
        such as application code, scheduled jobs, or message queues
*/
-- ============================================================================


-- ============================================================================
-- CRITICAL REMINDERS
-- ============================================================================
/*
✅ ALWAYS include RETURN statement in PostgreSQL triggers
✅ Use NEW for INSERT and UPDATE (new values)
✅ Use OLD for UPDATE and DELETE (old values)
✅ BEFORE triggers can modify data or cancel operations (RETURN NULL)
✅ AFTER triggers are for logging and side effects
✅ Test with BEGIN...ROLLBACK to avoid permanent changes
✅ Use descriptive error messages in RAISE EXCEPTION
✅ Add RAISE NOTICE for debugging
✅ Check trigger is enabled after creating it
✅ Be careful of infinite loops (trigger updating same table)

❌ Don't forget RETURN (most common beginner mistake!)
❌ Don't use NEW in DELETE triggers
❌ Don't use OLD in INSERT triggers
❌ Don't create infinite loops (trigger updates same table)
❌ Don't put complex business logic in triggers
❌ Don't forget to test performance with real data volumes
*/
-- ============================================================================


-- ============================================================================
-- MANAGING TRIGGERS
-- ============================================================================

-- View all triggers on a table
SELECT 
    trigger_name,
    event_manipulation AS event,
    action_timing AS timing,
    action_orientation AS level,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'employee'
ORDER BY trigger_name;

-- View all triggers in the database
SELECT 
    event_object_table AS table_name,
    trigger_name,
    event_manipulation AS event,
    action_timing AS timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- Disable a trigger temporarily
-- ALTER TABLE employee DISABLE TRIGGER track_salary_changes;

-- Re-enable a trigger
-- ALTER TABLE employee ENABLE TRIGGER track_salary_changes;

-- Disable ALL triggers on a table (use with caution!)
-- ALTER TABLE employee DISABLE TRIGGER ALL;

-- Drop a trigger
-- DROP TRIGGER IF EXISTS track_salary_changes ON employee;

-- Drop the function (do this AFTER dropping trigger)
-- DROP FUNCTION IF EXISTS audit_salary_changes();


-- ============================================================================
-- ANALYSIS QUESTIONS
-- ============================================================================
/*
1. What is the difference between BEFORE and AFTER triggers?
   When would you use each?

2. What is the difference between row-level and statement-level triggers?
   Give an example use case for each.

3. Why must PostgreSQL triggers always have a RETURN statement?
   What happens if you forget it?

4. When would you use RETURN NULL in a BEFORE trigger?
   What effect does this have?

5. What are the risks of creating triggers that update other tables?
   How can you avoid infinite loops?

6. Why is it important to test triggers with BEGIN...ROLLBACK?

7. What are the advantages of implementing validation at the database level
   using triggers versus in application code?

8. When might triggers hurt performance? What are some alternatives?

9. In what order do multiple triggers on the same table fire?

10. Can you have both BEFORE and AFTER triggers on the same table for
    the same operation? What happens?
*/
-- ============================================================================


-- ============================================================================
-- CLEANUP (Optional - run if you want to remove practice tables)
-- ============================================================================
/*
-- Remove triggers
DROP TRIGGER IF EXISTS enforce_business_hours ON employee;
DROP TRIGGER IF EXISTS track_salary_changes ON employee;
DROP TRIGGER IF EXISTS auto_track_modifications ON employee;
DROP TRIGGER IF EXISTS check_salary_valid ON employee;
DROP TRIGGER IF EXISTS clean_customer_data ON customer;
DROP TRIGGER IF EXISTS audit_customer_email ON customer;

-- Remove functions
DROP FUNCTION IF EXISTS check_business_hours();
DROP FUNCTION IF EXISTS audit_salary_changes();
DROP FUNCTION IF EXISTS track_employee_modifications();
DROP FUNCTION IF EXISTS validate_employee_salary();
DROP FUNCTION IF EXISTS cleanup_customer_data();
DROP FUNCTION IF EXISTS log_customer_email_change();
DROP FUNCTION IF EXISTS validate_employee_email();
DROP FUNCTION IF EXISTS auto_update_timestamp();
DROP FUNCTION IF EXISTS validate_rental_rate();
DROP FUNCTION IF EXISTS audit_employee_changes();

-- Remove tables
DROP TABLE IF EXISTS employee_audit_log;
DROP TABLE IF EXISTS employee_salary_audit;
DROP TABLE IF EXISTS customer_email_audit;
DROP TABLE IF EXISTS employee;
*/
-- ============================================================================

-- ============================================================================
-- END OF LAB 10
-- ============================================================================
-- Great job! You now understand:
-- ✓ How to create triggers in PostgreSQL (2-step process)
-- ✓ Difference between BEFORE and AFTER
-- ✓ Difference between row-level and statement-level
-- ✓ How to use NEW and OLD variables
-- ✓ How to validate data and create audit trails
-- ✓ Common mistakes and how to avoid them
-- ✓ How to debug triggers effectively
-- ✓ Performance considerations
--
-- ============================================================================