# End-to-End Testing with Playwright

This document explains how to set up and run end-to-end tests for the whoknows_elixir_monolith application using Playwright.

## Overview

Playwright is a powerful end-to-end testing framework that allows you to test your application across multiple browsers (Chromium, Firefox, WebKit). The tests simulate real user interactions with your Phoenix application.

## Prerequisites

- Node.js (v18 or higher recommended)
- npm or yarn package manager
- Elixir and Phoenix installed
- All project dependencies installed (`mix deps.get`)

## Installation

The project already has Playwright configured. If you need to reinstall:

```bash
npm install
npx playwright install
```

## Project Structure

```
e2e/
├── home.spec.ts        # Tests for the home page
├── search.spec.ts      # Tests for search functionality
├── auth.spec.ts        # Tests for authentication (login/register)
└── weather.spec.ts     # Tests for the weather page
```

## Configuration

The Playwright configuration is in [playwright.config.ts](playwright.config.ts). Key settings:

- **Base URL**: `http://localhost:4000`
- **Test directory**: `./e2e`
- **Web Server**: Automatically starts Phoenix server with `mix phx.server`
- **Browsers**: Chromium, Firefox, WebKit, Mobile Chrome, Mobile Safari
- **Retries**: 2 retries on CI, 0 locally
- **Parallel execution**: Enabled for faster test runs

## Running Tests

### Run all tests (headless mode)
```bash
npm test
```

### Run tests with UI mode (interactive)
```bash
npm run test:ui
```

### Run tests in headed mode (see browser)
```bash
npm run test:headed
```

### Debug tests
```bash
npm run test:debug
```

### Run tests in specific browser
```bash
npm run test:chromium
npm run test:firefox
npm run test:webkit
```

### View test report
After tests run, view the HTML report:
```bash
npm run test:report
```

### Generate tests with Codegen
Playwright's codegen tool can help you generate test code:
```bash
npm run test:codegen
```

## Database Setup for E2E Tests

E2E tests use a separate database configuration defined in [config/e2e.exs](config/e2e.exs):

- Database: `priv/repo/e2e.db`
- Server: Running on port 4000
- Environment: `MIX_ENV=test` (set automatically by Playwright)

The Phoenix server will automatically start before tests run and stop after tests complete.

## Test Database Management

### Reset the E2E test database
```bash
MIX_ENV=test mix ecto.reset
```

### Run migrations on E2E database
```bash
MIX_ENV=test mix ecto.migrate
```

## Writing Tests

### Basic Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature Name', () => {
  test('should do something', async ({ page }) => {
    await page.goto('/');

    // Find elements
    const element = page.locator('#element-id');

    // Interact with elements
    await element.click();
    await element.fill('text');

    // Assert expectations
    await expect(element).toBeVisible();
    await expect(page).toHaveURL(/expected-url/);
  });
});
```

### Useful Selectors

The application uses test-friendly IDs:
- `#search-input` - Main search input field
- `#search-button` - Search submit button
- `#nav-login` - Login navigation link
- `#nav-register` - Register navigation link

### Common Patterns

#### Navigate to a page
```typescript
await page.goto('/');
await page.goto('/login');
```

#### Fill a form
```typescript
const emailInput = page.locator('input[name="user[email]"]');
const passwordInput = page.locator('input[name="user[password]"]');

await emailInput.fill('user@example.com');
await passwordInput.fill('password123');
```

#### Click a button
```typescript
const submitButton = page.locator('button[type="submit"]');
await submitButton.click();
```

#### Wait for navigation
```typescript
await page.waitForURL(/\/dashboard/);
```

#### Assert element visibility
```typescript
await expect(element).toBeVisible();
await expect(element).toHaveText('Expected text');
await expect(element).toHaveAttribute('placeholder', 'Expected value');
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'

      - name: Install Elixir dependencies
        run: mix deps.get

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Node dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps

      - name: Setup database
        run: MIX_ENV=test mix ecto.setup

      - name: Run Playwright tests
        run: npm test

      - name: Upload test report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: playwright-report/
```

## Debugging Tips

### 1. Use UI Mode
UI mode provides a visual interface to debug tests:
```bash
npm run test:ui
```

### 2. Use Debug Mode
Step through tests line by line:
```bash
npm run test:debug
```

### 3. Screenshots and Videos
Failed tests automatically capture:
- Screenshots: `test-results/*/test-failed-*.png`
- Videos: `test-results/*/video.webm`
- Traces: Available in HTML report

### 4. Slow Down Tests
Add a delay to see what's happening:
```typescript
test.use({
  launchOptions: {
    slowMo: 1000 // 1 second delay between actions
  }
});
```

### 5. Check Phoenix Server Logs
If tests fail mysteriously, check the Phoenix server output for errors.

## Troubleshooting

### Tests fail with "Connection refused"
- Ensure Phoenix dependencies are installed: `mix deps.get`
- Ensure database is set up: `MIX_ENV=test mix ecto.setup`
- Check if port 4000 is available

### Tests timeout starting the server
- Increase the timeout in [playwright.config.ts](playwright.config.ts):
  ```typescript
  webServer: {
    timeout: 180 * 1000, // 3 minutes
  }
  ```

### Database errors
- Reset the database: `MIX_ENV=test mix ecto.reset`
- Check that SQLite is installed

### Browser installation issues
- Reinstall browsers: `npx playwright install --with-deps`

## Best Practices

1. **Keep tests independent**: Each test should set up its own data
2. **Use meaningful test names**: Describe what the test does
3. **Test user flows**: Test complete user journeys, not just individual actions
4. **Use page objects**: For complex pages, create reusable page object models
5. **Don't test implementation details**: Test what users see and do
6. **Keep tests fast**: Use parallel execution and avoid unnecessary waits
7. **Clean up test data**: Reset database state between test runs

## Resources

- [Playwright Documentation](https://playwright.dev)
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Phoenix Testing Guide](https://hexdocs.pm/phoenix/testing.html)
- [Ecto SQL Sandbox](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html)

## Support

For issues or questions:
- Check the [Playwright docs](https://playwright.dev)
- Review test output and screenshots in `test-results/`
- Check Phoenix server logs for backend errors
