# ADR-002: Financial Ledger Design — Double-Entry, Immutable, Integer-Only

- **Date**: 2026-09-15
- **Status**: Accepted
- **Deciders**: Principal Architect, Finance Domain Lead

---

## Context

FairGo handles real money: rider payments, driver earnings, wallet top-ups, cashback, refunds, and payouts. We need a financial data model that is correct, auditable, and compliant with Indian regulations (RBI PPI guidelines).

## Decision

### 1. Integer-Only Amounts
All monetary amounts are stored as **integers in paise** (1 INR = 100 paise). Never use `FLOAT`, `DOUBLE`, or `DECIMAL` for money amounts in application code. Use `BIGINT` in PostgreSQL.

### 2. Double-Entry Ledger
Every financial movement creates exactly two `ledger_entry` rows: one debit and one credit. The sum of all entries for a given account must always equal zero (when treating debits as negative). This makes reconciliation trivially verifiable.

Example: Rider pays ₹150 for a trip:
```
DEBIT  rider_wallet_A    150_00  (rider's balance decreases)
CREDIT trip_escrow_T001  150_00  (held in escrow)
```
On trip completion:
```
DEBIT  trip_escrow_T001  150_00
CREDIT driver_wallet_B   135_00  (driver's 90%)
CREDIT platform_revenue  15_00   (platform's 10%)
```

### 3. Immutable Records
Ledger entries are **never updated or deleted**. Corrections are new entries with a reference to the original. Status transitions happen on separate `payments` and `wallet_transactions` tables; the ledger only records settled movements.

### 4. RBI Compliance
- Wallet balances for riders who have completed KYC: up to ₹2,00,000 (full KYC) or ₹10,000 (minimum KYC).
- All PPI wallet top-ups via regulated payment methods only.
- Monthly transaction limits enforced at the application layer with database constraints as backup.

## Consequences

### Positive
- Zero floating-point rounding errors.
- Perfect audit trail — every paise is accounted for.
- Easy reconciliation against payment provider statements.
- Regulatory alignment with RBI guidelines.

### Negative
- Slightly more complex queries (need to aggregate debit/credit pairs).
- More rows than a simple balance update approach.

### Mitigations
- Materialized views for account balances (refreshed on each ledger write).
- Index on `(account_id, created_at)` for efficient balance calculations.
