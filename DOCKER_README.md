# Docker Setup Guide - WhoKnows Elixir Monolith

This comprehensive guide explains the complete Docker setup for the WhoKnows Elixir/Phoenix application, including the monitoring stack (Prometheus & Grafana) and database seeding system.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Detailed Component Breakdown](#detailed-component-breakdown)
5. [Database & Seed Data](#database--seed-data)
6. [Monitoring Stack](#monitoring-stack)
7. [Useful Commands](#useful-commands)
8. [Troubleshooting](#troubleshooting)
9. [Production Considerations](#production-considerations)

---

## Architecture Overview

The Docker setup consists of **three main services** running in a shared network:

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Network                        │
│                     (monitoring)                         │
│                                                          │
│  ┌──────────────┐   ┌──────────────┐   ┌────────────┐ │
│  │   Phoenix    │──▶│  Prometheus  │──▶│  Grafana   │ │
│  │     App      │   │              │   │            │ │
│  │  Port: 4000  │   │  Port: 9090  │   │ Port: 3000 │ │
│  │  Metrics:    │   │              │   │            │ │
│  │    9568      │   │              │   │            │ │
│  └──────┬───────┘   └──────────────┘   └────────────┘ │
│         │                                               │
│    ┌────▼─────┐                                        │
│    │ SQLite   │                                        │
│    │   DB     │                                        │
│    │(Volume)  │                                        │
│    └──────────┘                                        │
└─────────────────────────────────────────────────────────┘
```

### Services:

1. **Phoenix Application**: The main Elixir/Phoenix web application
2. **Prometheus**: Metrics collection and time-series database
3. **Grafana**: Metrics visualization and dashboards

---

## Prerequisites

- **Docker Desktop** (or Docker Engine + Docker Compose)
- **Python 3.x** (for database export scripts - optional)
- **Git** (for version control)

---

## Quick Start

### Step 1: Environment Configuration

The application uses a `.env` file for configuration. This file is already created with all necessary secrets:

```bash
# View the .env file (already configured)
cat .env
```

The `.env` file contains:
- `SECRET_KEY_BASE`: Cryptographic secret for Phoenix (auto-generated)
- `PHX_HOST`: Application hostname
- `GRAFANA_USER` & `GRAFANA_PASSWORD`: Grafana admin credentials

### Step 2: Start All Services

```bash
# Build and start all containers
docker-compose up -d --build
```

This command will:
1. Build the Phoenix application Docker image
2. Pull Prometheus and Grafana images
3. Create Docker volumes for persistent data
4. Start all three services
5. Run database migrations
6. Seed the database with initial data

### Step 3: Verify Services

Check that all containers are running:
```bash
docker-compose ps
```

You should see:
- `whoknows_app` - healthy
- `prometheus` - up
- `grafana` - up

### Step 4: Access the Application

- **Phoenix App**: http://localhost:4000
- **Grafana**: http://localhost:3000 (login: admin/admin)
- **Prometheus**: http://localhost:9090
- **App Metrics**: http://localhost:9568/metrics

---

## Detailed Component Breakdown

### 1. Dockerfile (Multi-Stage Build)

The `Dockerfile` uses a **multi-stage build** strategy for optimization:

#### **Stage 1: Builder** (`elixir:1.15-slim`)
```dockerfile
FROM elixir:1.15-slim AS builder
```

**What happens in this stage:**

1. **Install Build Dependencies**
   - `build-essential`: C compiler for native dependencies
   - `git`: For fetching dependencies
   - `curl`: For downloading tools

2. **Install Hex & Rebar** (Elixir package managers)
   ```dockerfile
   RUN mix local.hex --force && mix local.rebar --force
   ```

3. **Set Production Environment**
   ```dockerfile
   ENV MIX_ENV=prod
   ```

4. **Install Dependencies**
   - Copies `mix.exs` and `mix.lock`
   - Runs `mix deps.get --only prod`
   - Compiles dependencies

5. **Compile Application Code**
   - **Important**: Code is compiled BEFORE assets to generate `phoenix-colocated` hooks
   - The order matters: `lib/` → `mix compile` → `assets/` → `mix assets.deploy`

6. **Build Frontend Assets**
   - Installs Tailwind CSS
   - Installs esbuild
   - Compiles JavaScript and CSS
   - Runs `mix assets.deploy` (minifies for production)

7. **Create Release**
   - Runs `mix release`
   - Generates a self-contained Erlang/Elixir release in `_build/prod/rel/whoknows_elixir_monolith/`

#### **Stage 2: Runner** (`debian:bookworm-slim`)
```dockerfile
FROM debian:bookworm-slim AS runner
```

**What happens in this stage:**

1. **Install Runtime Dependencies Only**
   - `libstdc++6`, `openssl`, `libncurses5`: Required for Erlang VM
   - `locales`, `ca-certificates`: System essentials
   - `curl`: For health checks

2. **Create Non-Root User**
   ```dockerfile
   RUN useradd -m -u 1000 -s /bin/bash app
   ```
   - Security best practice: never run as root

3. **Copy Release from Builder**
   - Only the compiled release is copied (not source code)
   - This makes the final image much smaller (~200MB vs ~1GB)

4. **Set Health Check**
   ```dockerfile
   HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:4000/
   ```
   - Docker monitors application health
   - Prometheus/Grafana wait for app to be healthy before starting

5. **Start Command**
   ```dockerfile
   CMD ["/app/bin/whoknows_elixir_monolith", "start"]
   ```

**Why Multi-Stage Build?**
- **Smaller Image**: Final image is ~80% smaller (only runtime, no build tools)
- **Faster Deployment**: Less data to transfer
- **More Secure**: No build tools in production image
- **Better Performance**: Optimized release build

---

### 2. Docker Compose Configuration

The `docker-compose.yml` orchestrates all services:

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "4000:4000"    # Phoenix web server
      - "9568:9568"    # Prometheus metrics
    environment:
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - PHX_HOST=${PHX_HOST:-localhost}
      - DATABASE_PATH=/app/priv/repo/prod.db
    volumes:
      - app_data:/app/priv/repo    # Persistent SQLite database
    command: >
      sh -c "
        /app/bin/whoknows_elixir_monolith eval 'WhoknowsElixirMonolith.Release.migrate()' &&
        /app/bin/whoknows_elixir_monolith eval 'WhoknowsElixirMonolith.Release.seed()' &&
        /app/bin/whoknows_elixir_monolith start
      "
```

**The startup sequence:**
1. **Migrate**: Run database migrations (create tables)
2. **Seed**: Populate database with initial data (51 pages + 1 admin user)
3. **Start**: Launch the Phoenix web server

---

## Database & Seed Data

### SQLite Database

The application uses **SQLite** as its database:

**Location in Container**: `/app/priv/repo/prod.db`
**Persistent Storage**: Docker volume `app_data`
**Schema**: Defined by migrations in `priv/repo/migrations/`

#### Tables:
- `pages`: Stores Wikipedia articles (title, url, language, content, last_updated)
- `users`: User accounts with PBKDF2 password hashing
- `users_tokens`: Authentication tokens

### Automatic Database Setup

On container startup, the application automatically:

1. **Runs Migrations** via `Release.migrate/0`
   ```elixir
   # lib/whoknows_elixir_monolith/release.ex
   def migrate do
     for repo <- repos() do
       {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
     end
   end
   ```

2. **Seeds Data** via `Release.seed/0`
   ```elixir
   def seed do
     seed_script = Application.app_dir(:whoknows_elixir_monolith, "priv/repo/seeds.exs")
     Code.eval_file(seed_script)
   end
   ```

### Seed Data: 51 Wikipedia Pages + 1 Admin User

The `priv/repo/seeds.exs` file contains:

**51 Wikipedia Pages** covering topics like:
- Fortran
- COBOL
- And 49 other programming language/CS topics

**1 Admin User**:
- Email: `keamonk@stud.kea.dk`
- Password: `AdminPassword123!`
- Password Hash: PBKDF2-SHA512 (100,000 rounds)
- Status: Confirmed (can login immediately)

### How the Seed Data Was Created

#### Step 1: Export from Existing Database

We had an existing `whoknows.db` SQLite file with production data. To export it:

1. **Created Python export script** (`dump_pages.py`):
   ```python
   import sqlite3
   import json

   conn = sqlite3.connect('whoknows.db')
   cursor = conn.cursor()
   cursor.execute('SELECT title, url, language, last_updated, content FROM pages')
   pages_data = cursor.fetchall()

   # Export to JSON
   with open('pages_data.json', 'w', encoding='utf-8') as f:
       json.dump(pages_list, f, indent=2)
   ```

2. **Ran the export**:
   ```powershell
   python dump_pages.py
   # Output: pages_data.json (50 pages, ~980KB)
   ```

#### Step 2: Generate Elixir Seed File

Created `generate_seeds.py` to convert JSON to Elixir format:

```python
import json

with open('pages_data.json', 'r') as f:
    pages = json.load(f)

# Generate Elixir seed code
for page in pages:
    print(f'''
%Page{{
  title: "{page['title']}",
  url: "{page['url']}",
  language: "{page['language']}",
  last_updated: ~U[{page['last_updated']}Z],
  content: """
{page['content']}
"""
}} |> Repo.insert!()
''')
```

**Key Challenges Solved:**
- **Special Characters**: Escaped quotes and backslashes in content
- **Large Content**: Some Wikipedia articles are 50KB+ of text
- **Date Format**: Converted from `YYYY-MM-DD HH:MM:SS` to Elixir `~U[...]Z` sigil
- **Password Hashing**: Used pre-hashed PBKDF2 password (Bcrypt not available in production release)

#### Step 3: Usage

To regenerate seeds (if you update `whoknows.db`):

```powershell
# 1. Export database to JSON
python dump_pages.py

# 2. Generate seeds.exs from JSON
python generate_seeds.py

# 3. Rebuild Docker image
docker-compose up -d --build
```

---

## Monitoring Stack

### Prometheus (Metrics Collection)

**Purpose**: Collects and stores time-series metrics from the Phoenix application

**Configuration** (`prometheus.yml`):
```yaml
scrape_configs:
  - job_name: 'phoenix_app'
    static_configs:
      - targets: ['app:9568']  # Scrape metrics from Phoenix app
```

**What Metrics Are Collected:**
- HTTP request duration
- Request count (by status code, route)
- Erlang VM metrics (memory, processes, schedulers)
- Database query performance
- Custom business metrics

**Access**: http://localhost:9090

**Query Examples**:
```promql
# Average request duration
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# Requests per second
rate(http_requests_total[1m])

# Memory usage
erlang_vm_memory_bytes_total{kind="total"}
```

### Grafana (Visualization)

**Purpose**: Visualize Prometheus metrics with dashboards

**Pre-configured**:
- Data source: Prometheus (auto-configured)
- Dashboards: Located in `grafana/dashboards/whoknows_dashboard.json`

**Access**: http://localhost:3000
**Login**: admin / admin (change this in production!)

**Dashboard Features**:
- Request rate and latency graphs
- Error rate tracking
- Database performance
- System resource usage

---

## Useful Commands

### Container Management

```bash
# Start all services
docker-compose up -d

# Start with live logs (foreground)
docker-compose up

# Stop all services
docker-compose down

# Stop and remove volumes (⚠️ DELETES DATABASE)
docker-compose down -v

# Restart a specific service
docker-compose restart app

# Rebuild and restart
docker-compose up -d --build
```

### Logs & Debugging

```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View app logs only
docker-compose logs -f app

# Last 50 lines
docker-compose logs --tail=50 app

# Check container status
docker-compose ps

# Inspect a container
docker inspect whoknows_app
```

### Database Operations

```bash
# Run migrations manually
docker-compose exec app /app/bin/whoknows_elixir_monolith eval "WhoknowsElixirMonolith.Release.migrate()"

# Run seeds manually
docker-compose exec app /app/bin/whoknows_elixir_monolith eval "WhoknowsElixirMonolith.Release.seed()"

# Access Elixir console (IEx)
docker-compose exec app /app/bin/whoknows_elixir_monolith remote

# Query database from IEx
WhoknowsElixirMonolith.Repo.all(WhoknowsElixirMonolith.Page) |> length()
# => 51

# Export database from container
docker-compose exec app cp /app/priv/repo/prod.db /tmp/backup.db
docker cp whoknows_app:/tmp/backup.db ./prod_backup.db
```

### Performance & Monitoring

```bash
# Check metrics endpoint
curl http://localhost:9568/metrics

# Check application health
curl http://localhost:4000/

# View Prometheus targets
curl http://localhost:9090/api/v1/targets

# Container resource usage
docker stats whoknows_app
```

---

## Troubleshooting

### Issue: Container Won't Start

**Symptoms**: `docker-compose up` fails or container exits immediately

**Solution**:
```bash
# Check logs for errors
docker-compose logs app

# Common issues:
# 1. Missing SECRET_KEY_BASE in .env
# 2. Port 4000 already in use
# 3. Syntax error in seeds.exs
```

### Issue: Database Not Seeding

**Symptoms**: Application starts but no data in database

**Solution**:
```bash
# Check if seeds ran
docker-compose logs app | grep "Seeding"

# Manually run seeds
docker-compose exec app /app/bin/whoknows_elixir_monolith eval "WhoknowsElixirMonolith.Release.seed()"

# Verify data
docker-compose exec app /app/bin/whoknows_elixir_monolith eval "WhoknowsElixirMonolith.Repo.aggregate(WhoknowsElixirMonolith.Page, :count)"
```

### Issue: Prometheus Can't Scrape Metrics

**Symptoms**: Prometheus shows targets as "Down"

**Solution**:
1. Check if app is running: `curl http://localhost:9568/metrics`
2. Verify network: `docker-compose exec prometheus ping app`
3. Check `prometheus.yml` target: `app:9568`

### Issue: Build Fails with "phoenix-colocated not found"

**Symptoms**: esbuild error during `mix assets.deploy`

**Reason**: Assets were built before Elixir code was compiled

**Solution**: This is fixed in the Dockerfile by compiling code BEFORE assets:
```dockerfile
# Correct order:
COPY lib lib
RUN mix compile          # ← Generates phoenix-colocated hooks
COPY assets assets
RUN mix assets.deploy    # ← Can now import phoenix-colocated
```

### Issue: Health Check Failing

**Symptoms**: Container marked as "unhealthy"

**Solution**:
```bash
# Check if curl is installed in container
docker-compose exec app which curl

# Manually test health endpoint
docker-compose exec app curl http://localhost:4000/

# View health check logs
docker inspect whoknows_app | grep -A 10 Health
```

---

## Production Considerations

### Security Hardening

1. **Change Default Credentials**
   ```bash
   # Update .env
   GRAFANA_PASSWORD=<strong-password>
   ```

2. **Use Strong SECRET_KEY_BASE**
   ```bash
   # Generate new secret
   openssl rand -base64 48
   ```

3. **Don't Expose Internal Ports**
   ```yaml
   # In docker-compose.yml, remove:
   - "9568:9568"  # Only Prometheus needs this internally
   ```

4. **Enable HTTPS**
   - Use a reverse proxy (nginx, Traefik, Caddy)
   - Terminate SSL at the proxy level

### Scaling

For production with multiple instances:

```yaml
services:
  app:
    deploy:
      replicas: 3  # Run 3 app instances
    # Use PostgreSQL instead of SQLite
    environment:
      - DATABASE_URL=postgres://...
```

### Backup Strategy

```bash
# Automated daily backups
0 2 * * * docker-compose exec app cp /app/priv/repo/prod.db /tmp/backup-$(date +\%Y\%m\%d).db

# Backup volumes
docker run --rm -v whoknows_elixir_monolith_app_data:/data -v $(pwd):/backup alpine tar czf /backup/db-backup.tar.gz /data
```

### Monitoring & Alerts

Set up Grafana alerts for:
- High error rate (>1%)
- Slow response time (>500ms p95)
- High memory usage (>80%)
- Database connection errors

---

## File Structure Overview

```
whoknows_elixir_monolith/
├── Dockerfile                    # Multi-stage build definition
├── docker-compose.yml            # Orchestration configuration
├── .dockerignore                 # Files to exclude from build
├── .env                          # Environment variables (SECRET_KEY_BASE, etc.)
├── .env.example                  # Template for .env
├── DOCKER_README.md              # This file
│
├── lib/
│   └── whoknows_elixir_monolith/
│       └── release.ex            # Migration & seeding functions
│
├── priv/repo/
│   ├── migrations/               # Database schema changes
│   └── seeds.exs                 # Initial data (51 pages + 1 user)
│
├── grafana/
│   ├── dashboards/
│   │   └── whoknows_dashboard.json
│   └── provisioning/
│       ├── dashboards/
│       └── datasources/
│
├── prometheus.yml                # Prometheus scrape config
│
├── dump_pages.py                 # Export whoknows.db → JSON
├── generate_seeds.py             # Convert JSON → seeds.exs
├── pages_data.json               # Exported page data (980KB)
└── whoknows.db                   # Original database (not in Docker)
```

---

## Summary

You now have a fully Dockerized Phoenix application with:

✅ **Multi-stage optimized build** (200MB final image)
✅ **Automatic database migrations** on startup
✅ **51 Wikipedia pages** seeded automatically
✅ **1 admin user** ready to login
✅ **Prometheus metrics** collection
✅ **Grafana dashboards** for monitoring
✅ **Persistent data** via Docker volumes
✅ **Health checks** for reliability
✅ **Python scripts** to regenerate seed data

**Next Steps**:
1. Access http://localhost:4000 and login with `keamonk@stud.kea.dk` / `AdminPassword123!`
2. Explore Grafana dashboards at http://localhost:3000
3. Query Prometheus metrics at http://localhost:9090

For questions or issues, check the [Troubleshooting](#troubleshooting) section above.
