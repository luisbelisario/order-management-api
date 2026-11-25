# JPA Field Mappings — Quick Reference

Common JPA annotations used in this project and what they mean.

---

## `@GeneratedValue(strategy = GenerationType.IDENTITY)**

**What it does:** Tells Hibernate to let the database generate the primary key automatically.

```java
@Id
@GeneratedValue(strategy = GenerationType.IDENTITY)
private Long id;
```

The SQL equivalent is `BIGSERIAL` (PostgreSQL) or `AUTO_INCREMENT` (MySQL):

```sql
id BIGSERIAL PRIMARY KEY
```

Each time a row is inserted, the database increments the sequence and generates the next ID. Hibernate **does not** try to generate it — it inserts the row and then asks the database "what ID did you give me?".

### Other strategies

| Strategy | How it works |
|---|---|
| `IDENTITY` | Database generates the ID (BIGSERIAL, AUTO_INCREMENT). Hibernate inserts then queries the ID. |
| `SEQUENCE` | Uses a database sequence (`CREATE SEQUENCE`). Hibernate fetches the next value **before** inserting. More performant for batch inserts. |
| `AUTO` | Hibernate picks the best strategy (usually SEQUENCE on PostgreSQL). |
| `UUID` | Generates a random UUID in the application. |

**Recommendation:** Use `IDENTITY` for simple cases. Use `SEQUENCE` when you need batch insert performance.

---

## `@Column` — precision and scale

**What it does:** Defines the numeric constraints for `BigDecimal` fields.

```java
@Column(nullable = false, precision = 14, scale = 2)
private BigDecimal total;
```

- **`precision`** = total number of digits (both sides of the decimal point)
- **`scale`** = how many digits go **after** the decimal point

Translates to SQL:

```sql
total DECIMAL(14, 2) NOT NULL DEFAULT 0
```

### Visual example with `DECIMAL(14, 2)`

```
      _ _ _ _ _ _ _ _ _ _ _ _ . _ _
        12 digits before      2 digits after
        = 14 total digits (precision)
```

### What fits?

| Value | Fits in DECIMAL(14,2)? |
|---|---|
| `999999999999.99` | ✅ (12 before + 2 after = 14) |
| `1.99` | ✅ |
| `0.50` | ✅ |
| `1000000000000.00` | ❌ (13 before + 2 after = 15 > 14) |

### Why BigDecimal and not Double?

```java
// Double — imprecise!
0.1 + 0.2 = 0.30000000000000004  ← rounding error

// BigDecimal — exact!
new BigDecimal("0.1").add(new BigDecimal("0.2")) = 0.30  ← precise
```

**Rule of thumb:** Money values are **always** `BigDecimal`, never `double` or `float`.

---

## `@Column` — nullable, length, unique

```java
@Column(nullable = false, length = 150)
private String name;

@Column(nullable = false, unique = true)
private String email;
```

| Attribute | What it does | SQL equivalent |
|---|---|---|
| `nullable = false` | Field is required (NOT NULL) | `name VARCHAR(150) NOT NULL` |
| `length = 150` | Max string length | `name VARCHAR(150)` |
| `unique = true` | No duplicate values allowed | `email VARCHAR(255) UNIQUE` |
| `columnDefinition = "TEXT"` | Override the SQL column type | `description TEXT` |

---

## `@Column(columnDefinition = "TEXT")` and `@Lob`

**What it does:** Changes the SQL column type from the default `VARCHAR(255)` to `TEXT`.

```java
@Column(columnDefinition = "TEXT")
private String description;
```

**Why?** By default, Hibernate maps `String` to `VARCHAR(255)`. If the description is longer than 255 characters, the database will truncate it or throw an error. `TEXT` has no length limit.

### The portable alternative: `@Lob`

`columnDefinition` is **database-specific**. If you ever switch from PostgreSQL to MySQL, `"TEXT"` works for both, but values like `"JSONB"` would break. A more portable approach is:

```java
@Lob
private String description;
```

`@Lob` (Large Object) tells Hibernate: "this field can be big, pick the right type for the current database".

| Database | `VARCHAR(255)` (default) | `@Lob` | `columnDefinition = "TEXT"` |
|----------|-------------------------|--------|------------------------------|
| PostgreSQL | `VARCHAR(255)` | `TEXT` | `TEXT` |
| MySQL | `VARCHAR(255)` | `LONGTEXT` | `TEXT` |
| H2 (tests) | `VARCHAR(255)` | `CLOB` | `TEXT` |

**Recommendation:** Use `@Lob` when you want portability. Use `columnDefinition` when you need a specific database feature (e.g., `JSONB`, `UUID`, `GEOMETRY`).

---

## `@Enumerated(EnumType.STRING)`

**What it does:** Stores the enum **name** (the string literal) in the database instead of its ordinal position.

```java
@Enumerated(EnumType.STRING)
@Column(nullable = false, length = 20)
private OrderStatus status;
```

With `EnumType.STRING`, the value stored is `"PENDING"`, `"CONFIRMED"`, etc.

With `EnumType.ORDINAL` (default), it would store `0`, `1`, `2` — which breaks if you ever reorder or insert a new value in the middle of the enum.

**Recommendation:** Always use `EnumType.STRING` unless you have a very specific reason not to.

---

## `@CreationTimestamp` / `@UpdateTimestamp`

Hibernate annotations that automatically set timestamps on insert and update.

```java
@CreationTimestamp
@Column(name = "created_at", nullable = false, updatable = false)
private LocalDateTime createdAt;

@UpdateTimestamp
@Column(name = "updated_at", nullable = false)
private LocalDateTime updatedAt;
```

- **`@CreationTimestamp`** — set once on first insert, never updated
- **`@UpdateTimestamp`** — updated every time the entity is saved

### Alternatives

**Old-school approach** (before Hibernate 5+):

```java
@PrePersist
public void prePersist() {
    this.createdAt = LocalDateTime.now();
    this.updatedAt = LocalDateTime.now();
}

@PreUpdate
public void preUpdate() {
    this.updatedAt = LocalDateTime.now();
}
```

**Spring Data JPA approach** (with `@EnableJpaAuditing`):

```java
@CreatedDate
@LastModifiedDate
```

The Hibernate annotations (`@CreationTimestamp` / `@UpdateTimestamp`) are simpler — no extra configuration needed. The database also has defaults (`DEFAULT NOW()`) as a safety net.