# Monitoring Setup Guide

This document explains the monitoring setup for the WhoKnows Elixir application using Prometheus and Grafana.

## Overview

The monitoring stack consists of:
- **Prometheus**: Collects and stores metrics from the Phoenix application
- **Grafana**: Visualizes metrics in dashboards
- **Telemetry Metrics Prometheus Core**: Elixir library that exposes Phoenix metrics in Prometheus format

## Architecture

```
Phoenix App (:9568/metrics) → Prometheus (:9090) → Grafana (:3000)
```

1. The Phoenix application exposes metrics at `http://localhost:9568/metrics`
2. Prometheus scrapes these metrics every 15 seconds
3. Grafana queries Prometheus to visualize the data in dashboards

## What Metrics Are We Collecting?

According to the assignment requirements, we need to gather telemetry to understand how users interact with the system. Our metrics focus on:

### User Behavior Metrics
- **HTTP Requests by Method & Status Code**: Track which endpoints users are accessing and success/error rates
- **Route Access Patterns**: See which features are most popular (search, login, register, etc.)
- **Error Rates**: Monitor 4xx and 5xx responses to identify user issues

### System Performance Metrics
- **Database Query Counts & Duration**: Understand database load and query performance
- **VM Memory Usage**: Monitor application memory consumption
- **Run Queue Lengths**: Detect performance bottlenecks

### Why These Metrics?

These metrics help answer critical questions:
- Which features are users actually using?
- Are users encountering errors?
- Is the system performing well under load?
- Where are the bottlenecks?

This aligns with the assignment goal of "gathering telemetry from users" to understand system usage and identify improvement opportunities.

## Quick Start

### 1. Start the Phoenix Application

```bash
mix phx.server
```

The application will:
- Run on `http://localhost:4000`
- Expose Prometheus metrics at `http://localhost:9568/metrics`

### 2. Start Prometheus and Grafana

```bash
docker-compose -f docker-compose.monitoring.yml up -d
```

This starts:
- **Prometheus** at `http://localhost:9090`
- **Grafana** at `http://localhost:3000`

### 3. Access Grafana

1. Open `http://localhost:3000` in your browser
2. Login with:
   - Username: `admin`
   - Password: `admin`
3. Navigate to "Dashboards" → "WhoKnows Application Metrics"

### 4. Generate Some Traffic

To see metrics populate, generate some traffic:

```bash
# Make requests to your application
curl http://localhost:4000
curl http://localhost:4000/api/search?q=test
curl http://localhost:4000/api/register -X POST -H "Content-Type: application/json" -d "{}"
```

## Dashboard Panels

The pre-configured dashboard includes:

1. **HTTP Requests by Status Code**: Shows request rate broken down by HTTP status (200, 404, etc.) and method (GET, POST)
2. **Total Requests by Endpoint**: Displays which routes are being accessed most frequently
3. **Database Queries per Second**: Monitors database query rate
4. **Total Database Query Time**: Tracks database performance
5. **VM Memory Usage**: Shows application memory consumption
6. **VM Run Queue Lengths**: Indicates CPU and IO queue lengths
7. **Error Rate (4xx/5xx)**: Highlights error responses to identify issues

## Files Structure

```
.
├── docker-compose.monitoring.yml    # Docker Compose for Prometheus & Grafana
├── prometheus.yml                   # Prometheus scrape configuration
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml      # Auto-configure Prometheus datasource
│   │   └── dashboards/
│   │       └── default.yml         # Auto-load dashboards
│   └── dashboards/
│       └── whoknows_dashboard.json # Pre-built dashboard
├── lib/
│   ├── whoknows_elixir_monolith/
│   │   └── application.ex          # Prometheus exporter setup
│   └── whoknows_elixir_monolith_web/
│       └── telemetry.ex            # Metric definitions
└── mix.exs                         # Dependencies
```

## Viewing Raw Metrics

### Check Prometheus Metrics Endpoint

```bash
curl http://localhost:9568/metrics
```

Example output:
```
# TYPE phoenix_endpoint_stop_duration_count counter
phoenix_endpoint_stop_duration_count{method="GET",status="200"} 42
phoenix_endpoint_stop_duration_count{method="GET",status="404"} 3

# TYPE phoenix_router_dispatch_stop_duration_count counter
phoenix_router_dispatch_stop_duration_count{route="/api/search",method="GET"} 15
phoenix_router_dispatch_stop_duration_count{route="/api/login",method="POST"} 8

# TYPE vm_memory_total gauge
vm_memory_total 45678
```

### Query Prometheus Directly

Visit `http://localhost:9090` and try these queries:

- `rate(phoenix_endpoint_stop_duration_count[5m])` - Request rate over 5 minutes
- `phoenix_router_dispatch_stop_duration_count` - Total requests per route
- `vm_memory_total` - Current memory usage

## Customizing Metrics

### Adding New Metrics

Edit [lib/whoknows_elixir_monolith_web/telemetry.ex](lib/whoknows_elixir_monolith_web/telemetry.ex):

```elixir
def metrics do
  [
    # ... existing metrics ...

    # Add your custom metric
    counter("my_app.custom_event.count",
      tags: [:type],
      description: "Count of custom events"
    )
  ]
end
```

Then emit the event in your code:

```elixir
:telemetry.execute([:my_app, :custom_event, :count], %{count: 1}, %{type: "registration"})
```

### Supported Metric Types

The Prometheus Core library supports:
- `counter`: Monotonically increasing counter
- `sum`: Sum of values
- `last_value`: Most recent value (gauge)

Note: `summary` and `distribution` are not supported by `telemetry_metrics_prometheus_core`.

## Troubleshooting

### Metrics Not Showing in Grafana

1. Check if Phoenix app is running: `curl http://localhost:9568/metrics`
2. Check if Prometheus is scraping: Visit `http://localhost:9090/targets`
3. Verify Prometheus can reach the app: Look for "UP" status

### "No Data" in Grafana Panels

1. Generate traffic to create metrics
2. Check time range in Grafana (top right)
3. Verify queries in Prometheus first

### Prometheus Can't Reach Phoenix App

On Windows, ensure `host.docker.internal` resolves. If not, update [prometheus.yml](prometheus.yml) to use your machine's IP address instead:

```yaml
scrape_configs:
  - job_name: 'phoenix_app'
    static_configs:
      - targets: ['192.168.x.x:9568']  # Use your IP
```

## Assignment Requirements Checklist

- [x] **Monitoring implemented**: Prometheus + Grafana stack is configured
- [x] **Metrics defined**: HTTP requests, routes, database queries, VM stats
- [x] **User behavior tracking**: Request patterns, endpoint usage, error rates
- [x] **Dashboard created**: Pre-configured Grafana dashboard
- [x] **Documentation**: This README explains the setup and metric choices

### Metrics Discussion Points (For Exam)

When explaining your metric choices:

1. **Request Counters by Status**: Helps identify if users are encountering errors (404s, 500s)
2. **Route Access Patterns**: Shows which features users actually use (search vs register vs login)
3. **Database Metrics**: Indicates if queries are slow or if we're hitting the database too much
4. **VM Memory**: Helps detect memory leaks or high memory usage patterns
5. **Error Rates**: Critical for identifying when users are having problems

These metrics directly support the assignment goal: understanding system usage and identifying improvement opportunities.

## Stopping the Monitoring Stack

```bash
docker-compose -f docker-compose.monitoring.yml down
```

To also remove data:

```bash
docker-compose -f docker-compose.monitoring.yml down -v
```

## Taking Screenshots

As mentioned in the assignment, take screenshots of your dashboards during development since data will be cleared before exams:

1. Run the application and generate traffic
2. Open Grafana dashboard
3. Take screenshots showing:
   - HTTP request patterns
   - Popular routes
   - Error rates
   - System metrics

## Next Steps

1. **Generate More Traffic**: Use load testing tools like `wrk` or `hey` to simulate users
2. **Set Up Alerts**: Configure Grafana alerts for high error rates or memory usage
3. **Add Custom Metrics**: Track business-specific events (successful logins, searches, etc.)
4. **Export Dashboards**: Save dashboard JSON for version control

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Telemetry Metrics](https://hexdocs.pm/telemetry_metrics/)
- [Telemetry Metrics Prometheus Core](https://hexdocs.pm/telemetry_metrics_prometheus_core/)
