# Experiment 6 – Stored Procedure, Validation Triggers and Audit Logging

## Aim
Create a stored procedure `transfer_employee(emp_id, new_dept_id)` with validation and error handling, and implement triggers for salary validation and audit logging.

## Required tasks
- Create the `transfer_employee` stored procedure.
- Validate that the employee and destination department exist.
- Handle invalid transfer cases.
- Use transaction control and error handling.
- Implement salary-validation triggers.
- Implement salary audit logging.
- Test edge cases.

## Suggested files
- `experiment-06.sql` – audit table, triggers, procedure and test calls.
- `experiment-06-record.pdf` – practical record.
- `output/` – genuine screenshots of successful calls, audit rows and expected errors.

## Verification checklist
- [ ] Procedure accepts employee ID and new department ID.
- [ ] Invalid employee and department IDs are handled.
- [ ] Same-department transfer is tested.
- [ ] Salary validation is tested.
- [ ] Salary changes are recorded in the audit table.
- [ ] Successful transfer is verified with a query joining Employee and Department.

## Run order
The supplied practical uses the CompanyDB schema from Experiment 3. Run the prerequisite schema setup first.
