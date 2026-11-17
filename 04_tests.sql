-- Tests: each block raises an error if the behaviour is wrong.
\set ON_ERROR_STOP on
BEGIN;
-- 1. A transfer to a location with free space works and writes a movement row.
DO $$
DECLARE v_loc int; v_before int; v_after int;
BEGIN
    SELECT location_id INTO v_loc FROM v_location_utilisation WHERE pallets_in_use < capacity_pallets ORDER BY location_id LIMIT 1;
    SELECT count(*) INTO v_before FROM stock_movements;
    PERFORM move_pallet(1, v_loc, 'test_user');
    SELECT count(*) INTO v_after FROM stock_movements;
    IF (SELECT location_id FROM pallets WHERE pallet_id = 1) <> v_loc OR v_after <> v_before + 1 THEN
        RAISE EXCEPTION 'TEST 1 FAILED';
    END IF;
    RAISE NOTICE 'TEST 1 passed: transfer moved the pallet and logged it';
END $$;

-- 2. A transfer into a full location is rejected by the trigger.
DO $$
DECLARE v_full int; v_rejected boolean := false;
BEGIN
    -- fill one location to capacity first
    SELECT location_id INTO v_full FROM v_location_utilisation ORDER BY pallets_in_use DESC, location_id LIMIT 1;
    UPDATE storage_locations SET capacity_pallets = (SELECT pallets_in_use FROM v_location_utilisation WHERE location_id = v_full) WHERE location_id = v_full;
    BEGIN
        PERFORM move_pallet(2, v_full, 'test_user');
    EXCEPTION WHEN OTHERS THEN
        v_rejected := true;
        RAISE NOTICE 'TEST 2 passed: trigger said "%"', SQLERRM;
    END;
    IF NOT v_rejected THEN RAISE EXCEPTION 'TEST 2 FAILED: full location accepted a pallet'; END IF;
END $$;

-- 3. Shipping a pallet clears its location, and shipping it twice fails.
DO $$
DECLARE v_failed boolean := false;
BEGIN
    PERFORM ship_pallet(3, 'test_user');
    IF (SELECT location_id FROM pallets WHERE pallet_id = 3) IS NOT NULL THEN RAISE EXCEPTION 'TEST 3 FAILED'; END IF;
    BEGIN PERFORM ship_pallet(3, 'test_user'); EXCEPTION WHEN OTHERS THEN v_failed := true; END;
    IF NOT v_failed THEN RAISE EXCEPTION 'TEST 3 FAILED: double ship allowed'; END IF;
    RAISE NOTICE 'TEST 3 passed: ship clears location and cannot repeat';
END $$;
ROLLBACK;
