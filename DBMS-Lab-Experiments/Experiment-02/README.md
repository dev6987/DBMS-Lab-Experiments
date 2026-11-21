# Experiment 2 – ER-to-Relational Schema Conversion

## Aim
Convert the ER diagram from Experiment 1 into a relational schema and implement it using MySQL `CREATE TABLE` statements.

## Requirements
Write complete MySQL table definitions with:
- Primary keys
- Foreign keys
- `NOT NULL` constraints
- `UNIQUE` constraints
- `ON DELETE CASCADE`
- `ON DELETE SET NULL`

Insert sample data and demonstrate referential-integrity violations.

## Suggested files
- `experiment-02.sql` – complete MySQL DDL, sample inserts and constraint tests.
- `experiment-02-record.pdf` – practical record, if maintained separately.
- `output/` – genuine screenshots of successful statements and constraint errors.

## Verification checklist
- [ ] Tables reflect the relational schema derived from Experiment 1.
- [ ] Primary and foreign keys are defined.
- [ ] Required `NOT NULL` and `UNIQUE` constraints are present.
- [ ] Required delete actions are demonstrated.
- [ ] Sample data is inserted.
- [ ] Referential-integrity violations are tested and documented.

## Notes
Use the entities and relationships in your own Experiment 1 ER diagram when defining the tables. The exact relational mapping depends on the diagram.
