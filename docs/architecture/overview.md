# FairGo — System Architecture Overview

## System Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                                   │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────────┐    │
│  │  Rider Mobile    │  │  Driver Mobile   │  │  Admin Web / Corp  │    │
│  │  (Flutter)       │  │  (Flutter)       │  │  Portal (Next.js)  │    │
│  └────────┬─────────┘  └────────┬─────────┘  └─────────┬──────────┘    │
└───────────┼──────────────────────┼──────────────────────┼───────────────┘
            │  HTTPS / WSS         │  HTTPS / WSS         │  HTTPS
            ▼                      ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY (Kong / Express)                     │
│  JWT Validation │ Rate Limiting │ CORS │ Request ID │ Route Dispatch     │
└──────┬──────────────────────────────────────────────────┬───────────────┘
       │ REST/HTTP                                         │ WebSocket (WS)
       ▼                                                   ▼
┌──────────────────────────────────────┐   ┌──────────────────────────────┐
│         SYNCHRONOUS SERVICES         │   │      REALTIME SERVICES        │
│                                      │   │                              │
│  auth      rider     driver          │   │  location (WS server)        │
│  vehicle   trip      pricing         │   │  trip-events (WS broadcast)  │
│  matching  parcel    driver-booking  │   │  chat (WS)                   │
│  payment   wallet    coupon          │   │                              │
│  loyalty   corporate insurance       │   └──────────────────────────────┘
│  safety    support   fraud           │
│  analytics notification              │
└──────────────────┬───────────────────┘
                   │
       ┌───────────┼──────────────────────────────────────────────┐
       │           │                                              │
       ▼           ▼                                              ▼
┌──────────┐ ┌──────────────────┐                        ┌──────────────┐
│ Firebase │ │     Redis 7      │                        │    Kafka     │
│ Firestore│ │  Cache │ GEO     │                        │  Event Bus   │
│          │ │  Pub/Sub │ Locks │                        │              │
│Per-collec│ │  Session Store   │                        │ Schema Reg.  │
│  schema  │ │  Rate Limiter    │                        │              │
└──────────┘ └──────────────────┘                        └──────────────┘
```

## Services Map

### Core Platform
| Service | Port | Description |
|---|---|---|
| api-gateway | 3000 | Request routing, auth, rate limiting |
| auth | 3001 | Identity, OTP, JWT, sessions |
| rider | 3002 | Rider profiles, preferences |
| driver | 3003 | Driver profiles, KYC, documents |
| vehicle | 3004 | Vehicle registry, RC, insurance |
| trip | 3005 | Trip lifecycle state machine |
| matching | 3006 | Driver-rider matching engine |
| location | 3007 | GPS ingestion, WebSocket |
| pricing | 3008 | Fare engine, surge |

### Commerce & Finance
| Service | Port | Description |
|---|---|---|
| payment | 3009 | Payment intents, capture, refunds |
| wallet | 3010 | Ledger, payouts, top-ups |
| coupon | 3011 | Coupon engine |
| loyalty | 3012 | Tiers, cashback, referrals |
| corporate | 3013 | Corporate billing |
| insurance | 3014 | Policy abstraction |

### Operations & Support
| Service | Port | Description |
|---|---|---|
| parcel | 3015 | Parcel delivery |
| driver-booking | 3016 | Book-a-Driver |
| safety | 3017 | SOS, escalation |
| notification | 3018 | Push, SMS, email |
| support | 3019 | Tickets, chat, chatbot |
| fraud | 3020 | Risk scoring |
| analytics | 3021 | Reporting, forecasting |

### Infrastructure (local dev)
| Service | Port | Description |
|---|---|---|
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Cache / GEO / pub-sub |
| Kafka | 9092 | Event bus |
| Zookeeper | 2181 | Kafka coordinator |
| Schema Registry | 8081 | Avro/JSON schema registry |
| Kafka UI | 8080 | Dev UI for Kafka inspection |
| RedisInsight | 8001 | Dev UI for Redis inspection |
| Jaeger | 16686 | Distributed tracing UI |
| Prometheus | 9090 | Metrics |
| Grafana | 3100 | Dashboards |

## Data Flow: Bike Ride End-to-End

```
1. Rider opens app → GET /v1/pricing/estimate (pricing service)
2. Rider confirms booking → POST /v1/trips (trip service)
   - trip.status = SEARCHING
   - Publishes booking.created event
3. Matching service receives booking.created
   - Queries Redis GEO: GEORADIUS fairgo:drivers:live ...
   - Filters by: BIKE type, online, not in trip
   - Locks driver with Redis SETNX (prevents race conditions)
   - PUT /v1/trips/:id/driver (trip service)
   - trip.status = DRIVER_ASSIGNED
   - Publishes driver.assigned event
4. Driver app receives ride request (WebSocket push)
   - Countdown timer: 30 seconds to accept
   - Driver accepts → trip.status = DRIVER_EN_ROUTE
5. Driver arrives → trip.status = DRIVER_ARRIVED
   - Rider receives OTP
6. Driver enters OTP → trip.status = IN_PROGRESS
   - Location updates stream to rider (sub-5s)
7. Driver completes trip → trip.status = COMPLETED
   - Publishes trip.completed event
8. payment service: captures payment
   - Publishes payment.captured event
9. wallet service: credits driver earnings
10. loyalty service: awards cashback/points
11. notification service: sends receipt
12. Rider rates driver
```
