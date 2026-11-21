# Experiment 8 – Banking Transactions and Concurrency

**Aim:** Implement banking-style transactions using `BEGIN/START TRANSACTION`, `COMMIT`, `ROLLBACK` and `SAVEPOINT`, and observe isolation/concurrency behavior using two sessions.

## Files
- `experiment-08.sql` – creates sample bank accounts and demonstrates commit, rollback, savepoint and row locking.
- This experiment also requires the two-session tests below.

## Two-session procedure

Open two separate MySQL query windows connected to `BankingDB`. Run the setup portion of the SQL file once first.

### A. READ UNCOMMITTED – dirty-read demonstration
1. Session A: `SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;`
2. Session A: `START TRANSACTION;`
3. Session B: `START TRANSACTION; UPDATE bank_accounts SET balance = balance + 700 WHERE account_id = 1001;` Do **not** commit yet.
4. Session A: `SELECT balance FROM bank_accounts WHERE account_id = 1001;` READ UNCOMMITTED may expose Session B's uncommitted value (a dirty read).
5. Session B: `ROLLBACK;`
6. Session A: run the SELECT again, then `COMMIT;`. The previously observed uncommitted value has disappeared.

### B. READ COMMITTED – non-repeatable-read demonstration
1. Session A: `SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;`
2. Session A: `START TRANSACTION;`
3. Session A: `SELECT balance FROM bank_accounts WHERE account_id = 1001;`
4. Session B: `UPDATE bank_accounts SET balance = balance + 500 WHERE account_id = 1001; COMMIT;`
5. Session A: run the same SELECT again. Under READ COMMITTED, the second read can see Session B's committed value (a non-repeatable read).
6. Session A: `COMMIT;`

### C. REPEATABLE READ – repeatable snapshot
1. Session A: `SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;`
2. Session A: `START TRANSACTION;` then SELECT account 1001.
3. Session B: update account 1001 and COMMIT.
4. Session A: repeat the SELECT. In InnoDB's default REPEATABLE READ consistent-read behavior, it normally sees the same snapshot value.
5. Session A: `COMMIT;`

### D. SERIALIZABLE / phantom and range-lock demonstration
1. Session A: `SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;`
2. Session A: `START TRANSACTION; SELECT * FROM bank_accounts WHERE balance BETWEEN 5000 AND 12000;`
3. Session B: try inserting a new account whose balance falls in that range, then COMMIT. Depending on the locking/read behavior and index plan, Session B may wait for Session A.
4. Session A: `COMMIT;` and observe whether Session B proceeds.

### E. Row-lock / blocking demonstration
1. Session A: `START TRANSACTION; SELECT * FROM bank_accounts WHERE account_id=1001 FOR UPDATE;`
2. Session B: try to update account 1001. It waits for the row lock.
3. Session A: `COMMIT;`
4. Session B's waiting update can then continue.

**Important:** Dirty reads, non-repeatable reads and phantom reads depend on the isolation level and read type. InnoDB's default REPEATABLE READ uses consistent snapshots for ordinary SELECT statements. Use two sessions and record the actual behavior observed in your MySQL version.

**Run:** MySQL 8.0+ with InnoDB tables. The SQL script contains single-session examples; the two-session concurrency steps must be performed manually in separate query windows.
