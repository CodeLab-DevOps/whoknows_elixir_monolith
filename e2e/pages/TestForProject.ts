import { test, expect } from '@playwright/test';

/**
 * NOTE: This file has been refactored into separate, focused test files:
 * - ../user-journey.spec.ts - Main user flows (search, register, login)
 * - ../monitoring.spec.ts - Monitoring tools (Grafana, Prometheus)
 *
 * This file is kept for reference but the tests are disabled.
 * Please use the new test files for better organization and maintainability.
 */

test.describe('Original Generated Test (Deprecated)', () => {
  test.skip('original generated test - now split into focused tests', async ({ page }) => {
    // This test has been refactored into:
    // - user-journey.spec.ts for main application flows
    // - monitoring.spec.ts for Grafana and Prometheus tests

    // See those files for the improved, organized version of this test
  });
});

/**
 * Issues with the original test that were fixed:
 *
 * 1. ❌ Single giant test doing too many unrelated things
 *    ✅ Split into focused tests per feature
 *
 * 2. ❌ Hardcoded URLs (http://localhost:4000)
 *    ✅ Uses baseURL from playwright.config.ts
 *
 * 3. ❌ No meaningful test descriptions
 *    ✅ Descriptive test names and documentation
 *
 * 4. ❌ Testing multiple applications in one test
 *    ✅ Separate test files for different services
 *
 * 5. ❌ Redundant clicks and interactions
 *    ✅ Removed unnecessary actions
 *
 * 6. ❌ No assertions - just clicking
 *    ✅ Added proper expect() assertions
 *
 * 7. ❌ Random data without cleanup
 *    ✅ Uses timestamp-based unique data
 *
 * 8. ❌ Fragile auto-generated selectors
 *    ✅ Uses semantic role-based selectors
 *
 * 9. ❌ File in wrong location (pages/ folder)
 *    ✅ Proper test location in e2e/ directory
 */