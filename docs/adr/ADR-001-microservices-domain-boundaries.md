# ADR-001: Microservices Domain Boundaries

- **Date**: 2026-09-15
- **Status**: Accepted
- **Deciders**: Principal Architect

---

## Context

FairGo is a large platform with many distinct business domains. We need to decide how to slice the backend into independently deployable units.

## Decision

We adopt a **microservices architecture** with the following domain boundaries, each mapping to a separate Node.js/TypeScript service with its own PostgreSQL schema/database and independent deployment lifecycle:

| Service | Responsibility |
|---|---|
| `api-gateway` | Request routing, JWT validation, rate limiting, CORS |
| `auth` | Identity, sessions, OTP, OAuth |
| `rider` | Rider profiles, saved places, preferences |
| `driver` | Driver profiles, KYC, documents, status |
| `vehicle` | Vehicles, RC, insurance, maintenance |
| `trip` | Trip lifecycle state machine |
| `matching` | Driver-rider matching engine |
| `location` | GPS ingestion, WebSocket, Redis GEO |
| `pricing` | Fare calculation, surge, simulation |
| `parcel` | Parcel bookings, batching |
| `driver-booking` | Book-a-Driver hourly/per-trip |
| `payment` | Payment intents, capture, refunds |
| `wallet` | Double-entry ledger, payouts |
| `coupon` | Coupon validation, budgets |
| `loyalty` | Tiers, cashback, referrals |
| `corporate` | Corporate accounts, billing |
| `insurance` | Policy abstraction, claims |
| `safety` | SOS, escalation, emergency contacts |
| `notification` | Push, SMS, email, in-app |
| `support` | Tickets, chat, chatbot |
| `fraud` | Risk scoring, rules engine |
| `analytics` | Reporting, cohorts, forecasting |

### Communication Patterns
- **Synchronous (REST)**: Used when a caller needs an immediate response (e.g., trip service calling pricing service for fare).
- **Asynchronous (Kafka)**: Used for domain events (e.g., `trip.completed` → triggers wallet credit, loyalty points, invoice generation). Services never share databases.

## Consequences

### Positive
- Independent deployment and scaling per domain.
- Team autonomy; each service can evolve independently.
- Fault isolation; a notification failure doesn't fail a trip.

### Negative
- Distributed system complexity (network failures, eventual consistency).
- Requires Kafka, Redis, and observability tooling from day one.
- Local development requires Docker Compose to run dependencies.

### Mitigations
- Shared TypeScript types via `@fairgo/shared-types`.
- Versioned Kafka event contracts via `@fairgo/event-contracts`.
- Correlation IDs propagated across all service calls for tracing.
- Outbox/inbox pattern for reliable event delivery.
