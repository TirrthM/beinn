# Operations Runbook

This runbook contains procedures for monitoring, scaling, and recovering the Beinn platform in a production environment.

## Incident Management

### Scenario A: High WebSocket Latency
**Symptoms:** Drivers report location not updating; customers see frozen map markers.
**Investigation:**
1. Check Redis CPU and memory utilization.
2. Check NestJS instances CPU usage. Socket.IO can heavily tax a single Node.js thread.
**Resolution:**
- Scale the NestJS ECS tasks horizontally. Ensure the Redis adapter is properly configured so instances can share events.

### Scenario B: Database Connection Exhaustion
**Symptoms:** REST API endpoints timeout; PostgreSQL reports `FATAL: sorry, too many clients already`.
**Investigation:**
1. Check the PgBouncer/Connection pooler metrics.
2. Identify slow PostGIS queries (`ST_Distance`) locking up connections.
**Resolution:**
- Temporarily increase the maximum connection limit.
- Run `EXPLAIN ANALYZE` on the spatial queries and ensure spatial indexes (GIST) are correctly built on the `geog` columns.

## Routine Maintenance

### Database Migrations
Migrations should only be run during low-traffic windows (e.g., 3:00 AM local time).
```bash
NODE_ENV=production npm run typeorm migration:run
```

### Log Rotation & Cleanup
Driver ephemeral location data stored in Redis has a TTL of 24 hours. Ensure old completed order routing logs in Postgres are archived to cold storage monthly to maintain query performance.
