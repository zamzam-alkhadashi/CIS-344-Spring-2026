-- Create the database
CREATE DATABASE pet_store_db;
USE pet_store_db;

-- Create tables
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique user identifier',
    first_name VARCHAR(100) NOT NULL COMMENT 'User first name',
    last_name VARCHAR(100) NOT NULL COMMENT 'User last name',
    email VARCHAR(255) NOT NULL UNIQUE COMMENT 'User email address (must be unique)',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Hashed password',
    phone VARCHAR(30) NULL COMMENT 'User phone number',
    role ENUM('customer', 'admin') NOT NULL DEFAULT 'customer'
        COMMENT 'Defines system access level',
    status ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active'
        COMMENT 'Account status',
    email_verified BOOLEAN NOT NULL DEFAULT FALSE
        COMMENT 'Whether email has been verified',
    last_login_at TIMESTAMP NULL DEFAULT NULL
        COMMENT 'Last login timestamp',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Account creation time',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
        COMMENT 'Last update time',
    CONSTRAINT chk_users_email CHECK (email LIKE '%@%')
) ENGINE=InnoDB COMMENT='Stores system users';

CREATE TABLE addresses (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique address identifier',
    user_id BIGINT UNSIGNED NOT NULL COMMENT 'Owner of this address',
    recipient_name VARCHAR(200) NOT NULL COMMENT 'Person receiving delivery',
    phone VARCHAR(30) NOT NULL COMMENT 'Recipient phone number',
    address_line1 VARCHAR(255) NOT NULL COMMENT 'Primary street address',
    address_line2 VARCHAR(255) NULL COMMENT 'Secondary address info',
    city VARCHAR(100) NOT NULL COMMENT 'City name',
    state VARCHAR(100) NULL COMMENT 'State or region',
    postal_code VARCHAR(20) NOT NULL COMMENT 'ZIP or postal code',
    country VARCHAR(100) NOT NULL DEFAULT 'Kenya'
        COMMENT 'Country name',
    is_default BOOLEAN NOT NULL DEFAULT FALSE
        COMMENT 'Whether this is the default address',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Creation timestamp',
    CONSTRAINT fk_addresses_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT chk_postal_code CHECK (CHAR_LENGTH(postal_code) >= 3)
) ENGINE=InnoDB COMMENT='Stores user addresses';

CREATE TABLE products (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique product identifier',
    name VARCHAR(255) NOT NULL COMMENT 'Product name',
    description TEXT NULL COMMENT 'Detailed product description',
    sku VARCHAR(100) NOT NULL UNIQUE COMMENT 'Stock keeping unit identifier',
    price DECIMAL(10,2) NOT NULL COMMENT 'Original product price',
    discount_price DECIMAL(10,2) NULL COMMENT 'Discounted price if applicable',
    stock_quantity INT UNSIGNED NOT NULL DEFAULT 0
        COMMENT 'Available inventory quantity',
    brand VARCHAR(150) NULL COMMENT 'Product brand name',
    weight DECIMAL(8,2) NULL COMMENT 'Weight in kilograms',
    image_url VARCHAR(500) NULL COMMENT 'Product image location',
    status ENUM('active', 'inactive', 'out_of_stock') NOT NULL DEFAULT 'active'
        COMMENT 'Product availability status',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Creation timestamp',
    CONSTRAINT chk_price_positive CHECK (price >= 0),
    CONSTRAINT chk_discount_price_valid CHECK (
        discount_price IS NULL OR discount_price >= 0
    ),
    CONSTRAINT chk_stock_nonnegative CHECK (stock_quantity >= 0)

) ENGINE=InnoDB COMMENT='Stores all products';

CREATE TABLE categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique category identifier',
    name VARCHAR(150) NOT NULL COMMENT 'Category name',
    slug VARCHAR(150) NOT NULL UNIQUE COMMENT 'URL-friendly category identifier',
    description TEXT NULL COMMENT 'Category description',
    parent_category_id BIGINT UNSIGNED NULL
        COMMENT 'Parent category for hierarchy',
    image_url VARCHAR(500) NULL COMMENT 'Category image',
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active'
        COMMENT 'Category status',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Creation timestamp',
    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_category_id)
        REFERENCES categories(id)
        ON DELETE SET NULL,
    CONSTRAINT chk_category_name CHECK (CHAR_LENGTH(name) >= 2)
) ENGINE=InnoDB COMMENT='Stores product categories';

CREATE TABLE product_categories (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique relationship identifier',
    product_id BIGINT UNSIGNED NOT NULL COMMENT 'Referenced product',
    category_id BIGINT UNSIGNED NOT NULL COMMENT 'Referenced category',
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Timestamp when product was assigned to category',
    CONSTRAINT fk_pc_product
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_pc_category
        FOREIGN KEY (category_id)
        REFERENCES categories(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_product_category UNIQUE (product_id, category_id)
) ENGINE=InnoDB COMMENT='Links products and categories';

CREATE TABLE orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique order identifier',
    user_id BIGINT UNSIGNED NOT NULL COMMENT 'User who placed the order',
    address_id BIGINT UNSIGNED NOT NULL COMMENT 'Shipping address',
    order_number VARCHAR(50) NOT NULL UNIQUE COMMENT 'Public order identifier',
    status ENUM(
        'pending',
        'confirmed',
        'processing',
        'shipped',
        'delivered',
        'cancelled'
    ) NOT NULL DEFAULT 'pending'
        COMMENT 'Order lifecycle status',
    subtotal DECIMAL(12,2) NOT NULL COMMENT 'Sum of item prices',
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Tax amount',
    shipping_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Shipping cost',
    total_amount DECIMAL(12,2) NOT NULL COMMENT 'Final payable amount',
    payment_status ENUM(
        'pending',
        'paid',
        'failed',
        'refunded'
    ) NOT NULL DEFAULT 'pending'
        COMMENT 'Payment state',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Order creation time',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
        COMMENT 'Last update time',
    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_orders_address
        FOREIGN KEY (address_id)
        REFERENCES addresses(id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_amounts_positive CHECK (
        subtotal >= 0 AND
        tax_amount >= 0 AND
        shipping_amount >= 0 AND
        total_amount >= 0
    )

) ENGINE=InnoDB COMMENT='Stores customer orders';

CREATE TABLE order_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique order item identifier',
    order_id BIGINT UNSIGNED NOT NULL COMMENT 'Referenced order',
    product_id BIGINT UNSIGNED NOT NULL COMMENT 'Referenced product',
    product_name VARCHAR(255) NOT NULL COMMENT 'Product name snapshot at purchase time',
    sku VARCHAR(100) NOT NULL COMMENT 'SKU snapshot at purchase time',
    quantity INT UNSIGNED NOT NULL DEFAULT 1
        COMMENT 'Number of units ordered',
    unit_price DECIMAL(10,2) NOT NULL
        COMMENT 'Price per unit at purchase time',
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00
        COMMENT 'Discount applied per line item',
    total_price DECIMAL(12,2) NOT NULL
        COMMENT 'Final total price for this line',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Creation timestamp',
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_unit_price_positive CHECK (unit_price >= 0),
    CONSTRAINT chk_total_price_positive CHECK (total_price >= 0)

) ENGINE=InnoDB COMMENT='Stores products inside orders';

CREATE TABLE cart_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'Unique cart item identifier',
    user_id BIGINT UNSIGNED NOT NULL COMMENT 'Owner of cart',
    product_id BIGINT UNSIGNED NOT NULL COMMENT 'Product added to cart',
    quantity INT UNSIGNED NOT NULL DEFAULT 1
        COMMENT 'Quantity added',
    unit_price DECIMAL(10,2) NOT NULL
        COMMENT 'Price at time of adding',
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'When product was added',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
        COMMENT 'Last update time',
    CONSTRAINT fk_cart_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_cart_product
        FOREIGN KEY (product_id)
        REFERENCES products(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_cart_user_product UNIQUE (user_id, product_id),
    CONSTRAINT chk_cart_quantity_positive CHECK (quantity > 0)
) ENGINE=InnoDB COMMENT='Stores user shopping cart items';

