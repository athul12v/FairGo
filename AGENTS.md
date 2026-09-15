# AGENTS.md — FairGo Engineering Rules

This file governs all contributors (human and AI) working on the FairGo platform.
**All contributors must read and follow these rules without exception.**

---

## 1. Language & Type Safety

- All backend code is **TypeScript 5** with `strict: true` plus the following extras enabled:
  - `noUncheckedIndexedAccess`
  - `exactOptionalPropertyTypes`
  - `noImplicitOverride`
  - `noPropertyAccessFromIndexSignature`
- **`any` is forbidden** unless explicitly justified with a comment beginning `// JUSTIFICATION: any —`.
- Never use `// @ts-ignore` or `// @ts-nocheck` unless paired with a GitHub issue reference.
- All exported functions must have explicit return types.
- Prefer `type` imports (`import type { Foo } from '...'`).

---

## 2. Architecture Rules

- **Controllers are thin**: HTTP/WS layer only — no business logic, no DB access.
- **Business logic belongs in the domain/application layer** (`src/domain/` or `src/application/`).
- **No cross-service DB access**: services communicate via REST (sync) or Kafka (async). A service never touches another service's tables.
- **Domain events are versioned** (`v1`, `v2`, …) using JSON Schema in `packages/event-contracts/`.
- **State machines are explicit**: Use `xstate` or a custom state machine class; no ad-hoc status strings.
- **Financial amounts are integers** (paise / smallest currency unit). Never use `float` for money.
- **Ledger entries are immutable**: No `UPDATE` or `DELETE` on `ledger_entries`. Only insert correction entries.
- **Database schema changes require migrations**: No ad-hoc `ALTER TABLE` in application code.

---

## 3. Security Rules

- **No secrets in repository**: All credentials use environment variables. See `.env.example` per service.
- **Never log PII** (phone numbers, emails, card data, GPS coordinates of users at rest).
- **Rate limiting** must be applied at the API gateway level for all public endpoints.
- **RBAC**: Every API endpoint must declare its required role/permission in the route definition.
- **Webhook payloads** must be signature-verified (HMAC-SHA256) before processing.
- **Idempotency keys** are required for all payment and wallet mutation operations.
- **Signed URLs** for all user-uploaded documents (never expose raw storage paths).

---

## 4. API Design Rules

- External APIs follow **OpenAPI 3.1**. Update the spec file (`docs/api/<service>.openapi.yaml`) alongside code changes.
- API versions are prefix-based (`/v1/`, `/v2/`). Breaking changes require a new version.
- All API responses follow the envelope schema:
  ```json
  { "success": true, "data": { ... }, "meta": { ... } }
  { "success": false, "error": { "code": "ERR_...", "message": "...", "details": [...] } }
  ```
- Paginated endpoints use cursor-based pagination (not offset).
- All responses include `X-Request-ID` and `X-Correlation-ID` headers.

---

## 5. Event Design Rules

- Kafka topics are named: `fairgo.<domain>.<event-name>` (e.g., `fairgo.trip.completed`).
- Every event envelope contains: `eventId`, `eventType`, `version`, `occurredAt`, `correlationId`, `payload`.
- **Outbox pattern**: Services write events to an `outbox` table in the same DB transaction as the state change. A relay process publishes to Kafka.
- **Inbox pattern**: Consumers write processed event IDs to prevent duplicate processing.
- Dead-letter topics: `fairgo.<domain>.<event-name>.dlq`.
- Schema Registry (Confluent) enforces backward-compatible schema evolution.

---

## 6. Testing Rules

- **Unit tests** required for: domain logic, state machines, pricing calculations, matching rules, ledger operations.
- **Integration tests** required for: API endpoints, DB interactions, Kafka producer/consumer.
- **Contract tests** required for: OpenAPI contracts (Schemathesis), Kafka event schemas.
- **E2E tests** required for: complete trip flow (Phase 5+).
- Test files: `*.test.ts` co-located with source, or in `src/__tests__/`.
- **Never delete or disable tests** to make a build pass. Fix the underlying issue.
- Test coverage minimum: **80%** for domain layer, **70%** overall.
- Tests must pass before merging to `main`.

---

## 7. Observability Rules

- All services use **structured logging** (pino) with: `level`, `service`, `requestId`, `correlationId`, `userId`, `driverId`, `tripId` where applicable.
- Every incoming request gets a `requestId` (UUID v4) injected by the gateway.
- **Traces** are emitted via OpenTelemetry SDK to Jaeger.
- **Metrics** are exposed via `/metrics` endpoint (Prometheus format).
- **Health checks**: `/health/live` (liveness) and `/health/ready` (readiness) on every service.
- **Error tracking**: Sentry SDK initialized in every service.
- Never use `console.log` — use the shared `@fairgo/logger` package.

---

## 8. Mobile Rules (Flutter)

- State management: **Riverpod** (code generation variant).
- Navigation: **go_router** with typed routes.
- HTTP: **Dio** with interceptors for auth/retry.
- All screens handle: loading state, empty state, error state, offline state.
- Battery-aware location: adaptive interval based on speed (stationary → 30s, slow → 10s, fast → 3s).
- Offline queue: local SQLite (drift) for location points and commands when offline.
- All strings are localization keys (`flutter_localizations` + ARB files). No hardcoded UI strings.
- Accessibility: `Semantics` widget on all interactive elements; minimum touch target 48×48dp.

---

## 9. Infrastructure Rules

- All services are containerized (Dockerfile in each service directory).
- Kubernetes: requests/limits must be set on every container.
- **ConfigMaps** for non-sensitive config; **Secrets** backed by AWS Secrets Manager via External Secrets Operator.
- **Never store real credentials** in Terraform vars files — use `terraform.tfvars.example` with placeholder values.
- Database connection pooling (PgBouncer) is required in production.
- Migrations run as a Job before rolling deployment.
- Rollback plan required for every production deployment.

---

## 10. Documentation Rules

- **ADRs** (Architecture Decision Records) in `docs/adr/ADR-NNN-title.md`. Create an ADR for any significant architectural decision.
- OpenAPI specs stay in sync with implementation — enforced by CI contract tests.
- Runbooks in `docs/runbooks/` for every critical operational procedure.
- `README.md` in every service: purpose, local setup, environment variables, endpoints.
- Changelog in `CHANGELOG.md` (Keep a Changelog format).
- Implementation status updated in `docs/STATUS.md` after each milestone.

---

## 11. Integration Boundaries

When a real external credential/integration is unavailable:
- Build the correct **adapter interface** (e.g., `PaymentProvider`, `MapsProvider`, `SMSProvider`).
- Implement a **local/test adapter** that works without credentials.
- Mark the integration boundary with a `// INTEGRATION_BOUNDARY:` comment.
- Document in `docs/runbooks/integrations.md` what credentials/setup is required to go live.
- **Never fabricate production credentials** or claim an integration is live when it is not.

---

## 12. Git Rules

- Branch naming: `feat/<ticket>-<short-description>`, `fix/<ticket>-<description>`, `chore/<description>`.
- Commit messages follow **Conventional Commits** (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`).
- All PRs require: passing CI, at least one reviewer approval, no merge conflicts.
- **Squash merges** to keep `main` history clean.
- Protected branch: `main`. Force-push is forbidden.

---

## 13. Feature Flags

- Risky releases must be behind a feature flag (LaunchDarkly or GrowthBook adapter).
- Feature flags default to `OFF`. The flag adapter is in `@fairgo/feature-flags`.
- A/B experiments use the same flag system with variant assignment.
- Document all active flags in `docs/feature-flags.md`.

---

## Compliance Notes

> FairGo is designed to align with applicable Indian regulations including RBI PPI guidelines,
> DPDP Act data residency requirements, and GST invoicing rules. **This is not legal certification.**
> Actual compliance certification requires independent legal review, external audit, and operational controls
> beyond what code alone can provide. All integration boundaries with regulatory systems (RBI, NPCI, GST)
> are documented in `docs/runbooks/compliance.md`.
