# Post-Mortem 001 — PostgreSQL Connection Between Spring Boot and Docker

**Date:** 2026-11-18
**Duration:** ~30 minutes of troubleshooting
**Project:** Order Management API (H1 — Setup)

## Symptom

The Spring Boot application failed to start with:

```
FATAL: role "admin" does not exist
```

Even though the PostgreSQL container was running and the `.env` file had the correct credentials.

## Timeline

| Time | Event |
|------|-------|
| 17:15 | `docker compose up -d` — containers start |
| 17:17 | App starts in IntelliJ → error `role "admin" does not exist` |
| 17:20 | `docker exec` connects via socket — **false positive** |
| 17:22 | `psql -h localhost` via TCP fails — **same error** |
| 17:25 | `sudo lsof -i :5432` discovers **local PostgreSQL (PID 890)** on the port |
| 17:27 | `kill 890` + `brew services stop postgresql` frees the port |
| 17:29 | App connects and starts successfully |

## Root Cause

**Homebrew PostgreSQL (PID 890)** was running in the background from a previous installation, occupying port `5432` on the host.

`docker compose up` allocated port `5432` inside the Colima VM, but the port forwarding **never reached the container** because the local process was already listening. Spring Boot tried to connect to `localhost:5432` and hit the wrong PostgreSQL (the local one, without the `admin` role).

## Commands Used

```bash
# 1. Check running containers
docker ps --format "table {{.Names}}\t{{.Status}}"

# 2. Connect via socket (inside the container)
docker exec order-db psql -U admin -d orderdb -c "\conninfo"

# 3. Connect via TCP (simulates JDBC)
psql -h localhost -p 5432 -U admin -d orderdb

# 4. Discover what is occupying the port
sudo lsof -i :5432

# 5. Identify the process
ps aux | grep <PID>

# 6. Kill the local process
kill <PID>

# 7. Stop Homebrew service (so it doesn't restart on reboot)
brew services stop postgresql

# 8. Restart the PostgreSQL container
docker compose restart postgres
```

## Lessons Learned

1. **`docker exec` does not test the port.** It connects via Unix socket inside the container, which uses `trust` authentication. Always test via TCP (`psql -h localhost`) to simulate the real application connection.

2. **Homebrew PostgreSQL starts on its own.** `brew services` may have installed PostgreSQL at some point and left it running. On macOS, Homebrew services start automatically on boot.

3. **Always check who is on the port.** Before blaming the application configuration, confirm with `sudo lsof -i :PORTA` that the expected service is the one listening.

4. **Docker persistent volumes.** If the database was previously created with different credentials (e.g., without the `.env` `POSTGRES_USER`), the volume keeps the wrong state. Use `docker compose down -v` to recreate from scratch.

## Preventive Actions

- [ ] Check for other Homebrew services that might conflict with Docker ports
- [ ] Add a `scripts/diagnose.sh` that lists occupied ports before starting the application
- [ ] In `application-dev.yml`, consider an alternative port (5433) for local PostgreSQL, or an automatic stop via setup script

## Glossary

| Term | Meaning |
|------|---------|
| **Unix Socket** | PostgreSQL's internal connection via socket file (`/var/run/postgresql`) — no password, trusted |
| **TCP** | Network connection — used by JDBC/Spring Boot — requires password authentication |
| **Colima** | Docker runtime for macOS (alternative to Docker Desktop) — uses a Lima Linux VM |
| **KRaft** | Kafka mode without Zookeeper (from version 3.x+) |