# Pallet and Storage Inventory Database (PostgreSQL)

A small warehouse database that tracks pallets, storage locations and every movement between them. I built it around the kind of pallet and storage data I worked with during my internship at Tata Motors. The data in this repo is randomly generated demo data, not real company data.

## What is in it

- **Schema (3NF):** warehouses, storage locations, suppliers, products, pallets and stock movements, with primary keys, foreign keys, unique constraints and CHECK rules.
- **Trigger:** a location cannot take more pallets than its capacity.
- **Stored functions:** `move_pallet()` and `ship_pallet()` change the pallet and write the movement record in one step.
- **Views:** location utilisation and stock by SKU.
- **Analytics queries:** CTEs, window functions (`SUM OVER`, `RANK`, `ROW_NUMBER`) and joins across four tables.
- **Tests:** three SQL tests that fail loudly if the trigger or the functions misbehave.
- **Index test:** the same two queries timed before and after adding indexes.

## Size and measured results

Demo data: 1,200 locations, 20,000 pallets, 500,000 movement records. Timings are `EXPLAIN ANALYZE` runs on one laptop-class machine, three runs each, PostgreSQL 16.

| Query | Without index | With index |
|---|---|---|
| Movement history of one pallet | about 22 ms | about 0.09 ms |
| Movements in the last 7 days, by type | about 41 ms | about 7 ms |

The second query gains less because it still has to read about 10,000 matching rows.

## Run it

```bash
export PGHOST=localhost PGUSER=postgres
./run.sh
```

Files run in order: `01_schema.sql`, `02_logic.sql`, `03_seed.sql`, `04_tests.sql`, `05_queries.sql`, `06_performance_test.sql`.
