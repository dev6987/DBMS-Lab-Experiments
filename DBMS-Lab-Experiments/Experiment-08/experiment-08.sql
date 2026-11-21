-- ============================================================
-- EXPERIMENT 8: Transactions, Savepoints and Isolation Levels
-- MySQL 8.0+ | InnoDB
-- ============================================================
-- IMPORTANT:
-- This experiment includes statements intended for TWO separate
-- MySQL sessions. Follow the instructions in README.md.
-- ============================================================

CREATE DATABASE IF NOT EXISTS BankingDB;
USE BankingDB;

DROP TABLE IF EXISTS transaction_log;
DROP TABLE IF EXISTS bank_accounts;

CREATE TABLE bank_accounts (
    account_id INT PRIMARY KEY,
    account_holder VARCHAR(100) NOT NULL,
    balance DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_nonnegative_balance CHECK (balance >= 0)
) ENGINE = InnoDB;

CREATE TABLE transaction_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    from_account INT,
    to_account INT,
    amount DECIMAL(12,2),
    description VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

INSERT INTO bank_accounts VALUES
(1001, 'Aarav', 10000.00),
(1002, 'Diya', 8000.00),
(1003, 'Kabir', 5000.00);

-- 1. BASIC TRANSACTION: successful transfer with COMMIT.
START TRANSACTION;

UPDATE bank_accounts
SET balance = balance - 1000
WHERE account_id = 1001 AND balance >= 1000;

UPDATE bank_accounts
SET balance = balance + 1000
WHERE account_id = 1002;

INSERT INTO transaction_log
(from_account, to_account, amount, description)
VALUES (1001, 1002, 1000, 'Transfer committed');

COMMIT;

SELECT * FROM bank_accounts ORDER BY account_id;
SELECT * FROM transaction_log ORDER BY log_id;

-- 2. ROLLBACK: demonstrate that uncommitted changes are cancelled.
START TRANSACTION;

UPDATE bank_accounts
SET balance = balance - 500
WHERE account_id = 1002;

UPDATE bank_accounts
SET balance = balance + 500
WHERE account_id = 1003;

-- Undo both updates.
ROLLBACK;

SELECT * FROM bank_accounts ORDER BY account_id;

-- 3. SAVEPOINT: retain work before the savepoint and undo later work.
START TRANSACTION;

UPDATE bank_accounts
SET balance = balance - 200
WHERE account_id = 1001;

SAVEPOINT after_first_update;

UPDATE bank_accounts
SET balance = balance + 200
WHERE account_id = 1003;

-- Simulate a partial failure: undo only the second update.
ROLLBACK TO SAVEPOINT after_first_update;

-- Complete the transaction with the first update only.
-- This is a demonstration of savepoint behavior, not a real transfer.
COMMIT;

SELECT * FROM bank_accounts ORDER BY account_id;

-- 4. ISOLATION LEVELS.
-- Run these session-specific statements separately as described
-- in README.md. MySQL InnoDB supports READ UNCOMMITTED,
-- READ COMMITTED, REPEATABLE READ and SERIALIZABLE.

-- Example setting for the current session:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Start a transaction to inspect a consistent read.
START TRANSACTION;
SELECT account_id, balance
FROM bank_accounts
WHERE account_id = 1001;

-- In a second session, update and COMMIT account 1001.
-- Repeat the SELECT above to observe READ COMMITTED behavior.
COMMIT;

-- 5. LOCKING READ EXAMPLE.
-- SELECT ... FOR UPDATE obtains an exclusive row lock for the
-- selected account until COMMIT or ROLLBACK.
START TRANSACTION;

SELECT account_id, balance
FROM bank_accounts
WHERE account_id = 1001
FOR UPDATE;

-- Perform a controlled update while holding the row lock.
UPDATE bank_accounts
SET balance = balance + 100
WHERE account_id = 1001;

COMMIT;

SELECT * FROM bank_accounts WHERE account_id = 1001;

-- 6. FINAL BALANCE CHECK.
SELECT
    SUM(balance) AS total_money_in_accounts
FROM bank_accounts;

-- If no money was added or removed, the sum remains equal to the
-- initial total (23,000.00), apart from the intentional savepoint
-- demonstration and locking-read update which adds 100. This script
-- is designed to illustrate transaction commands and session behavior.
