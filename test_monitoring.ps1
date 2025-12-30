# Test Monitoring Setup

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Monitoring Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Phoenix App
Write-Host "1. Testing Phoenix App (http://localhost:4000)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:4000" -UseBasicParsing -TimeoutSec 5
    Write-Host "   OK Phoenix is running!" -ForegroundColor Green
} catch {
    Write-Host "   FAIL Phoenix is NOT running" -ForegroundColor Red
    Write-Host "   Run: mix phx.server" -ForegroundColor Yellow
}

# Test 2: Metrics Endpoint
Write-Host "`n2. Testing Metrics Endpoint (http://localhost:9568/metrics)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9568/metrics" -UseBasicParsing -TimeoutSec 5
    Write-Host "   OK Metrics endpoint is working!" -ForegroundColor Green
    Write-Host "`n   Sample metrics:" -ForegroundColor Cyan
    $lines = $response.Content -split "`n"
    $lines[0..10] | ForEach-Object { Write-Host "   $_" }
} catch {
    Write-Host "   FAIL Metrics endpoint is NOT accessible" -ForegroundColor Red
    Write-Host "   Check that Phoenix is running" -ForegroundColor Yellow
}

# Test 3: Prometheus
Write-Host "`n3. Testing Prometheus (http://localhost:9090)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9090" -UseBasicParsing -TimeoutSec 5
    Write-Host "   OK Prometheus is running!" -ForegroundColor Green
} catch {
    Write-Host "   FAIL Prometheus is NOT running" -ForegroundColor Red
    Write-Host "   Run: docker-compose -f docker-compose.monitoring.yml up -d" -ForegroundColor Yellow
}

# Test 4: Prometheus Targets
Write-Host "`n4. Checking Prometheus Targets..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9090/api/v1/targets" -UseBasicParsing -TimeoutSec 5
    $json = $response.Content | ConvertFrom-Json
    $active = $json.data.activeTargets

    if ($active.Count -gt 0) {
        foreach ($target in $active) {
            $health = $target.health
            $scrapeUrl = $target.scrapeUrl
            if ($health -eq "up") {
                Write-Host "   OK Target UP: $scrapeUrl" -ForegroundColor Green
            } else {
                Write-Host "   FAIL Target DOWN: $scrapeUrl" -ForegroundColor Red
                Write-Host "        Last Error: $($target.lastError)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "   WARNING No targets configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   FAIL Could not check targets" -ForegroundColor Red
}

# Test 5: Grafana
Write-Host "`n5. Testing Grafana (http://localhost:3000)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    Write-Host "   OK Grafana is running!" -ForegroundColor Green
} catch {
    Write-Host "   FAIL Grafana is NOT running" -ForegroundColor Red
    Write-Host "   Run: docker-compose -f docker-compose.monitoring.yml up -d" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Open Grafana: http://localhost:3000 (admin/admin)" -ForegroundColor White
Write-Host "2. Go to Dashboards -> WhoKnows Application Metrics" -ForegroundColor White
Write-Host "3. Generate traffic: curl http://localhost:4000" -ForegroundColor White
Write-Host "4. Check Prometheus targets: http://localhost:9090/targets" -ForegroundColor White
Write-Host ""
