#!/bin/bash

# Setup script for E2E testing environment
# This script prepares the test database and ensures all dependencies are ready

echo "Setting up E2E testing environment..."

# Check if Elixir is installed
if ! command -v elixir &> /dev/null; then
    echo "Error: Elixir is not installed. Please install Elixir first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Install Node dependencies
echo "Installing Node.js dependencies..."
npm install

# Install Playwright browsers
echo "Installing Playwright browsers..."
npx playwright install

# Install Elixir dependencies
echo "Installing Elixir dependencies..."
mix deps.get

# Setup test database
echo "Setting up test database..."
MIX_ENV=test mix ecto.setup

echo "E2E testing environment setup complete!"
echo ""
echo "You can now run tests with:"
echo "  npm test          # Run all tests"
echo "  npm run test:ui   # Run tests in UI mode"
echo "  npm run test:headed  # Run tests with visible browser"
