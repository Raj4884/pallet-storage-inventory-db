-- Trigger: stop a location going over its pallet capacity.
CREATE OR REPLACE FUNCTION check_location_capacity() RETURNS trigger AS $$
DECLARE
    v_used int;
    v_cap  int;
BEGIN
    SELECT capacity_pallets INTO v_cap FROM storage_locations WHERE location_id = NEW.location_id;
    SELECT count(*) INTO v_used FROM pallets
     WHERE location_id = NEW.location_id AND status = 'IN_STOCK' AND pallet_id <> NEW.pallet_id;
    IF v_used >= v_cap THEN
        RAISE EXCEPTION 'Location % is full (% of % pallets)', NEW.location_id, v_used, v_cap;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_capacity
BEFORE INSERT OR UPDATE OF location_id ON pallets
FOR EACH ROW WHEN (NEW.location_id IS NOT NULL AND NEW.status = 'IN_STOCK')
EXECUTE FUNCTION check_location_capacity();

-- Stored function: move a pallet and write the movement record in one transaction.
CREATE OR REPLACE FUNCTION move_pallet(p_pallet_id int, p_to_location int, p_user text)
RETURNS void AS $$
DECLARE
    v_from   int;
    v_status text;
BEGIN
    SELECT location_id, status INTO v_from, v_status FROM pallets WHERE pallet_id = p_pallet_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Pallet % does not exist', p_pallet_id; END IF;
    IF v_status <> 'IN_STOCK' THEN RAISE EXCEPTION 'Pallet % is not in stock', p_pallet_id; END IF;
    UPDATE pallets SET location_id = p_to_location WHERE pallet_id = p_pallet_id;
    INSERT INTO stock_movements (pallet_id, from_location, to_location, movement_type, moved_by)
    VALUES (p_pallet_id, v_from, p_to_location, 'TRANSFER', p_user);
END;
$$ LANGUAGE plpgsql;

-- Stored function: ship a pallet out.
CREATE OR REPLACE FUNCTION ship_pallet(p_pallet_id int, p_user text)
RETURNS void AS $$
DECLARE
    v_from int;
BEGIN
    SELECT location_id INTO v_from FROM pallets WHERE pallet_id = p_pallet_id AND status = 'IN_STOCK' FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Pallet % is not in stock', p_pallet_id; END IF;
    UPDATE pallets SET status = 'SHIPPED', location_id = NULL WHERE pallet_id = p_pallet_id;
    INSERT INTO stock_movements (pallet_id, from_location, to_location, movement_type, moved_by)
    VALUES (p_pallet_id, v_from, NULL, 'SHIP', p_user);
END;
$$ LANGUAGE plpgsql;

-- Views for reporting
CREATE OR REPLACE VIEW v_location_utilisation AS
SELECT l.location_id, w.name AS warehouse, l.rack, l.bay, l.level, l.capacity_pallets,
       count(p.pallet_id) AS pallets_in_use,
       round(100.0 * count(p.pallet_id) / l.capacity_pallets, 1) AS utilisation_pct
FROM storage_locations l
JOIN warehouses w ON w.warehouse_id = l.warehouse_id
LEFT JOIN pallets p ON p.location_id = l.location_id AND p.status = 'IN_STOCK'
GROUP BY l.location_id, w.name, l.rack, l.bay, l.level, l.capacity_pallets;

CREATE OR REPLACE VIEW v_stock_by_sku AS
SELECT pr.sku, pr.name, s.name AS supplier,
       count(*) AS pallets, sum(p.qty) AS units, round(sum(p.qty * pr.unit_weight_kg), 0) AS total_kg
FROM pallets p
JOIN products pr ON pr.product_id = p.product_id
JOIN suppliers s ON s.supplier_id = pr.supplier_id
WHERE p.status = 'IN_STOCK'
GROUP BY pr.sku, pr.name, s.name;
