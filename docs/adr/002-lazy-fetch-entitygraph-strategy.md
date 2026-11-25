# ADR-002: Lazy Fetch with @EntityGraph Strategy

**Date:** 2026-11-19

## Context

When modeling JPA relationships, we had to decide how to load associated entities (e.g., `Order.user`, `Order.items`, `OrderItem.product`).

The options were:

1. **`FetchType.EAGER`** (default for `@ManyToOne`) — loads everything in the same SELECT
2. **`FetchType.LAZY`** — loads only when accessed (proxy pattern)
3. **`FetchType.LAZY` + `JOIN FETCH`** in the query
4. **`FetchType.LAZY` + `@EntityGraph`** on the repository

## Decision

We used **`FetchType.LAZY` explicitly on all relationships**, including `@ManyToOne` (which defaults to EAGER).

For cases where we need the associated data, we use **`@EntityGraph`** on the repository:

```java
@EntityGraph(attributePaths = {"user"})
@Query("SELECT o FROM Order o")
List<Order> findAllWithUser();
```

### Why not EAGER?

`FetchType.EAGER` causes the **N+1 problem**: when fetching N orders, Hibernate runs 1 query for orders + N queries for users — even when the user is the same for all orders. EAGER is not "smart" enough to batch the lookups.

### Why `@EntityGraph` over `JOIN FETCH`?

| Scenario | @EntityGraph | JOIN FETCH |
|---|---|---|
| Simple query, just attach one relationship | ✅ Cleaner | ❌ Requires writing JPQL |
| Multiple relationships (e.g., user + items + product) | ✅ `attributePaths` handles it | ❌ Multiple JOIN FETCH manually |
| Complex queries with filters | ❌ Can't add WHERE on the attribute | ✅ Full control |

Both generate the same SQL (`JOIN` with the associated table's columns). `@EntityGraph` is a **declarative** alternative to avoid writing `JOIN FETCH` manually.

## Consequences

**Pros:**
- Controlled performance: only loads what you need
- Cleaner code with `@EntityGraph`
- Eliminates the risk of N+1 in unprepared queries
- Works with Hibernate's first-level cache

**Cons:**
- If you forget to use `@EntityGraph` on a query that needs the data, LAZY will throw a `LazyInitializationException` outside a transaction
- Requires discipline: every query that needs a relationship must explicitly load it

## References

- [Code: Order.java](../../src/main/java/com/luis/order_management_api/model/Order.java)
- [Code: OrderItem.java](../../src/main/java/com/luis/order_management_api/model/OrderItem.java)
- [Spring Data @EntityGraph documentation](https://docs.spring.io/spring-data/jpa/reference/repositories/entity-graphs.html)