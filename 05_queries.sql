-- 1. Window function: running total of pallets received per month
WITH monthly AS (
    SELECT date_trunc('month', received_on)::date AS month, count(*) AS pallets_received
    FROM pallets GROUP BY 1
)
SELECT month, pallets_received,
       sum(pallets_received) OVER (ORDER BY month) AS running_total
FROM monthly ORDER BY month;

-- 2. RANK: top 10 SKUs by units in stock, with each SKU's share of the total
SELECT sku, units,
       RANK() OVER (ORDER BY units DESC) AS rank,
       round(100.0 * units / sum(units) OVER (), 2) AS pct_of_stock
FROM v_stock_by_sku
ORDER BY rank LIMIT 10;

-- 3. CTE: pallets sitting for more than 300 days, grouped by warehouse
WITH aged AS (
    SELECT p.pallet_id, p.product_id, p.qty, p.received_on, l.warehouse_id,
           current_date - p.received_on AS days_in_stock
    FROM pallets p JOIN storage_locations l ON l.location_id = p.location_id
    WHERE p.status = 'IN_STOCK'
)
SELECT w.name AS warehouse, count(*) AS aged_pallets, round(avg(days_in_stock)) AS avg_days
FROM aged a JOIN warehouses w ON w.warehouse_id = a.warehouse_id
WHERE days_in_stock > 300
GROUP BY w.name ORDER BY aged_pallets DESC;

-- 4. ROW_NUMBER: the latest movement of every pallet that moved this week
SELECT pallet_id, movement_type, moved_at
FROM (SELECT m.*, row_number() OVER (PARTITION BY pallet_id ORDER BY moved_at DESC) AS rn
      FROM stock_movements m WHERE moved_at >= now() - interval '7 days') t
WHERE rn = 1 ORDER BY moved_at DESC LIMIT 10;

-- 5. Locations at least 75 percent full (uses the view)
SELECT warehouse, rack, bay, level, pallets_in_use, capacity_pallets, utilisation_pct
FROM v_location_utilisation WHERE utilisation_pct >= 75 ORDER BY utilisation_pct DESC, warehouse LIMIT 10;
