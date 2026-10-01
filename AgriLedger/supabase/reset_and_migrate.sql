-- ==============================================================================
-- AgriLedger — Supabase Database Migration & Reset Script
-- Description: Drops all existing tables/data and creates clean schema for
--              Parties, Transactions, Bag Movements, Employees, Attendances,
--              Employee Payments, and Sync Queue.
-- Includes: Proper constraints, indexes, RLS policies, and updated_at triggers.
-- ==============================================================================

-- 1. DROP ALL EXISTING TABLES & OBJECTS (CASCADE to remove foreign keys & dependencies)
DROP TABLE IF EXISTS employee_payments CASCADE;
DROP TABLE IF EXISTS attendances CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS bag_movements CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS parties CASCADE;
DROP TABLE IF EXISTS sync_queue CASCADE;

-- Drop trigger function if exists
DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;

-- 2. UTILITY FUNCTION FOR AUTOMATIC updated_at TIMESTAMPS
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. CREATE TABLES

-- -----------------------------------------------------------------------------
-- 3.1 PARTIES (Farmers, Suppliers, Customers)
-- -----------------------------------------------------------------------------
CREATE TABLE parties (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    party_type VARCHAR(20) NOT NULL CHECK (party_type IN ('farmer', 'customer', 'supplier', 'trader')),
    phone VARCHAR(15),
    village VARCHAR(100),
    notes VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_parties_name ON parties(name);
CREATE INDEX idx_parties_village ON parties(village);
CREATE INDEX idx_parties_party_type ON parties(party_type);
CREATE INDEX idx_parties_is_active ON parties(is_active);
CREATE INDEX idx_parties_updated_at ON parties(updated_at);

CREATE TRIGGER trg_parties_updated_at
    BEFORE UPDATE ON parties
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 3.2 TRANSACTIONS (Grain purchases/sales, Cash in/out)
-- -----------------------------------------------------------------------------
CREATE TABLE transactions (
    id VARCHAR(36) PRIMARY KEY,
    party_id VARCHAR(36) NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,
    txn_type VARCHAR(20) NOT NULL CHECK (txn_type IN ('purchase', 'sale', 'cash_in', 'cash_out')),
    commodity VARCHAR(20),
    quantity_kg NUMERIC(10, 3),
    rate_per_kg NUMERIC(10, 2),
    amount NUMERIC(12, 2) NOT NULL,
    direction VARCHAR(5) NOT NULL CHECK (direction IN ('in', 'out')),
    payment_mode VARCHAR(10) NOT NULL DEFAULT 'cash' CHECK (payment_mode IN ('cash', 'upi', 'bank_transfer', 'cheque')),
    notes VARCHAR(500),
    voice_raw VARCHAR(1000),
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_deleted BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX idx_transactions_party_id ON transactions(party_id);
CREATE INDEX idx_transactions_entry_date ON transactions(entry_date);
CREATE INDEX idx_transactions_txn_type ON transactions(txn_type);
CREATE INDEX idx_transactions_is_deleted ON transactions(is_deleted);
CREATE INDEX idx_transactions_updated_at ON transactions(updated_at);

CREATE TRIGGER trg_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 3.3 BAG MOVEMENTS (Jute bag / Bori tracking)
-- -----------------------------------------------------------------------------
CREATE TABLE bag_movements (
    id VARCHAR(36) PRIMARY KEY,
    party_id VARCHAR(36) NOT NULL REFERENCES parties(id) ON DELETE RESTRICT,
    movement VARCHAR(10) NOT NULL CHECK (movement IN ('given', 'returned')),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    linked_txn_id VARCHAR(36) REFERENCES transactions(id) ON DELETE SET NULL,
    notes VARCHAR(500),
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_deleted BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX idx_bag_movements_party_id ON bag_movements(party_id);
CREATE INDEX idx_bag_movements_entry_date ON bag_movements(entry_date);
CREATE INDEX idx_bag_movements_is_deleted ON bag_movements(is_deleted);
CREATE INDEX idx_bag_movements_updated_at ON bag_movements(updated_at);

CREATE TRIGGER trg_bag_movements_updated_at
    BEFORE UPDATE ON bag_movements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 3.4 EMPLOYEES (Daily wage labour & staff)
-- -----------------------------------------------------------------------------
CREATE TABLE employees (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(15),
    email VARCHAR(100),
    daily_wage_rate NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    aadhaar_number VARCHAR(20),
    address VARCHAR(500),
    joining_date DATE NOT NULL DEFAULT CURRENT_DATE,
    employee_type VARCHAR(20) NOT NULL DEFAULT 'labour' CHECK (employee_type IN ('labour', 'driver', 'manager', 'accountant', 'security', 'other')),
    team_group VARCHAR(50),
    emergency_contact VARCHAR(100),
    notes VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_employees_name ON employees(name);
CREATE INDEX idx_employees_employee_type ON employees(employee_type);
CREATE INDEX idx_employees_team_group ON employees(team_group);
CREATE INDEX idx_employees_is_active ON employees(is_active);
CREATE INDEX idx_employees_updated_at ON employees(updated_at);

CREATE TRIGGER trg_employees_updated_at
    BEFORE UPDATE ON employees
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 3.5 ATTENDANCES (Daily attendance tracking)
-- -----------------------------------------------------------------------------
CREATE TABLE attendances (
    id VARCHAR(36) PRIMARY KEY,
    employee_id VARCHAR(36) NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL CHECK (status IN ('present', 'absent', 'half_day', 'overtime', 'holiday')),
    check_in_time TIME,
    check_out_time TIME,
    absence_reason VARCHAR(1000),
    voice_raw VARCHAR(1000),
    overtime_hours NUMERIC(5, 2) DEFAULT 0.00,
    notification_sent BOOLEAN NOT NULL DEFAULT false,
    notes VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_employee_attendance_date UNIQUE (employee_id, attendance_date)
);

CREATE INDEX idx_attendances_employee_id ON attendances(employee_id);
CREATE INDEX idx_attendances_attendance_date ON attendances(attendance_date);
CREATE INDEX idx_attendances_status ON attendances(status);
CREATE INDEX idx_attendances_updated_at ON attendances(updated_at);

CREATE TRIGGER trg_attendances_updated_at
    BEFORE UPDATE ON attendances
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 3.6 EMPLOYEE PAYMENTS (Wages, advances, settlements)
-- -----------------------------------------------------------------------------
CREATE TABLE employee_payments (
    id VARCHAR(36) PRIMARY KEY,
    employee_id VARCHAR(36) NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_mode VARCHAR(20) NOT NULL CHECK (payment_mode IN ('cash', 'upi', 'bank_transfer', 'cheque')),
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('wage', 'advance', 'bonus', 'deduction', 'settlement')),
    reference_number VARCHAR(100),
    notes VARCHAR(500),
    voice_raw VARCHAR(1000),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_employee_payments_employee_id ON employee_payments(employee_id);
CREATE INDEX idx_employee_payments_payment_date ON employee_payments(payment_date);
CREATE INDEX idx_employee_payments_payment_type ON employee_payments(payment_type);
CREATE INDEX idx_employee_payments_updated_at ON employee_payments(updated_at);

CREATE TRIGGER trg_employee_payments_updated_at
    BEFORE UPDATE ON employee_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 3.7 SYNC QUEUE (Server-side audit / queue tracking)
-- -----------------------------------------------------------------------------
CREATE TABLE sync_queue (
    id BIGSERIAL PRIMARY KEY,
    entity_type VARCHAR(30) NOT NULL,
    entity_id VARCHAR(36) NOT NULL,
    operation VARCHAR(10) NOT NULL,
    payload JSONB NOT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_error VARCHAR(500),
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sync_queue_lookup ON sync_queue(entity_type, created_at);
CREATE INDEX idx_sync_queue_processed ON sync_queue(processed_at);

-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- Enabling RLS and granting access to authenticated and anon roles for mobile sync

ALTER TABLE parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bag_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendances ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_queue ENABLE ROW LEVEL SECURITY;

-- Parties policies
CREATE POLICY "Allow public read parties" ON parties FOR SELECT USING (true);
CREATE POLICY "Allow public insert parties" ON parties FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update parties" ON parties FOR UPDATE USING (true);
CREATE POLICY "Allow public delete parties" ON parties FOR DELETE USING (true);

-- Transactions policies
CREATE POLICY "Allow public read transactions" ON transactions FOR SELECT USING (true);
CREATE POLICY "Allow public insert transactions" ON transactions FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update transactions" ON transactions FOR UPDATE USING (true);
CREATE POLICY "Allow public delete transactions" ON transactions FOR DELETE USING (true);

-- Bag Movements policies
CREATE POLICY "Allow public read bag_movements" ON bag_movements FOR SELECT USING (true);
CREATE POLICY "Allow public insert bag_movements" ON bag_movements FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update bag_movements" ON bag_movements FOR UPDATE USING (true);
CREATE POLICY "Allow public delete bag_movements" ON bag_movements FOR DELETE USING (true);

-- Employees policies
CREATE POLICY "Allow public read employees" ON employees FOR SELECT USING (true);
CREATE POLICY "Allow public insert employees" ON employees FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update employees" ON employees FOR UPDATE USING (true);
CREATE POLICY "Allow public delete employees" ON employees FOR DELETE USING (true);

-- Attendances policies
CREATE POLICY "Allow public read attendances" ON attendances FOR SELECT USING (true);
CREATE POLICY "Allow public insert attendances" ON attendances FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update attendances" ON attendances FOR UPDATE USING (true);
CREATE POLICY "Allow public delete attendances" ON attendances FOR DELETE USING (true);

-- Employee Payments policies
CREATE POLICY "Allow public read employee_payments" ON employee_payments FOR SELECT USING (true);
CREATE POLICY "Allow public insert employee_payments" ON employee_payments FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update employee_payments" ON employee_payments FOR UPDATE USING (true);
CREATE POLICY "Allow public delete employee_payments" ON employee_payments FOR DELETE USING (true);

-- Sync Queue policies
CREATE POLICY "Allow public read sync_queue" ON sync_queue FOR SELECT USING (true);
CREATE POLICY "Allow public insert sync_queue" ON sync_queue FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update sync_queue" ON sync_queue FOR UPDATE USING (true);
CREATE POLICY "Allow public delete sync_queue" ON sync_queue FOR DELETE USING (true);

-- 5. ENABLE REALTIME PUBLICATION
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'parties'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE parties, transactions, bag_movements, employees, attendances, employee_payments;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Continue if supabase_realtime is not configured
END $$;

-- 6. INSERT SEED DATA (Demo Farmer)
INSERT INTO parties (id, name, party_type, village, is_active, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Demo Farmer',
    'farmer',
    'Demo Village',
    true,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;
