CREATE TABLE person (
    -- It is best practice to use a primary key/ID column
    user_id SERIAL PRIMARY KEY,
    -- 'nma' for Name
    nma VARCHAR(100) NOT NULL,
    -- 'email' for Email, ensuring it is unique
    email VARCHAR(255) UNIQUE NOT NULL
);


INSERT INTO person (nma, email)
VALUES ('Mustafa Ali', 'mustafa.ali@example.com');

-- Select all columns (*) and all rows
SELECT * FROM person;

