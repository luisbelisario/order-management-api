CREATE TABLE orders.orders (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total DECIMAL(14, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES orders.users(id)
);

CREATE INDEX idx_orders_user_id ON orders.orders (user_id);
CREATE INDEX idx_orders_status ON orders.orders (status);