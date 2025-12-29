# ==============================================================================
# Multi-stage Dockerfile for Phoenix/Elixir application
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build dependencies and compile assets
# ------------------------------------------------------------------------------
FROM elixir:1.15-slim AS builder

# Install build dependencies
RUN apt-get update -y && \
    apt-get install -y build-essential git curl && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Set working directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build environment
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mkdir config

# Copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger recompilation
COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

# Copy source code first (needed for phoenix-colocated hooks)
COPY lib lib
COPY .formatter.exs .formatter.exs

# Compile the project (generates phoenix-colocated hooks)
RUN mix compile

# Copy assets and database files
COPY assets assets
COPY priv priv

# Compile assets (now phoenix-colocated hooks are available)
# Note: if using a separate node build step, you can adjust this
RUN mix assets.deploy

# Copy runtime configuration (loaded at runtime, not compile time)
COPY config/runtime.exs config/

# Build the release
RUN mix release

# ------------------------------------------------------------------------------
# Stage 2: Create minimal runtime image
# ------------------------------------------------------------------------------
FROM debian:bookworm-slim AS runner

# Install runtime dependencies
RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create app user
RUN useradd -m -u 1000 -s /bin/bash app

# Set working directory
WORKDIR /app

# Change ownership
RUN chown app:app /app

# Switch to non-root user
USER app

# Copy the release from builder
COPY --from=builder --chown=app:app /app/_build/prod/rel/whoknows_elixir_monolith ./

# Create directory for SQLite database (needs write permissions)
RUN mkdir -p /app/priv/repo

# Remove write permissions from application code for security (except database directory)
RUN find /app -type d -not -path "/app/priv/repo*" -exec chmod a-w {} + && \
    find /app -type f -exec chmod a-w {} +

# Copy migrations and seeds (these are already in the release, but we make them explicit)
# The release already includes priv/repo/* from the builder stage

# Set environment variables
ENV HOME=/app
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:4000/ || exit 1

# Start the Phoenix app
CMD ["/app/bin/whoknows_elixir_monolith", "start"]
