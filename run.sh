#!/usr/bin/env bash
# Builds the database from scratch, runs the tests, queries and the index timing test.
# Needs PostgreSQL 14+ and the usual PG* environment variables (PGHOST, PGUSER, ...).
set -euo pipefail
DB=${DB:-pallet_db}
dropdb --if-exists "$DB" && createdb "$DB"
for f in 01_schema.sql 02_logic.sql 03_seed.sql; do psql -d "$DB" -q -v ON_ERROR_STOP=1 -f "$f"; done
psql -d "$DB" -q -f 04_tests.sql 2>&1 | grep -E "TEST|ERROR"
psql -d "$DB" -f 05_queries.sql
psql -d "$DB" -f 06_performance_test.sql | grep -E "===|Q1|Q2|Execution Time"
