# ADR-003: Realtime Location Architecture

- **Date**: 2026-09-15
- **Status**: Accepted
- **Deciders**: Principal Architect

---

## Context

Driver location must be updated in near-realtime (target: rider sees driver move within 3–5 seconds). We need to handle:
- Thousands of concurrent active drivers
- High GPS write throughput
- Redis geospatial queries for matching
- Battery-efficient mobile tracking
- Offline buffering on mobile

## Decision

### Architecture

```
Driver App  →(WebSocket)→  Location Service  →(Redis GEO)→  Matching Service
                                ↓
                         Outbox (PostgreSQL)  →(Kafka)→  Analytics / History
```

1. **Driver App** sends GPS points over a persistent WebSocket connection to the Location Service.
2. **Adaptive Sampling**: The app adjusts GPS send frequency based on speed:
   - Stationary (< 2 km/h): every 30 seconds
   - Walking/slow (2–20 km/h): every 10 seconds
   - Moving fast (> 20 km/h): every 3 seconds
   - Active trip: every 2 seconds (priority mode)
3. **Location Service** writes each point to Redis GEO (`GEOADD fairgo:drivers:live <lon> <lat> <driverId>`) in-memory immediately. This is the **hot path** — no PostgreSQL write on every GPS point.
4. **Redis TTL**: Driver geo entry expires after 90 seconds of inactivity (marks driver as effectively offline).
5. **Kafka outbox**: Every Nth point (configurable, default: every 30 seconds or on significant movement) is written to the `fairgo.location.driver-moved` topic for persistence, analytics, and trip polyline reconstruction.
6. **Last-known state**: Redis hash `fairgo:driver:<id>:lastloc` stores the most recent full location snapshot (lat, lon, bearing, speed, accuracy, timestamp).
7. **Offline buffering**: Mobile stores unsent points in local SQLite. On reconnection, it flushes the queue with timestamps intact. The server deduplicates by `(driverId, timestamp)`.

### WebSocket Protocol

Messages are binary-encoded (MessagePack) to minimize payload size:
```json
// Client → Server (location update)
{ "t": "loc", "lat": 12.9716, "lon": 77.5946, "spd": 35.2, "hdg": 270, "acc": 5.0, "ts": 1726412345678 }

// Server → Rider Client (driver position update during trip)  
{ "t": "drv_loc", "driverId": "uuid", "lat": 12.9716, "lon": 77.5946, "hdg": 270, "eta": 240 }
```

### Rider Map Updates
During an active trip, the Trip Service subscribes to Redis pub/sub channel `fairgo:trip:<tripId>:loc` and forwards driver updates to the rider's WebSocket connection. Sub-5 second latency target.

## Consequences

### Positive
- Redis GEO handles sub-millisecond geospatial queries for matching.
- No PostgreSQL hot path on GPS writes prevents DB overload.
- Battery-efficient adaptive sampling.
- Offline support with local queue.

### Negative
- Redis is the source of truth for live location — requires Redis HA (cluster/sentinel).
- Location history requires Kafka consumer to persist to a time-series or append table.
- WebSocket connections require sticky sessions or Redis-backed session store.

### Mitigations
- Redis Sentinel (dev) / Redis Cluster (production) for HA.
- Location history stored in a partitioned `driver_location_history` table (partitioned by day, pruned after 30 days).
- Kubernetes Ingress with WebSocket support (sticky sessions via cookie).
