# Multi-stage Dockerfile for FairGo Auth Service
# Build: docker build -t fairgo/auth -f services/auth/Dockerfile .

# ============================================================
# Stage 1: Dependencies
# ============================================================
FROM node:24-alpine AS deps

WORKDIR /app

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

# Copy workspace manifests
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY packages/shared-types/package.json ./packages/shared-types/
COPY packages/logger/package.json ./packages/logger/
COPY packages/domain-errors/package.json ./packages/domain-errors/
COPY packages/event-contracts/package.json ./packages/event-contracts/
COPY services/auth/package.json ./services/auth/

# Install dependencies
RUN pnpm install --frozen-lockfile --filter @fairgo/auth-service...

# ============================================================
# Stage 2: Build
# ============================================================
FROM node:24-alpine AS builder

WORKDIR /app

RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/packages/shared-types/node_modules ./packages/shared-types/node_modules
COPY --from=deps /app/packages/logger/node_modules ./packages/logger/node_modules
COPY --from=deps /app/packages/domain-errors/node_modules ./packages/domain-errors/node_modules
COPY --from=deps /app/packages/event-contracts/node_modules ./packages/event-contracts/node_modules
COPY --from=deps /app/services/auth/node_modules ./services/auth/node_modules

# Copy source
COPY tsconfig.base.json ./
COPY packages/shared-types ./packages/shared-types
COPY packages/logger ./packages/logger
COPY packages/domain-errors ./packages/domain-errors
COPY packages/event-contracts ./packages/event-contracts
COPY services/auth ./services/auth

# Build shared packages first
RUN pnpm --filter @fairgo/shared-types build
RUN pnpm --filter @fairgo/domain-errors build
RUN pnpm --filter @fairgo/logger build
RUN pnpm --filter @fairgo/event-contracts build

# Build auth service
RUN pnpm --filter @fairgo/auth-service build

# ============================================================
# Stage 3: Production runtime
# ============================================================
FROM node:24-alpine AS runtime

# Security: run as non-root
RUN addgroup -g 1001 -S fairgo && adduser -u 1001 -S fairgo -G fairgo

WORKDIR /app

# Copy built artifacts
COPY --from=builder --chown=fairgo:fairgo /app/packages/shared-types/dist ./packages/shared-types/dist
COPY --from=builder --chown=fairgo:fairgo /app/packages/logger/dist ./packages/logger/dist
COPY --from=builder --chown=fairgo:fairgo /app/packages/domain-errors/dist ./packages/domain-errors/dist
COPY --from=builder --chown=fairgo:fairgo /app/packages/event-contracts/dist ./packages/event-contracts/dist
COPY --from=builder --chown=fairgo:fairgo /app/services/auth/dist ./services/auth/dist

# Copy production node_modules (no dev deps)
COPY --from=deps --chown=fairgo:fairgo /app/node_modules ./node_modules
COPY --from=deps --chown=fairgo:fairgo /app/services/auth/node_modules ./services/auth/node_modules

USER fairgo

EXPOSE 3001

ENV NODE_ENV=production
ENV PORT=3001

# Health check
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3001/health/live || exit 1

CMD ["node", "services/auth/dist/server.js"]
