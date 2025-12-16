-- Importing the CSV file into mysql

-- First create a table with every column as VARCHAR(255) to ensure there are no errors when importing

CREATE TABLE transactions_raw (
    `status` VARCHAR(255),
	card_present_flag VARCHAR(255),
    bpay_biller_code VARCHAR(255),
    `account` VARCHAR(255),
    currency VARCHAR(255),
    long_lat VARCHAR(255),
    txn_description VARCHAR(255),
    merchant_id VARCHAR(255),
    merchant_code VARCHAR(255),
    first_name VARCHAR(255),
    balance VARCHAR(255),
    `date` VARCHAR(255),
    gender VARCHAR(255),
    age VARCHAR(255),
    merchant_suburb VARCHAR(255),
    merchant_state VARCHAR(255),
    extraction VARCHAR(255),
    amount VARCHAR(255),
    transaction_id VARCHAR(255),
    country VARCHAR(255),
    customer_id VARCHAR(255),
    merchant_long_lat VARCHAR(255),
    movement VARCHAR(255)
);


-- Use the load data infile method to import the large dataset into the table

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ANZ.csv'
INTO TABLE transactions_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
IGNORE 1 LINES
(    
	`status`,
    card_present_flag,
    bpay_biller_code,
    `account`,
    currency,
    long_lat,
    txn_description,
    merchant_id,
    merchant_code,
    first_name,
    balance,
    `date`,
    gender,
    age,
    merchant_suburb,
    merchant_state,
    extraction,
    amount,
    transaction_id,
    country,
    customer_id,
    merchant_long_lat,
    movement
);

SELECT * 
FROM transactions_raw;


-- Create a duplicate of the raw table

CREATE TABLE transactions_staging
LIKE transactions_raw;

INSERT INTO transactions_staging
SELECT *
FROM transactions_raw;

SELECT *
FROM transactions_staging;


-- Data Cleaning

-- Skills used:
-- 1. Handling Duplicates
-- 2. Analysing Null Values or Blank Values
-- 3. Standardising the Data

-- 1. Check for any duplicates (transaction_id)

SELECT transaction_id, COUNT(*)
FROM transactions_staging
GROUP BY transaction_id 
HAVING COUNT(*) > 1;

-- Account, merchant_id and customer_id can have multiple transactions
-- The query above returned no result for transaction_id, thus there are no duplicate transactions 


-- 2. Null values or blank values

SELECT *
FROM transactions_staging;

SELECT *
FROM transactions_staging
WHERE card_present_flag = '';

-- Blank values are present in card_present_flag, bpay_biller_code, merchant_id, merchant_code, 
-- merchant_suburb, merchant_state and merchant_long_lat


-- Replace all blank values with NULL so we can update columns to their appropriate data types
-- INT data type allows NULL values but not blank values

UPDATE transactions_staging
SET card_present_flag = NULL
WHERE card_present_flag = '';

UPDATE transactions_staging
SET bpay_biller_code = NULL
WHERE bpay_biller_code = '';

UPDATE transactions_staging
SET merchant_id = NULL
WHERE merchant_id = '';

UPDATE transactions_staging
SET merchant_code = NULL
WHERE merchant_code = '';

UPDATE transactions_staging
SET merchant_suburb = NULL
WHERE merchant_suburb = '';

UPDATE transactions_staging
SET merchant_state = NULL
WHERE merchant_state = '';

UPDATE transactions_staging
SET merchant_long_lat = NULL
WHERE merchant_long_lat = '';


-- Check NULL values for each transaction description
-- SALES-POS, POS, PAYMENT, PAY/SALARY, INTER BANK, PHONE BANK

SELECT DISTINCT txn_description, COUNT(*)
FROM transactions_staging
GROUP BY txn_description
ORDER BY COUNT(*) DESC;

SELECT * 
FROM transactions_staging
WHERE txn_description = 'SALES-POS';

SELECT * 
FROM transactions_staging
WHERE txn_description = 'POS';

SELECT * 
FROM transactions_staging
WHERE txn_description = 'PAYMENT';

SELECT * 
FROM transactions_staging
WHERE txn_description = 'PAY/SALARY';

SELECT * 
FROM transactions_staging
WHERE txn_description = 'INTER BANK';

SELECT * 
FROM transactions_staging
WHERE txn_description = 'PHONE BANK';

-- NULLs in merchant and card fields occur naturally in non-merchant transactions (salary, transfers, phone banking)
-- and NULLs in bpay_biller_code indicate non-BPAY transactions, so they were preserved as structurally meaningful


-- 3. Standardise the data

SELECT *
FROM transactions_staging;

SELECT DISTINCT bpay_biller_code
FROM transactions_staging;

SELECT *
FROM transactions_staging
WHERE bpay_biller_code = ' THE DISCOUNT CHEMIST GROUP' 
OR bpay_biller_code = ' LAND WATER & PLANNING East Melbourne';

-- The two BPAY biller descriptions that appear only once each are genuine BPAY transactions,
-- retain them to preserve the accuracy


SELECT `date`
FROM transactions_staging;

-- Convert date column from mm/dd/yyyy to yyyy-mm-dd

UPDATE transactions_staging
SET `date` = DATE_FORMAT(STR_TO_DATE(`date`, '%m/%d/%Y'), '%Y-%m-%d')
WHERE `date` LIKE '%/%';


-- Convert date column from yyyy-dd-mm to yyyy-mm-dd

UPDATE transactions_staging
SET `date` = DATE_FORMAT(STR_TO_DATE(`date`, '%Y-%d-%m'), '%Y-%m-%d')
WHERE CAST(SUBSTRING_INDEX(`date`, '-', -1) AS UNSIGNED) <= 12;

SELECT `date`, extraction
FROM transactions_staging;


-- Convert extraction column to YYYY-MM-DD HH:MM:SS

SELECT DISTINCT extraction
FROM transactions_staging
ORDER BY extraction;

UPDATE transactions_staging
SET extraction = STR_TO_DATE(LEFT(extraction, 19), '%Y-%m-%dT%H:%i:%s');


-- Convert all relevant columns to their appropriate data types

ALTER TABLE transactions_staging
MODIFY card_present_flag TINYINT,
MODIFY currency CHAR(3),
MODIFY merchant_code INT,
MODIFY balance DECIMAL(12,2),
MODIFY `date` DATE,
MODIFY age INT,
MODIFY merchant_state CHAR(3),
MODIFY extraction DATETIME,
MODIFY amount DECIMAL(12,2);


-- Remove the hidden characters (\r) from the movement column

UPDATE transactions_staging
SET movement = TRIM(REPLACE(movement, '\r', ''));


-- Split long_lat into separate coordinate columns

ALTER TABLE transactions_staging
ADD COLUMN `long` DECIMAL(9,2) AFTER long_lat,
ADD COLUMN lat DECIMAL(9,2) AFTER `long`;

UPDATE transactions_staging
SET
  `long` = SUBSTRING_INDEX(long_lat, ' ', 1),
  lat = SUBSTRING_INDEX(long_lat, ' ', -1);

ALTER TABLE transactions_staging
DROP long_lat;


-- Split merchant_long_lat into separate coordinate columns

ALTER TABLE transactions_staging
ADD COLUMN merchant_long DECIMAL(9,2) AFTER merchant_long_lat,
ADD COLUMN merchant_lat DECIMAL(9,2) AFTER merchant_long;

UPDATE transactions_staging
SET
  merchant_long = SUBSTRING_INDEX(merchant_long_lat, ' ', 1),
  merchant_lat = SUBSTRING_INDEX(merchant_long_lat, ' ', -1);

ALTER TABLE transactions_staging
DROP merchant_long_lat;


-- Data Exploration

SELECT *
FROM transactions_staging;


-- Shows total number of customers, total number of transactions, 
-- total balance, average balance, total amount, average amount
-- Timeframe for transactions in this dataset is 3 months (2018-08-01 to 2018-10-31)

SELECT 
    MIN(`date`) AS start_date,
    MAX(`date`) AS end_date,
	COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(transaction_id) AS total_transactions,
    ROUND(SUM(balance), 2) AS total_balance,
    ROUND(AVG(balance), 2) AS avg_balance,
    ROUND(SUM(amount), 2) AS total_amount,
    ROUND(AVG(amount), 2) AS avg_amount
FROM transactions_staging;


-- Shows the percentage of debit transactions, total amount spent, average amount spent

SELECT 
	COUNT(transaction_id) AS total_transactions,
	SUM(movement = 'debit') AS total_debit,
    ROUND((SUM(movement = 'debit') /  COUNT(transaction_id)) *100, 2) AS percent_of_debit,
    ROUND(SUM(amount * (movement = 'debit')), 2) AS total_amount_spent,
	ROUND((SUM(amount * (movement = 'debit')) / SUM(movement = 'debit')), 2) AS avg_amount_spent
FROM transactions_staging;


-- Shows the percentage of credit transactions, total amount earned, average amount earned

SELECT 
	COUNT(transaction_id) AS total_transactions,
	SUM(movement = 'credit') AS total_credit,
    ROUND((SUM(movement = 'credit') /  COUNT(transaction_id)) *100, 2) AS percent_of_credit,
    ROUND(SUM(amount * (movement = 'credit')), 2) AS total_amount_earned,
	ROUND((SUM(amount * (movement = 'credit')) / SUM(movement = 'credit')), 2) AS avg_amount_earned
FROM transactions_staging;


-- Shows the total amount spent per transaction type

SELECT 
	txn_description AS transaction_type, 
	SUM(amount) AS total_amount_spent
FROM transactions_staging
WHERE movement = 'debit' 
GROUP BY txn_description
ORDER BY total_amount_spent DESC;


-- Shows the total amount spent per month

SELECT 
	MONTHNAME(`date`) AS `month`, 
	SUM(amount) AS total_amount_spent
FROM transactions_staging
WHERE movement = 'debit' 
GROUP BY MONTHNAME(`date`)
ORDER BY total_amount_spent DESC;


-- Shows the total amount spent per state

SELECT 
	merchant_state, 
	SUM(amount) AS total_amount_spent
FROM transactions_staging
WHERE movement = 'debit'
GROUP BY merchant_state
ORDER BY total_amount_spent DESC;


-- Shows the total amount spent per suburb

SELECT 
	merchant_suburb, 
	SUM(amount) AS total_amount_spent
FROM transactions_staging
WHERE movement = 'debit'
GROUP BY merchant_suburb
ORDER BY total_amount_spent DESC;


-- Shows what days of the week people spend the most (weekdays vs weekends)

SELECT 
    DAYNAME(`date`) AS day_of_week,
    SUM(amount) AS total_amount_spent
FROM transactions_staging
WHERE movement = 'debit'
GROUP BY day_of_week
ORDER BY total_amount_spent DESC;


-- Shows what days of the week people earn the most (weekdays vs weekends)

SELECT 
    DAYNAME(`date`) AS day_of_week,
    SUM(amount) AS total_amount_earned
FROM transactions_staging
WHERE movement = 'credit'
GROUP BY day_of_week
ORDER BY total_amount_earned DESC;


-- Shows which age group spends the most

SELECT DISTINCT age
FROM transactions_staging
ORDER BY age;

WITH age_group_summary AS (
	SELECT age, amount,
		CASE
			WHEN age BETWEEN 18 AND 24 THEN 'young adults'
			WHEN age BETWEEN 25 AND 34 THEN 'early career' 
			WHEN age BETWEEN 35 AND 49 THEN 'mid career' 
			ELSE 'pre-retirement and retirees' 
		END AS age_group
	FROM transactions_staging
    WHERE movement = 'debit'
)
SELECT 
	age_group, 
    SUM(amount) AS total_amount_spent
FROM age_group_summary
GROUP BY age_group
ORDER BY total_amount_spent DESC;


-- Shows what days of the week the 'mid career' age group spend the most

WITH age_group_summary AS (
	SELECT age, amount, DAYNAME(`date`) AS day_of_week,
		CASE
			WHEN age BETWEEN 18 AND 24 THEN 'young adults'
			WHEN age BETWEEN 25 AND 34 THEN 'early career' 
			WHEN age BETWEEN 35 AND 49 THEN 'mid career' 
			ELSE 'pre-retirement and retirees' 
		END AS age_group
	FROM transactions_staging
    WHERE movement = 'debit'
)
SELECT 
	age_group, 
    day_of_week,
    SUM(amount) AS total_amount_spent
FROM age_group_summary
WHERE age_group = 'mid career'
GROUP BY day_of_week
ORDER BY total_amount_spent DESC;


-- Shows whether the 'pre-retirement and retirees' age group maintain higher balances

WITH age_group_summary AS (
	SELECT age, balance,
		CASE
			WHEN age BETWEEN 18 AND 24 THEN 'young adults'
			WHEN age BETWEEN 25 AND 34 THEN 'early career' 
			WHEN age BETWEEN 35 AND 49 THEN 'mid career' 
			ELSE 'pre-retirement and retirees' 
		END AS age_group
	FROM transactions_staging
)
SELECT 
	age_group, 
    AVG(balance) AS avg_balance
FROM age_group_summary
GROUP BY age_group
ORDER BY avg_balance DESC;

-- 'mid career' age group has the highest average balance, 'pre-retirement and retirees' are second


-- Shows the customers with the highest spending amount

SELECT
	first_name,
	customer_id AS customer , 
	SUM(amount) AS total_amount_spent
FROM transactions_staging
WHERE movement = 'debit'
GROUP BY customer_id, first_name
ORDER BY total_amount_spent DESC;


-- Shows the customers with the highest balances

SELECT
	first_name,
	customer_id AS customer , 
	SUM(balance) AS total_balance
FROM transactions_staging
GROUP BY customer_id, first_name
ORDER BY total_balance DESC;


-- Shows the customers with the highest transaction frequency

SELECT
	first_name,
	customer_id AS customer , 
	COUNT(transaction_id) AS total_transactions
FROM transactions_staging
GROUP BY customer_id, first_name
ORDER BY total_transactions DESC;


-- Deep dive into balance runway
-- how many days after a salary deposit does a customer’s balance drop below a “stress” threshold
-- Balance runway = threshold date - salary date


-- Stress threshold = balance < $100

WITH salary_cycles AS (
    SELECT
		first_name,
        customer_id,
        `date`,
        balance,
        MAX(
            CASE 
                WHEN txn_description = 'PAY/SALARY'
                 AND movement = 'credit'
                THEN `date`
            END
        ) OVER (
            PARTITION BY customer_id
            ORDER BY `date`
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS salary_date
    FROM transactions_staging
),  stress_dates AS (
    SELECT
		first_name,
        customer_id,
        salary_date,
        MIN(`date`) AS stress_date
    FROM salary_cycles
    WHERE balance < 100
      AND salary_date IS NOT NULL
    GROUP BY customer_id, first_name, salary_date
)
SELECT
	first_name,
    customer_id,
    salary_date,
    stress_date,
    DATEDIFF(stress_date, salary_date) AS balance_runway_days
FROM stress_dates
ORDER BY balance_runway_days, salary_date DESC;



-- Stress threshold = balance < salary_amount * 0.05

WITH salary_cycles AS (
    SELECT
        first_name,
        customer_id,
        `date`,
        balance,

        -- carry forward last salary date
        MAX(
            CASE 
                WHEN txn_description = 'PAY/SALARY'
                 AND movement = 'credit'
                THEN `date`
            END
        ) OVER (
            PARTITION BY customer_id
            ORDER BY `date`
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS salary_date,

        -- carry forward last salary amount
        MAX(
            CASE 
                WHEN txn_description = 'PAY/SALARY'
                 AND movement = 'credit'
                THEN amount
            END
        ) OVER (
            PARTITION BY customer_id
            ORDER BY `date`
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS salary_amount

    FROM transactions_staging
),

stress_dates AS (
    SELECT
        first_name,
        customer_id,
        salary_date,
        MIN(`date`) AS stress_date
    FROM salary_cycles
    WHERE balance < salary_amount * 0.05
      AND salary_date IS NOT NULL
    GROUP BY customer_id, first_name, salary_date
)
SELECT
    first_name,
    customer_id,
    salary_date,
    stress_date,
    DATEDIFF(stress_date, salary_date) AS balance_runway_days
FROM stress_dates
ORDER BY balance_runway_days, salary_date DESC;
