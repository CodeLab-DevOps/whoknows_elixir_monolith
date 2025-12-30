@echo off
echo Killing any existing Elixir processes...
tasklist | findstr "beam.smp" >nul
if %errorlevel% == 0 (
    for /f "tokens=2" %%a in ('tasklist ^| findstr "beam.smp"') do taskkill /PID %%a /F >nul 2>&1
    timeout /t 2 /nobreak >nul
)

echo Starting Phoenix server...
start cmd /c "mix phx.server"

timeout /t 10 /nobreak
echo.
echo Checking metrics endpoint...
powershell -Command "try { $r = Invoke-WebRequest -Uri http://localhost:9568/metrics -UseBasicParsing; Write-Host 'Metrics endpoint is WORKING!' -ForegroundColor Green; Write-Host ''; Write-Host 'Sample metrics:'; $r.Content.Split([Environment]::NewLine)[0..10] | ForEach-Object { Write-Host $_ } } catch { Write-Host 'Metrics endpoint is NOT accessible' -ForegroundColor Red; Write-Host $_.Exception.Message }"

echo.
echo Checking main app...
powershell -Command "try { Invoke-WebRequest -Uri http://localhost:4000 -UseBasicParsing | Out-Null; Write-Host 'Phoenix app is running on http://localhost:4000' -ForegroundColor Green } catch { Write-Host 'Phoenix app is NOT accessible' -ForegroundColor Red }"

echo.
echo.
echo ============================================================
echo Next steps:
echo 1. Start Prometheus and Grafana: docker-compose -f docker-compose.monitoring.yml up -d
echo 2. Open Grafana: http://localhost:3000 (admin/admin)
echo 3. Check Prometheus: http://localhost:9090
echo 4. View metrics: http://localhost:9568/metrics
echo ============================================================
pause
