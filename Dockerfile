# =============================================================================
# Build Stage
# =============================================================================
FROM haskell:9.10-slim AS builder

WORKDIR /build

# Install system dependencies needed for compiling SQLite & Cabal builds
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    pkg-config \
    zlib1g-dev \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Cache dependencies layer
COPY scotty-starter.cabal cabal.project ./
RUN cabal update && cabal build --only-dependencies -j

# Copy source code and build production binary
COPY . .
RUN cabal build exe:scotty-starter --enable-optimization=2 \
 && cp "$(cabal list-bin exe:scotty-starter)" /build/scotty-starter

# =============================================================================
# Runtime Stage
# =============================================================================
FROM debian:bookworm-slim AS runner

WORKDIR /app

# Install minimal runtime shared libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libsqlite3-0 \
    libgmp10 \
    curl \
    netbase \
 && rm -rf /var/lib/apt/lists/*

# Run as non-root unprivileged user for security
RUN groupadd -r scotty && useradd -r -g scotty -d /app -s /sbin/nologin scotty

# Copy compiled executable and static directory
COPY --from=builder /build/scotty-starter /app/scotty-starter
COPY static/ /app/static/

# Prepare database directory with proper permissions
RUN mkdir -p /app/data && chown -R scotty:scotty /app

USER scotty

# Configuration environment variables
ENV PORT=3000 \
    SCOTTY_ENV=production \
    DATABASE_URL=sqlite:///app/data/scotty.db

EXPOSE 3000

# Docker healthcheck querying the /healthz liveness probe
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/healthz || exit 1

ENTRYPOINT ["/app/scotty-starter"]

