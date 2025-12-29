@echo off
REM Setup script for E2E testing environment (Windows)
REM This script prepares the test database and ensures all dependencies are ready

echo Setting up E2E testing environment...

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Node.js is not installed. Please install Node.js first.
    exit /b 1
)

REM Check if Mix is installed
where mix >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Elixir/Mix is not installed. Please install Elixir first.
    exit /b 1
)

REM Install Node dependencies
echo Installing Node.js dependencies...
call npm install
if %ERRORLEVEL% neq 0 (
    echo Error installing Node dependencies
    exit /b 1
)

REM Install Playwright browsers
echo Installing Playwright browsers...
call npx playwright install
if %ERRORLEVEL% neq 0 (
    echo Error installing Playwright browsers
    exit /b 1
)

REM Install Elixir dependencies
echo Installing Elixir dependencies...
call mix deps.get
if %ERRORLEVEL% neq 0 (
    echo Error installing Elixir dependencies
    exit /b 1
)

REM Setup test database
echo Setting up test database...
set MIX_ENV=test
call mix ecto.setup
if %ERRORLEVEL% neq 0 (
    echo Error setting up test database
    exit /b 1
)

echo.
echo E2E testing environment setup complete!
echo.
echo You can now run tests with:
echo   npm test          - Run all tests
echo   npm run test:ui   - Run tests in UI mode
echo   npm run test:headed  - Run tests with visible browser
