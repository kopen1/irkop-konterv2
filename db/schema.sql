-- ============================================================
-- IRKOP KONTER — Database Schema (Cloudflare D1 / SQLite)
-- Database name: irkop-konter
-- outlet_id disertakan di tabel transaksional agar siap multi-cabang
-- ============================================================

-- ============ AUTH & OUTLET ============

CREATE TABLE outlets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  address TEXT,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO outlets (id, name) VALUES (1, 'Outlet Utama');

CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'kasir',        -- 'admin' | 'kasir'
  is_active INTEGER DEFAULT 1,
  outlet_id INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (outlet_id) REFERENCES outlets(id)
);

CREATE TABLE role_permissions (                -- matrix role & permission, editable dari UI
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  role TEXT NOT NULL,
  module TEXT NOT NULL,                        -- 'dashboard' | 'transaksi' | 'kasir' | dst
  access_level TEXT NOT NULL DEFAULT 'none'     -- 'none' | 'view' | 'full'
);

-- ============ PRODUK & KATEGORI ============

CREATE TABLE product_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,                          -- Voucher, Transfer, Tarik Tunai, dll
  outlet_id INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (outlet_id) REFERENCES outlets(id)
);

CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category_id INTEGER,
  sell_price REAL NOT NULL,
  cost_price REAL NOT NULL,
  stock INTEGER DEFAULT 0,
  outlet_id INTEGER DEFAULT 1,
  is_active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES product_categories(id),
  FOREIGN KEY (outlet_id) REFERENCES outlets(id)
);

-- ============ PELANGGAN ============

CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT,
  merged_into_id INTEGER,                      -- diisi kalau profil ini digabung ke customer lain
  outlet_id INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (merged_into_id) REFERENCES customers(id),
  FOREIGN KEY (outlet_id) REFERENCES outlets(id)
);

CREATE TABLE customer_accounts (                -- akun/rekening milik satu pelanggan (bisa >1)
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  account_type TEXT,                            -- Dana, SeaBank, dll
  account_number TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- ============ KASIR ============

CREATE TABLE cashier_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  outlet_id INTEGER DEFAULT 1,
  opening_balance REAL NOT NULL,
  drawer_cash REAL DEFAULT 0,
  closing_balance REAL,
  status TEXT DEFAULT 'open',                   -- open | closed
  opened_at TEXT DEFAULT CURRENT_TIMESTAMP,
  closed_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (outlet_id) REFERENCES outlets(id)
);

CREATE TABLE cashier_bank_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cashier_session_id INTEGER NOT NULL,
  bank_name TEXT NOT NULL,
  balance REAL DEFAULT 0,
  FOREIGN KEY (cashier_session_id) REFERENCES cashier_sessions(id)
);

CREATE TABLE cashier_mutations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cashier_session_id INTEGER NOT NULL,
  type TEXT NOT NULL,                           -- in | out
  amount REAL NOT NULL,
  note TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (cashier_session_id) REFERENCES cashier_sessions(id)
);

-- ============ TRANSAKSI ============

CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER,
  category_id INTEGER,
  sell_price REAL NOT NULL,
  cost_price REAL NOT NULL,
  profit REAL NOT NULL,
  payment_method TEXT,
  customer_id INTEGER,
  user_id INTEGER NOT NULL,                     -- kasir yang input
  outlet_id INTEGER DEFAULT 1,
  transaction_date TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(id),
  FOREIGN KEY (category_id) REFERENCES product_categories(id),
  FOREIGN KEY (customer_id) REFERENCES customers(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (outlet_id) REFERENCES outlets(id)
);

CREATE TABLE transaction_custom_fields (        -- definisi field custom (diatur di Pengaturan)
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  field_name TEXT NOT NULL,
  field_type TEXT DEFAULT 'text',
  is_active INTEGER DEFAULT 1,
  outlet_id INTEGER DEFAULT 1
);

CREATE TABLE transaction_custom_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  field_id INTEGER NOT NULL,
  value TEXT,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id),
  FOREIGN KEY (field_id) REFERENCES transaction_custom_fields(id)
);

-- ============ SERVICE HP ============

CREATE TABLE service_orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_name TEXT NOT NULL,
  customer_id INTEGER,
  phone_number TEXT,
  damage_description TEXT,
  service_cost REAL,
  cost_price REAL,
  profit REAL,
  date_in TEXT NOT NULL,
  date_out TEXT,
  warranty TEXT,
  technician_id INTEGER,
  notes TEXT,
  status TEXT DEFAULT 'diterima',               -- diterima, proses, menunggu_sparepart, selesai, diambil, batal
  outlet_id INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id),
  FOREIGN KEY (technician_id) REFERENCES employees(id),
  FOREIGN KEY (outlet_id) REFERENCES outlets(id)
);

-- ============ KASBON ============

CREATE TABLE kasbon_profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  total_debt REAL DEFAULT 0,
  outlet_id INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE kasbon_entries (                   -- catatan hutang baru
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kasbon_profile_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  description TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (kasbon_profile_id) REFERENCES kasbon_profiles(id)
);

CREATE TABLE kasbon_payments (                  -- histori bayar (boleh parsial)
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kasbon_profile_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  paid_at TEXT DEFAULT CURRENT_TIMESTAMP,
  note TEXT,
  FOREIGN KEY (kasbon_profile_id) REFERENCES kasbon_profiles(id)
);

-- ============ PENGELUARAN ============

CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  note TEXT,
  outlet_id INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ============ KARYAWAN & GAJI ============

CREATE TABLE employees (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  position TEXT,
  phone TEXT,
  is_active INTEGER DEFAULT 1,
  outlet_id INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE salaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  employee_id INTEGER NOT NULL,
  period TEXT NOT NULL,                         -- format: 'YYYY-MM'
  amount REAL NOT NULL,
  paid_at TEXT,
  note TEXT,
  FOREIGN KEY (employee_id) REFERENCES employees(id)
);

-- ============ NOTIFHOOK ============

CREATE TABLE notif_sources (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_name TEXT NOT NULL,                    -- Dana, OrderKuota, dll
  matcher_type TEXT NOT NULL,                   -- package_name
  value TEXT NOT NULL,                          -- com.dana
  status TEXT DEFAULT 'aktif',
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notif_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_id INTEGER,
  raw_content TEXT,
  matched_transaction_id INTEGER,
  status TEXT DEFAULT 'pending',                -- pending, matched, ignored
  received_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (source_id) REFERENCES notif_sources(id)
);

-- ============ MASTER AKUN ============

CREATE TABLE master_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_name TEXT NOT NULL,                   -- Dana, OrderKuota, SeaBank, dll (custom)
  account_number TEXT,
  balance REAL DEFAULT 0,
  is_custom INTEGER DEFAULT 0,
  outlet_id INTEGER DEFAULT 1,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- ============ LOG / AUDIT ============

CREATE TABLE audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  action TEXT NOT NULL,                         -- create, update, delete
  table_name TEXT NOT NULL,
  record_id INTEGER,
  detail TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ============ INDEXES ============

CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_customer ON transactions(customer_id);
CREATE INDEX idx_transactions_outlet ON transactions(outlet_id);
CREATE INDEX idx_service_orders_status ON service_orders(status);
CREATE INDEX idx_kasbon_entries_profile ON kasbon_entries(kasbon_profile_id);
CREATE INDEX idx_kasbon_payments_profile ON kasbon_payments(kasbon_profile_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_notif_logs_status ON notif_logs(status);
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name, record_id);
