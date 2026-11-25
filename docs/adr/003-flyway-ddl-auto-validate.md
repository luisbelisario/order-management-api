# ADR-003: Flyway with ddl-auto=validate

**Date:** 2026-11-19

## Context

We needed to manage the database schema. The options were:

1. **`ddl-auto=update`** — Hibernate creates/alters tables automatically
2. **Flyway** — versioned migrations written in plain SQL
3. **Liquibase** — Flyway alternative (more verbose)

We also needed to decide whether Flyway would be the sole schema manager or if Hibernate would also participate.

## Decision

We used **Flyway with `ddl-auto=validate`**:

- **Flyway** is the **schema owner** — all migrations are versioned plain SQL
- **Hibernate** only **validates** that JPA entities match the existing schema
- If there's a mismatch between an entity and a migration, the application **won't start** (fail-fast)

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate
  flyway:
    enabled: true
```

### Why not `ddl-auto=update`?

- Dangerous in production: Hibernate might drop columns or tables without warning
- No versioning: you can't tell what state the database was in for each deploy
- Hard to review: changes happen "magically", with no code to review

### Why Flyway over Liquibase?

- Flyway is simpler: migrations are plain SQL files
- Liquibase uses XML/YAML/JSON and is more verbose for the same result
- Flyway is the most widely used in the Spring Boot ecosystem

## Consequences

**Pros:**
- Versioned and traceable schema
- Explicit rollback (create a reversal migration)
- Safety: `validate` prevents the app from starting with an inconsistent schema
- Plain SQL migrations — any DBA can review them

**Cons:**
- More initial work: you must write SQL manually instead of letting Hibernate create it
- In development, every schema change requires a new migration (can't just alter the entity and restart)

## References

- [Migration V1: initial schema](../../src/main/resources/db/migration/V1__init.sql)
- [Migration V2: users](../../src/main/resources/db/migration/V2__create_users_table.sql)
- [Migration V3: products](../../src/main/resources/db/migration/V3__create_products_table.sql)
- [Migration V4: orders](../../src/main/resources/db/migration/V4__create_orders_table.sql)
- [Migration V5: order_items](../../src/main/resources/db/migration/V5__create_order_items_table.sql)
- [application-dev.yaml](../../src/main/resources/application-dev.yaml)