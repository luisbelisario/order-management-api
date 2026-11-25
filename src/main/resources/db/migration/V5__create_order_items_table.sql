CREATE TABLE orders.order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    subtotal DECIMAL(14, 2) NOT NULL,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders.orders(id),
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES orders.products(id)
);

CREATE INDEX idx_order_items_order_id ON orders.order_items (order_id);
CREATE INDEX idx_order_items_product_id ON orders.order_items (product_id);