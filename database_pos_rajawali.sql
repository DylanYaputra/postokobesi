-- ============================================================
-- DATABASE: POS Toko Besi Rajawali
-- Dibuat berdasarkan Class Diagram
-- Engine: MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS pos_rajawali
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pos_rajawali;

-- ============================================================
-- 1. ROLES
-- ============================================================
CREATE TABLE roles (
    role_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    guard_name  VARCHAR(100) NOT NULL DEFAULT 'web',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Daftar peran pengguna (admin, kasir, gudang, dll.)';

-- ============================================================
-- 2. PERMISSIONS
-- ============================================================
CREATE TABLE permissions (
    permission_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL UNIQUE,
    module_name     VARCHAR(100) NOT NULL COMMENT 'Nama modul: product, sale, purchase, user, report, dst.',
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Daftar izin akses per modul';

-- ============================================================
-- 3. ROLE_PERMISSIONS (pivot)
-- ============================================================
CREATE TABLE role_permissions (
    role_id         INT UNSIGNED NOT NULL,
    permission_id   INT UNSIGNED NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role       FOREIGN KEY (role_id)       REFERENCES roles(role_id)       ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Relasi banyak-ke-banyak antara role dan permission';

-- ============================================================
-- 4. USERS
-- ============================================================
CREATE TABLE users (
    user_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username    VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL COMMENT 'Bcrypt / Argon2 hash',
    full_name   VARCHAR(150) NOT NULL,
    email       VARCHAR(150)          UNIQUE,
    status      TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '1=aktif, 0=nonaktif',
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='Akun pengguna sistem';

-- ============================================================
-- 5. USER_ROLES (pivot)
-- ============================================================
CREATE TABLE user_roles (
    user_id INT UNSIGNED NOT NULL,
    role_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Relasi banyak-ke-banyak antara user dan role';

-- ============================================================
-- 6. CATEGORIES
-- ============================================================
CREATE TABLE categories (
    category_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT
) ENGINE=InnoDB COMMENT='Kategori produk (pipa, baut, cat, kawat, dll.)';

-- ============================================================
-- 7. SUPPLIERS
-- ============================================================
CREATE TABLE suppliers (
    supplier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    phone       VARCHAR(30),
    address     TEXT,
    email       VARCHAR(150)
) ENGINE=InnoDB COMMENT='Data pemasok / vendor';

-- ============================================================
-- 8. PRODUCTS
-- ============================================================
CREATE TABLE products (
    product_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id     INT UNSIGNED NOT NULL,
    supplier_id     INT UNSIGNED NOT NULL,
    product_code    VARCHAR(50)      NOT NULL UNIQUE,
    product_name    VARCHAR(200)     NOT NULL,
    unit            VARCHAR(30)      NOT NULL COMMENT 'pcs, meter, kg, liter, dll.',
    stock           INT              NOT NULL DEFAULT 0,
    buying_price    DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    selling_price   DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_prod_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON UPDATE CASCADE,
    CONSTRAINT fk_prod_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)  ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Katalog produk toko besi';

-- ============================================================
-- 9. PURCHASES (Pembelian dari supplier)
-- ============================================================
CREATE TABLE purchases (
    purchase_id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id             INT UNSIGNED     NOT NULL COMMENT 'Petugas yang mencatat',
    supplier_id         INT UNSIGNED     NOT NULL,
    invoice_number      VARCHAR(100)     NOT NULL UNIQUE,
    purchase_date       DATE             NOT NULL,
    gross_total         DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    discount_percentage DECIMAL(5,2)     NOT NULL DEFAULT 0.00,
    discount_amount     DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    subtotal            DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    created_at          DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pur_user     FOREIGN KEY (user_id)     REFERENCES users(user_id)         ON UPDATE CASCADE,
    CONSTRAINT fk_pur_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Header transaksi pembelian barang';

-- ============================================================
-- 10. PURCHASE_ITEMS (Detail item pembelian)
-- ============================================================
CREATE TABLE purchase_items (
    purchase_item_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    purchase_id         INT UNSIGNED     NOT NULL,
    product_id          INT UNSIGNED     NOT NULL,
    quantity            INT              NOT NULL DEFAULT 1,
    price               DECIMAL(15,2)    NOT NULL DEFAULT 0.00 COMMENT 'Harga beli per unit saat transaksi',
    subtotal            DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_pi_purchase FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pi_product  FOREIGN KEY (product_id)  REFERENCES products(product_id)  ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Detail item pada transaksi pembelian';

-- ============================================================
-- 11. SALES (Penjualan ke pelanggan)
-- ============================================================
CREATE TABLE sales (
    sale_id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id             INT UNSIGNED     NOT NULL COMMENT 'Kasir yang melayani',
    invoice_number      VARCHAR(100)     NOT NULL UNIQUE,
    sale_date           DATE             NOT NULL,
    payment_method      VARCHAR(50)      NOT NULL DEFAULT 'cash' COMMENT 'cash, transfer, qris, dll.',
    payment_status      VARCHAR(30)      NOT NULL DEFAULT 'paid' COMMENT 'paid, pending, cancelled',
    gross_total         DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    discount_percentage DECIMAL(5,2)     NOT NULL DEFAULT 0.00,
    discount_amount     DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    subtotal            DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    created_at          DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_sale_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Header transaksi penjualan';

-- ============================================================
-- 12. SALE_ITEMS (Detail item penjualan)
-- ============================================================
CREATE TABLE sale_items (
    sale_item_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sale_id         INT UNSIGNED     NOT NULL,
    product_id      INT UNSIGNED     NOT NULL,
    quantity        INT              NOT NULL DEFAULT 1,
    price           DECIMAL(15,2)    NOT NULL DEFAULT 0.00 COMMENT 'Harga jual per unit saat transaksi',
    subtotal        DECIMAL(15,2)    NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_si_sale    FOREIGN KEY (sale_id)    REFERENCES sales(sale_id)       ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_si_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Detail item pada transaksi penjualan';

-- ============================================================
-- 13. RECEIPTS (Struk penjualan)
-- ============================================================
CREATE TABLE receipts (
    receipt_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sale_id     INT UNSIGNED NOT NULL UNIQUE COMMENT 'Satu sale = satu receipt',
    print_date  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rec_sale FOREIGN KEY (sale_id) REFERENCES sales(sale_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Struk cetak untuk setiap penjualan';

-- ============================================================
-- 14. ACTIVITY_LOGS
-- ============================================================
CREATE TABLE activity_logs (
    log_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    log_name    VARCHAR(150)  NOT NULL,
    description TEXT,
    subject_id  INT UNSIGNED  COMMENT 'ID record yang dimodifikasi (polymorphic)',
    subject_type VARCHAR(100) COMMENT 'Nama tabel/model (misal: sales, products, users)',
    causer_id   INT UNSIGNED  COMMENT 'user_id yang melakukan aksi',
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_causer FOREIGN KEY (causer_id) REFERENCES users(user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Log aktivitas pengguna di sistem';

-- ============================================================
-- 15. REPORTS (Metadata laporan yang digenerate)
-- ============================================================
CREATE TABLE reports (
    report_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    report_type     VARCHAR(50)   NOT NULL COMMENT 'sales, purchase, product',
    generated_date  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    generated_by    INT UNSIGNED  NOT NULL COMMENT 'user_id yang generate laporan',
    CONSTRAINT fk_rep_user FOREIGN KEY (generated_by) REFERENCES users(user_id) ON UPDATE CASCADE
) ENGINE=InnoDB COMMENT='Riwayat laporan yang pernah diekspor';

-- ============================================================
-- INDEXES tambahan untuk performa query
-- ============================================================
CREATE INDEX idx_products_category  ON products(category_id);
CREATE INDEX idx_products_supplier  ON products(supplier_id);
CREATE INDEX idx_products_code      ON products(product_code);
CREATE INDEX idx_purchases_date     ON purchases(purchase_date);
CREATE INDEX idx_purchases_supplier ON purchases(supplier_id);
CREATE INDEX idx_sales_date         ON sales(sale_date);
CREATE INDEX idx_sales_user         ON sales(user_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);
CREATE INDEX idx_pur_items_product  ON purchase_items(product_id);
CREATE INDEX idx_activity_causer    ON activity_logs(causer_id);
CREATE INDEX idx_activity_subject   ON activity_logs(subject_type, subject_id);

-- ============================================================
-- TRIGGERS: Otomatis update stok produk
-- ============================================================

DELIMITER $$

-- Tambah stok saat purchase_item diinsert
CREATE TRIGGER trg_stock_add_on_purchase
AFTER INSERT ON purchase_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock + NEW.quantity
    WHERE product_id = NEW.product_id;
END$$

-- Kurangi stok saat sale_item diinsert
CREATE TRIGGER trg_stock_deduct_on_sale
AFTER INSERT ON sale_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE product_id = NEW.product_id;
END$$

-- Kembalikan stok saat purchase_item dihapus
CREATE TRIGGER trg_stock_revert_on_purchase_delete
AFTER DELETE ON purchase_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock - OLD.quantity
    WHERE product_id = OLD.product_id;
END$$

-- Kembalikan stok saat sale_item dihapus (misal transaksi dibatalkan)
CREATE TRIGGER trg_stock_revert_on_sale_delete
AFTER DELETE ON sale_items
FOR EACH ROW
BEGIN
    UPDATE products
    SET stock = stock + OLD.quantity
    WHERE product_id = OLD.product_id;
END$$

DELIMITER ;

-- ============================================================
-- DATA AWAL (Seed)
-- ============================================================

-- Roles
INSERT INTO roles (name, guard_name) VALUES
    ('admin',   'web'),
    ('kasir',   'web'),
    ('gudang',  'web');

-- Permissions
INSERT INTO permissions (name, module_name) VALUES
    -- User management
    ('user.view',   'user'), ('user.create', 'user'), ('user.update', 'user'), ('user.delete', 'user'),
    -- Role management
    ('role.view',   'role'), ('role.create', 'role'), ('role.update', 'role'), ('role.delete', 'role'),
    -- Category
    ('category.view', 'category'), ('category.create', 'category'), ('category.update', 'category'), ('category.delete', 'category'),
    -- Supplier
    ('supplier.view', 'supplier'), ('supplier.create', 'supplier'), ('supplier.update', 'supplier'), ('supplier.delete', 'supplier'),
    -- Product
    ('product.view', 'product'), ('product.create', 'product'), ('product.update', 'product'), ('product.delete', 'product'),
    -- Purchase
    ('purchase.view', 'purchase'), ('purchase.create', 'purchase'), ('purchase.update', 'purchase'), ('purchase.delete', 'purchase'),
    -- Sale
    ('sale.view', 'sale'), ('sale.create', 'sale'), ('sale.update', 'sale'), ('sale.delete', 'sale'),
    -- Report
    ('report.sales', 'report'), ('report.purchase', 'report'), ('report.product', 'report'),
    -- Dashboard
    ('dashboard.view', 'dashboard'),
    -- Activity Log
    ('log.view', 'log');

-- Admin mendapat semua permission
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, permission_id FROM permissions;

-- Kasir: sale, product view, report sales, dashboard
INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, permission_id FROM permissions
WHERE module_name IN ('sale', 'dashboard')
   OR name IN ('product.view', 'category.view', 'report.sales');

-- Gudang: purchase, product, supplier, category
INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, permission_id FROM permissions
WHERE module_name IN ('purchase', 'product', 'supplier', 'category');

-- User admin default (password: admin123 → bcrypt placeholder)
INSERT INTO users (username, password, full_name, email, status) VALUES
    ('admin', '$2y$10$exampleHashForAdmin123456789012345678901234567', 'Administrator', 'admin@rajawali.com', 1),
    ('kasir1', '$2y$10$exampleHashForKasir123456789012345678901234567', 'Kasir Satu', 'kasir1@rajawali.com', 1);

INSERT INTO user_roles (user_id, role_id) VALUES (1, 1), (2, 2);

-- Kategori produk besi
INSERT INTO categories (name, description) VALUES
    ('Pipa & Fitting',     'Berbagai jenis pipa besi, galvanis, PVC, dan fittingnya'),
    ('Baut & Mur',         'Baut, mur, ring, dan sekrup berbagai ukuran'),
    ('Besi & Baja',        'Besi hollow, besi ulir, baja WF, plat besi, dll.'),
    ('Cat & Pelapis',      'Cat besi, anti karat, thinner, dan primer'),
    ('Kawat & Kabel',      'Kawat duri, kawat las, kawat beton, dan kabel'),
    ('Alat Tangan',        'Palu, obeng, kunci, gergaji, dan perkakas tangan lainnya'),
    ('Alat Las',           'Elektroda, mesin las, sarung tangan las, helm las'),
    ('Semen & Bahan Bangunan', 'Semen, pasir, bata, genteng, dan material bangunan');

-- Supplier contoh
INSERT INTO suppliers (name, phone, address, email) VALUES
    ('PT. Baja Mulia Sentosa',   '0618881234', 'Jl. Industri No.12, Medan',       'penjualan@bajamulia.com'),
    ('CV. Logam Jaya',           '0218889999', 'Jl. Raya Bekasi KM 5, Jakarta',    'order@logamjaya.co.id'),
    ('UD. Sumber Besi',          '0311234567', 'Jl. Tandes No.8, Surabaya',        NULL),
    ('PT. Indosteel',            '0214445678', 'Kawasan MM2100, Bekasi',            'supply@indosteel.com');

-- Produk contoh
INSERT INTO products (category_id, supplier_id, product_code, product_name, unit, stock, buying_price, selling_price) VALUES
    (1, 1, 'PIP-GAL-1/2',  'Pipa Galvanis 1/2 Inch',       'batang', 150,  45000.00,  58000.00),
    (1, 1, 'PIP-GAL-1',    'Pipa Galvanis 1 Inch',          'batang', 120,  78000.00,  95000.00),
    (1, 1, 'PIP-HIR-3/4',  'Pipa Hitam 3/4 Inch',           'batang',  80,  42000.00,  55000.00),
    (2, 2, 'BAU-HEX-M8',   'Baut Hex M8 x 30mm',            'pcs',   2000,    350.00,    600.00),
    (2, 2, 'BAU-HEX-M10',  'Baut Hex M10 x 40mm',           'pcs',   1500,    550.00,    900.00),
    (2, 2, 'MUR-M8',       'Mur M8',                        'pcs',   3000,    150.00,    250.00),
    (3, 1, 'BSI-HOL-2X4',  'Besi Hollow 2x4 cm Tebal 1.8mm','batang',  60, 115000.00, 140000.00),
    (3, 1, 'BSI-ULR-D10',  'Besi Ulir Diameter 10mm',       'batang',  90,  85000.00, 105000.00),
    (3, 2, 'PLAT-BSI-3MM', 'Plat Besi 3mm (1.2m x 2.4m)',   'lembar',  25, 420000.00, 520000.00),
    (4, 3, 'CAT-AR-1KG',   'Cat Besi Anti Karat 1Kg',       'kaleng', 200,  55000.00,  75000.00),
    (4, 3, 'THIN-1LT',     'Thinner A Special 1 Liter',     'liter',  300,  22000.00,  32000.00),
    (5, 4, 'KWT-DUR-50M',  'Kawat Duri 50 Meter',           'roll',    40, 110000.00, 140000.00),
    (6, 3, 'PALU-1KG',     'Palu Besi 1 Kg',                'pcs',    100,  45000.00,  65000.00),
    (7, 4, 'ELEK-RD-2.6',  'Elektroda Las RD 2.6mm (5Kg)',  'kotak',   50, 165000.00, 210000.00);

-- ============================================================
-- VIEWS untuk Dashboard & Laporan
-- ============================================================

-- Ringkasan stok
CREATE VIEW v_stock_summary AS
SELECT
    p.product_id,
    p.product_code,
    p.product_name,
    c.name          AS category,
    p.unit,
    p.stock,
    p.buying_price,
    p.selling_price,
    (p.selling_price - p.buying_price)                  AS margin,
    (p.stock * p.selling_price)                         AS stock_value_selling,
    (p.stock * p.buying_price)                          AS stock_value_buying
FROM products p
JOIN categories c ON c.category_id = p.category_id;

-- Penjualan harian
CREATE VIEW v_daily_sales AS
SELECT
    s.sale_date,
    COUNT(DISTINCT s.sale_id)           AS total_transactions,
    SUM(si.quantity)                    AS total_items_sold,
    SUM(s.subtotal)                     AS total_revenue
FROM sales s
JOIN sale_items si ON si.sale_id = s.sale_id
WHERE s.payment_status = 'paid'
GROUP BY s.sale_date
ORDER BY s.sale_date DESC;

-- Produk terlaris
CREATE VIEW v_top_products AS
SELECT
    p.product_id,
    p.product_code,
    p.product_name,
    SUM(si.quantity)    AS total_sold,
    SUM(si.subtotal)    AS total_revenue
FROM sale_items si
JOIN products p ON p.product_id = si.product_id
JOIN sales s    ON s.sale_id    = si.sale_id
WHERE s.payment_status = 'paid'
GROUP BY p.product_id, p.product_code, p.product_name
ORDER BY total_sold DESC;

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- Generate nomor invoice penjualan otomatis
CREATE PROCEDURE sp_generate_sale_invoice(OUT p_invoice VARCHAR(100))
BEGIN
    DECLARE v_date   VARCHAR(8);
    DECLARE v_count  INT;
    SET v_date  = DATE_FORMAT(NOW(), '%Y%m%d');
    SELECT COUNT(*) + 1 INTO v_count
    FROM sales
    WHERE sale_date = CURDATE();
    SET p_invoice = CONCAT('INV-', v_date, '-', LPAD(v_count, 4, '0'));
END$$

-- Generate nomor invoice pembelian otomatis
CREATE PROCEDURE sp_generate_purchase_invoice(OUT p_invoice VARCHAR(100))
BEGIN
    DECLARE v_date   VARCHAR(8);
    DECLARE v_count  INT;
    SET v_date  = DATE_FORMAT(NOW(), '%Y%m%d');
    SELECT COUNT(*) + 1 INTO v_count
    FROM purchases
    WHERE purchase_date = CURDATE();
    SET p_invoice = CONCAT('PUR-', v_date, '-', LPAD(v_count, 4, '0'));
END$$

-- Laporan penjualan per periode
CREATE PROCEDURE sp_sales_report(
    IN p_start DATE,
    IN p_end   DATE
)
BEGIN
    SELECT
        s.sale_id,
        s.invoice_number,
        s.sale_date,
        u.full_name          AS kasir,
        s.payment_method,
        s.gross_total,
        s.discount_amount,
        s.subtotal
    FROM sales s
    JOIN users u ON u.user_id = s.user_id
    WHERE s.sale_date BETWEEN p_start AND p_end
      AND s.payment_status = 'paid'
    ORDER BY s.sale_date, s.sale_id;
END$$

DELIMITER ;

-- ============================================================
-- SELESAI
-- Jalankan: mysql -u root -p < database_pos_rajawali.sql
-- ============================================================