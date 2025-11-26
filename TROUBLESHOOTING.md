# Monitoring Troubleshooting Guide

## Issue: Prometheus Not Collecting Data

### Step 1: Verify Phoenix App is Running

```bash
# Check if Phoenix is running
curl http://localhost:4000

# OR in PowerShell
Invoke-WebRequest -Uri http://localhost:4000 -UseBasicParsing
```

**Expected**: Should return your app's HTML

### Step 2: Verify Metrics Endpoint Works

```bash
# Check metrics endpoint directly
curl http://localhost:9568/metrics

# OR in PowerShell
Invoke-WebRequest -Uri http://localhost:9568/metrics -UseBasicParsing
```

**Expected**: Should return Prometheus-format metrics like:
```
# TYPE phoenix_endpoint_stop_duration_count counter
phoenix_endpoint_stop_duration_count{method="GET",status="200"} 5
```

**If metrics endpoint doesn't work:**
- Check Phoenix server logs for errors
- Look for warning about duplicate metric names
- Make sure `TelemetryMetricsPrometheus.Core` is in supervision tree

### Step 3: Verify Prometheus Can Reach the App

1. Check Prometheus targets at: `http://localhost:9090/targets`

2. You should see `phoenix_app` endpoint listed

3. **Status should be "UP"** (green)

**If status is "DOWN" (red):**

#### Fix A: Use Your Machine's IP Instead of host.docker.internal

1. Find your IP address:
```bash
ipconfig
# Look for IPv4 Address under your network adapter
```

2. Edit [prometheus.yml](prometheus.yml) and replace `host.docker.internal` with your IP:
```yaml
scrape_configs:
  - job_name: 'phoenix_app'
    static_configs:
      - targets: ['192.168.x.x:9568']  # <-- Use your IP
```

3. Restart Prometheus:
```bash
docker-compose -f docker-compose.monitoring.yml restart prometheus
```

#### Fix B: Run Phoenix Inside Docker Network

If host networking doesn't work, you could run Phoenix in the same Docker network:

1. Add to [docker-compose.monitoring.yml](docker-compose.monitoring.yml):
```yaml
services:
  phoenix:
    image: elixir:1.15
    working_dir: /app
    volumes:
      - .:/app
    command: mix phx.server
    ports:
      - "4000:4000"
      - "9568:9568"
    networks:
      - monitoring
```

2. Update [prometheus.yml](prometheus.yml):
```yaml
scrape_configs:
  - job_name: 'phoenix_app'
    static_configs:
      - targets: ['phoenix:9568']
```

### Step 4: Check Grafana Data Source

1. Open Grafana: `http://localhost:3000`
2. Go to: Configuration → Data Sources → Prometheus
3. Click "Test" button
4. Should say "Data source is working"

**If test fails:**
- Verify Prometheus container is running: `docker ps`
- Check Prometheus logs: `docker logs prometheus`

### Step 5: Generate Traffic to Create Metrics

Metrics only exist after events occur. Generate some traffic:

```bash
# Make several requests
for /L %i in (1,1,10) do curl http://localhost:4000
for /L %i in (1,1,10) do curl http://localhost:4000/api/search?q=test
```

Then check metrics endpoint again - you should see counters increment.

### Step 6: Verify Metrics Appear in Prometheus

1. Open Prometheus: `http://localhost:9090`
2. Go to "Graph" tab
3. Try these queries:
   - `phoenix_endpoint_stop_duration_count`
   - `vm_memory_total`
4. Click "Execute"

**If no data appears:**
- Go back to `http://localhost:9090/targets` and verify target is UP
- Check that metrics endpoint is actually returning data
- Verify scrape_interval in prometheus.yml (default: 15s)

### Step 7: Check Grafana Dashboard

1. Open Grafana: `http://localhost:3000`
2. Go to Dashboards → WhoKnows Application Metrics
3. Set time range to "Last 5 minutes"
4. Generate traffic to your app

**If panels show "No Data":**
- Verify Prometheus has data (step 6)
- Check panel queries match your metric names
- Ensure correct time range is selected

## Common Issues

### Issue: Port 4000 Already in Use

```bash
# Kill existing Elixir processes
tasklist | findstr "beam"
taskkill /PID <PID> /F
```

### Issue: Duplicate Metric Warning

```
[warning] Metric name already exists. Dropping measure.
```

**Solution**: Remove duplicate metric definitions in [lib/whoknows_elixir_monolith_web/telemetry.ex](lib/whoknows_elixir_monolith_web/telemetry.ex)

### Issue: Docker Containers Not Starting

```bash
# Check container status
docker ps -a

# View logs
docker logs prometheus
docker logs grafana

# Restart containers
docker-compose -f docker-compose.monitoring.yml restart
```

### Issue: Grafana Dashboard Not Loading

The dashboard is auto-provisioned. If it doesn't appear:

1. Check [grafana/provisioning/dashboards/default.yml](grafana/provisioning/dashboards/default.yml) exists
2. Check [grafana/dashboards/whoknows_dashboard.json](grafana/dashboards/whoknows_dashboard.json) exists
3. Restart Grafana:
```bash
docker-compose -f docker-compose.monitoring.yml restart grafana
```

## Quick Test Script

Run [start_monitoring.bat](start_monitoring.bat) which:
- Kills existing Phoenix processes
- Starts Phoenix server
- Tests metrics endpoint
- Shows next steps

## Still Having Issues?

### Debug Checklist:

- [ ] Phoenix app is running (`http://localhost:4000` works)
- [ ] Metrics endpoint works (`http://localhost:9568/metrics` returns data)
- [ ] Prometheus container is running (`docker ps` shows it)
- [ ] Prometheus target is UP (`http://localhost:9090/targets`)
- [ ] Grafana can connect to Prometheus (test data source)
- [ ] Generated traffic to create metrics
- [ ] Checked time range in Grafana (last 5-15 minutes)

### Verify Complete Setup:

```powershell
# All-in-one verification script
Write-Host "1. Checking Phoenix app..." -ForegroundColor Yellow
try { Invoke-WebRequest -Uri http://localhost:4000 -UseBasicParsing | Out-Null; Write-Host "   ✓ Phoenix OK" -ForegroundColor Green } catch { Write-Host "   ✗ Phoenix FAIL" -ForegroundColor Red }

Write-Host "2. Checking metrics endpoint..." -ForegroundColor Yellow
try { Invoke-WebRequest -Uri http://localhost:9568/metrics -UseBasicParsing | Out-Null; Write-Host "   ✓ Metrics OK" -ForegroundColor Green } catch { Write-Host "   ✗ Metrics FAIL" -ForegroundColor Red }

Write-Host "3. Checking Prometheus..." -ForegroundColor Yellow
try { Invoke-WebRequest -Uri http://localhost:9090 -UseBasicParsing | Out-Null; Write-Host "   ✓ Prometheus OK" -ForegroundColor Green } catch { Write-Host "   ✗ Prometheus FAIL" -ForegroundColor Red }

Write-Host "4. Checking Grafana..." -ForegroundColor Yellow
try { Invoke-WebRequest -Uri http://localhost:3000 -UseBasicParsing | Out-Null; Write-Host "   ✓ Grafana OK" -ForegroundColor Green } catch { Write-Host "   ✗ Grafana FAIL" -ForegroundColor Red }
```

## Alternative: Use Windows IP Instead of Docker Network

If `host.docker.internal` doesn't work:

1. Get your IP: `ipconfig` → Look for "IPv4 Address"
2. Update [prometheus.yml](prometheus.yml):
   ```yaml
   targets: ['YOUR_IP_HERE:9568']
   ```
3. Restart: `docker-compose -f docker-compose.monitoring.yml restart prometheus`
