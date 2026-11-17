-- Pallet and storage inventory database (PostgreSQL 16)
-- Third normal form: each fact lives in one table, linked by foreign keys.
DROP TABLE IF EXISTS stock_movements, pallets, products, suppliers, storage_locations, warehouses CASCADE;

CREATE TABLE warehouses (
    warehouse_id  serial PRIMARY KEY,
    name          text NOT NULL UNIQUE,
    city          text NOT NULL
);

CREATE TABLE storage_locations (
    location_id      serial PRIMARY KEY,
    warehouse_id     int  NOT NULL REFERENCES warehouses,
    rack             char(1) NOT NULL,
    bay              int  NOT NULL CHECK (bay > 0),
    level            int  NOT NULL CHECK (level BETWEEN 1 AND 6),
    capacity_pallets int  NOT NULL CHECK (capacity_pallets > 0),
    UNIQUE (warehouse_id, rack, bay, level)
);

CREATE TABLE suppliers (
    supplier_id serial PRIMARY KEY,
    name        text NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id     serial PRIMARY KEY,
    sku            text NOT NULL UNIQUE,
    name           text NOT NULL,
    supplier_id    int  NOT NULL REFERENCES suppliers,
    unit_weight_kg numeric(8,2) NOT NULL CHECK (unit_weight_kg > 0)
);

CREATE TABLE pallets (
    pallet_id   serial PRIMARY KEY,
    product_id  int  NOT NULL REFERENCES products,
    qty         int  NOT NULL CHECK (qty > 0),
    received_on date NOT NULL,
    status      text NOT NULL DEFAULT 'IN_STOCK' CHECK (status IN ('IN_STOCK','SHIPPED')),
    location_id int  REFERENCES storage_locations,
    -- a shipped pallet has no location, an in-stock pallet must have one
    CHECK ((status = 'IN_STOCK' AND location_id IS NOT NULL) OR (status = 'SHIPPED' AND location_id IS NULL))
);
CREATE INDEX idx_pallets_location ON pallets (location_id);
CREATE INDEX idx_pallets_product  ON pallets (product_id);

CREATE TABLE stock_movements (
    movement_id   bigserial PRIMARY KEY,
    pallet_id     int  NOT NULL REFERENCES pallets,
    from_location int  REFERENCES storage_locations,
    to_location   int  REFERENCES storage_locations,
    movement_type text NOT NULL CHECK (movement_type IN ('RECEIVE','TRANSFER','SHIP')),
    moved_at      timestamptz NOT NULL DEFAULT now(),
    moved_by      text NOT NULL
);
