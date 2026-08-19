-- Seed demo minimal untuk local D1/SQLite.
-- Password hash di bawah hanya placeholder demo; gunakan hashing backend untuk login nyata.
INSERT OR IGNORE INTO outlets (id,name,address) VALUES (1,'Outlet Utama','Jl. Contoh No. 10');
INSERT OR IGNORE INTO users (id,name,email,password_hash,role,outlet_id) VALUES (1,'Budi Admin','admin@irkop.local','DEMO_ONLY_ADMIN_HASH','admin',1);
INSERT OR IGNORE INTO users (id,name,email,password_hash,role,outlet_id) VALUES (2,'Rina Kasir','kasir@irkop.local','DEMO_ONLY_KASIR_HASH','kasir',1);
INSERT OR IGNORE INTO product_categories (id,name,outlet_id) VALUES (1,'Voucher',1),(2,'Transfer',1),(3,'Tarik Tunai',1),(4,'Aksesoris',1),(5,'Service',1);
INSERT OR IGNORE INTO products (id,name,category_id,sell_price,cost_price,stock,outlet_id) VALUES
(1,'Voucher Telkomsel 10K',1,11500,10000,42,1),(2,'Voucher XL 10K',1,11200,9800,31,1),(3,'Transfer Bank',2,5000,0,999,1),(4,'Tarik Tunai',3,5000,0,999,1),(5,'Kabel Data Type-C',4,25000,16000,18,1);
INSERT OR IGNORE INTO customers (id,name,phone,outlet_id) VALUES (1,'Andi Saputra','081234567890',1),(2,'Siti Rahma','081298765432',1),(3,'Rudi Cell','082155667788',1);
INSERT OR IGNORE INTO employees (id,name,position,phone,outlet_id) VALUES (1,'Agus','Teknisi','081300001111',1),(2,'Deni','Teknisi','081300002222',1),(3,'Budi Admin','Admin','081300003333',1);
INSERT OR IGNORE INTO master_accounts (id,account_name,account_number,balance,is_custom,outlet_id) VALUES (1,'Dana','0898123456',825000,0,1),(2,'OrderKuota','082211223344',410000,0,1),(3,'SeaBank','9012-3344-5566',1250000,0,1);
