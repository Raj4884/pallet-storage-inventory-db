-- Synthetic demo data (random, not real company data).
SELECT setseed(0.42);
INSERT INTO warehouses (name, city) VALUES ('WH-Thane','Thane'),('WH-Pune','Pune'),('WH-Kolhapur','Kolhapur');

INSERT INTO storage_locations (warehouse_id, rack, bay, level, capacity_pallets)
SELECT w.warehouse_id, chr(64 + r), b, lv, 20
FROM warehouses w, generate_series(1,10) r, generate_series(1,10) b, generate_series(1,4) lv;

INSERT INTO suppliers (name) SELECT 'Supplier ' || g FROM generate_series(1,15) g;

INSERT INTO products (sku, name, supplier_id, unit_weight_kg)
SELECT 'SKU-' || lpad(g::text,4,'0'), 'Product ' || g, 1 + (g % 15), round((1 + random()*49)::numeric, 2)
FROM generate_series(1,200) g;

-- 20,000 pallets: 17,000 in stock (placed round-robin so no location overfills), 3,000 shipped
INSERT INTO pallets (product_id, qty, received_on, status, location_id)
SELECT 1 + (g % 200), 10 + (random()*490)::int, current_date - (random()*364)::int,
       CASE WHEN g <= 17000 THEN 'IN_STOCK' ELSE 'SHIPPED' END,
       CASE WHEN g <= 17000 THEN 1 + ((g-1) % 1200) END
FROM generate_series(1,20000) g;

-- 500,000 movement records for the performance test
INSERT INTO stock_movements (pallet_id, from_location, to_location, movement_type, moved_at, moved_by)
SELECT 1 + (random()*19999)::int,
       CASE WHEN t = 'RECEIVE' THEN NULL ELSE 1 + (random()*1199)::int END,
       CASE WHEN t = 'SHIP' THEN NULL ELSE 1 + (random()*1199)::int END,
       t, now() - (random()*365 || ' days')::interval, 'user_' || (1 + (random()*9)::int)
FROM (SELECT (ARRAY['RECEIVE','TRANSFER','SHIP'])[1 + (random()*2)::int] AS t FROM generate_series(1,500000)) x;
ANALYZE;
