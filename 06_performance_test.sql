-- Measure the same two queries before and after adding indexes.
DROP INDEX IF EXISTS idx_movements_pallet_time, idx_movements_moved_at;
ANALYZE stock_movements;
\echo '=== BEFORE INDEXES ==='
\echo 'Q1: movement history of one pallet'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM stock_movements WHERE pallet_id = 4242 ORDER BY moved_at DESC;
\echo 'Q2: movements in the last 7 days by type'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT movement_type, count(*) FROM stock_movements WHERE moved_at >= now() - interval '7 days' GROUP BY movement_type;

CREATE INDEX idx_movements_pallet_time ON stock_movements (pallet_id, moved_at DESC);
CREATE INDEX idx_movements_moved_at    ON stock_movements (moved_at);
ANALYZE stock_movements;

\echo '=== AFTER INDEXES ==='
\echo 'Q1: movement history of one pallet'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM stock_movements WHERE pallet_id = 4242 ORDER BY moved_at DESC;
\echo 'Q2: movements in the last 7 days by type'
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT movement_type, count(*) FROM stock_movements WHERE moved_at >= now() - interval '7 days' GROUP BY movement_type;
