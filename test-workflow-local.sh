#!/bin/bash
# Local workflow testing script using act

echo "Testing CI/CD workflow locally with act..."
echo ""
echo "Note: Only lint and unit-test will work locally."
echo "Docker build/push requires GitHub environment."
echo ""

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo "❌ Error: act is not installed"
    echo "Install it from: https://github.com/nektos/act"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

echo "✅ Prerequisites OK"
echo ""
echo "Running lint job..."
act -j lint --secret-file .secrets

echo ""
echo "Running unit-test job..."
act -j unit-test --secret-file .secrets

echo ""
echo "✅ Local testing complete!"
echo ""
echo "To test the full pipeline (including Docker build):"
echo "  git checkout -b test-ci"
echo "  git push origin test-ci"
echo "  Then check: https://github.com/CodeLab-DevOps/whoknows_elixir_monolith/actions"
