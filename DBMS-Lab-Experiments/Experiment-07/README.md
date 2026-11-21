# Experiment 7 – Functional Dependencies and Normalization

**Aim:** Identify functional dependencies in a denormalized Sales relation and normalize it from 1NF to 3NF and BCNF. Verify lossless join and dependency preservation.

**Relations in the final design:** `Customer`, `Salesperson`, `Product`, `SalesOrder`, `SalesItem`.

**Run:** Execute `experiment-07.sql` in MySQL 8.0+. The script creates its own database, inserts sample sales data, reconstructs the original rows through joins, and runs dependency-check queries.

**Note:** The functional dependencies and sample Sales attributes are explicitly documented in the SQL comments. 
