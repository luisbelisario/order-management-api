# docs/

Architecture documentation, technical decisions, and learning records for the Order Management API.

## Structure

```
docs/
├── adr/             → Architecture Decision Records
│                       Conscious decisions about modeling, tech stack, and strategy
├── post-mortems/    → Bug and incident analysis
│                       What happened, root cause, how it was fixed
└── README.md        → You are here
```

## ADRs (Architecture Decision Records)

Each ADR documents **one architectural decision**: context, what was decided and why, and the consequences.

| # | Title | Decision |
|---|-------|----------|
| 001 | [1:N relational modeling](adr/001-1n-relational-modeling.md) | Avoid `@ManyToMany`, use associative entity |
| 002 | [Lazy fetch with @EntityGraph strategy](adr/002-lazy-fetch-entitygraph-strategy.md) | Use `FetchType.LAZY` + `@EntityGraph` instead of EAGER |
| 003 | [Flyway with ddl-auto=validate](adr/003-flyway-ddl-auto-validate.md) | Schema managed by Flyway, Hibernate only validates |
| 004 | [Indexes on search fields](adr/004-indexes-on-search-fields.md) | Indexes on email, status, user_id, order_id, product_id |

## Guides

Practical references for JPA annotations and common patterns used in the project.

| # | Title | Covers |
|---|-------|--------|
| 001 | [JPA Field Mappings](guides/jpa-field-mappings.md) | @GeneratedValue, precision/scale, @Enumerated, @CreationTimestamp, @UpdateTimestamp |

## Post-Mortems

| # | Title | Duration |
|---|-------|----------|
| 001 | [PostgreSQL connection between Spring Boot and Docker](post-mortems/001-postgres-connection-spring-boot-docker.md) | ~30 min |

## How to contribute

- **New ADR:** copy the template below and create `adr/XXX-short-title.md`
- **New post-mortem:** create `post-mortems/XXX-short-title.md` following the 001 format

### ADR Template

```markdown
# ADR-XXX: Title

**Date:** YYYY-MM-DD

## Context

What was being decided and why.

## Decision

What was chosen.

## Consequences

Pros, cons, observed impacts.

## References

Links to code, issues, external docs.
```