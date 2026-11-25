# ADR-001: 1:N Relational Modeling

**Date:** 2026-11-19

## Context

We needed to model the core entities for the order management system: **User**, **Product**, **Order**, and **OrderItem**.

The main question was: how to model the relationship between **Order** and **Product**?

- An order can have multiple products
- A product can be in multiple orders

This is a **many-to-many** relationship (`@ManyToMany`), but we also needed to store extra data per item: **quantity**, **unit price**, and **subtotal**.

## Decision

We created an **associative entity** `OrderItem` with `@ManyToOne` on both sides, instead of using `@ManyToMany` between Order and Product.

```java
// Order → OneToMany with OrderItem
@OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
private List<OrderItem> items;

// OrderItem → ManyToOne with Order and Product
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "order_id")
private Order order;

@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "product_id")
private Product product;
```

This generates the `order_items` table with FKs to both `orders` and `products`.

## Consequences

**Pros:**
- OrderItem has its own attributes (quantity, unitPrice, subtotal) — something `@ManyToMany` doesn't allow without an explicit join table
- More flexible for future business rules (e.g., adding per-item discounts)
- Clearer and more performant SQL queries
- Avoids the implicit join table that `@ManyToMany` creates, giving full control over the table

**Cons:**
- More code: one extra entity + repository
- Must manage bidirectional consistency (helper methods `addItem()` / `removeItem()`)

## References

- [Code: Order.java](../../src/main/java/com/luis/order_management_api/model/Order.java)
- [Code: OrderItem.java](../../src/main/java/com/luis/order_management_api/model/OrderItem.java)
- [Code: Product.java](../../src/main/java/com/luis/order_management_api/model/Product.java)
- [Migration V5: order_items](../../src/main/resources/db/migration/V5__create_order_items_table.sql)