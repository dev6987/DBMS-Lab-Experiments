# Experiment 6 – Stored Procedure and Triggers

**Aim:** Create a validated employee-transfer procedure, enforce salary limits with triggers, and maintain a salary audit log.

## Files
- `experiment-06.sql` – audit table, BEFORE INSERT/UPDATE validation triggers, AFTER UPDATE audit trigger, stored procedure and tests.
- Add your practical PDF/Word record and genuine output screenshots to this folder.

## Run
Run Experiments 3 and 5 first. Execute this file in MySQL 8.0+. The script includes commented negative tests; uncomment and run those one at a time because they intentionally return errors.

## Corrections made for a consistent runnable setup
- The supplied practical showed a salary UPDATE test but only defined a BEFORE INSERT validation trigger. This script includes both BEFORE INSERT and BEFORE UPDATE triggers.
- The supplied audit example updated employee ID 31, but Experiment 3 creates employees 1–30. This script tests employee ID 6 instead.
- Department names are kept consistent with Experiment 3 (IT, HR, Finance, Marketing, Operations).
