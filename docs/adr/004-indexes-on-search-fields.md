# ADR-004: Indexes on Search Fields

**Date:** 2026-11-19

## Context

When creating the tables, we had to decide where to place indexes. An index speeds up queries but has a cost on writes (INSERT/UPDATE/DELETE).

The most frequent system queries would be:

- Login: `SELECT * FROM users WHERE email = ?`
- My orders: `SELECT * FROM orders WHERE user_id = ?`
- Filter by status: `SELECT * FROM orders WHERE status = ?`
- Order details: `SELECT * FROM order_items WHERE order_id = ?`
- Product reports: `SELECT * FROM order_items WHERE product_id = ?`

## Decision

We created indexes on the fields used in these queries:

| Table | Index | Type | Reason |
|---|---|---|---|
| `users` | `idx_users_email` | **UNIQUE** | User login + guarantee unique emails |
| `orders` | `idx_orders_user_id` | B-tree | List orders for a user |
| `orders` | `idx_orders_status` | B-tree | Filter orders by status (PENDING, CONFIRMED, etc) |
| `order_items` | `idx_order_items_order_id` | B-tree | Fetch items for a specific order |
| `order_items` | `idx_order_items_product_id` | B-tree | Product reports |

### How does an index work?

Without an index, PostgreSQL performs a **sequential scan** of the entire table (table scan). With an index, it queries a separate structure (B-tree) that tells exactly where the rows are — like a library catalog.

### Why not index everything?

Indexes speed up **reads** but slow down **writes**:

- INSERT: must update all indexes on the table
- UPDATE: if an indexed column changes, it needs reindexing
- DELETE: must remove from the index

That's why we index **only** the fields that will be used in frequent searches.

## Consequences

**Pros:**
- Fast login and listing queries even with millions of records
- `idx_users_email` as UNIQUE is already an index — two benefits in one structure
- Complete coverage of the system's main queries

**Cons:**
- Small overhead on writes (acceptable for the expected volume)
- Takes up disk space (proportional to table size)

## References

- [Migration V2: idx_users_email](../../src/main/resources/db/migration/V2__create_users_table.sql)
- [Migration V4: idx_orders_user_id and idx_orders_status](../../src/main/resources/db/migration/V4__create_orders_table.sql)
- [Migration V5: idx_order_items_order_id and idx_order_items_product_id](../../src/main/resources/db/migration/V5__create_order_items_table.sql)