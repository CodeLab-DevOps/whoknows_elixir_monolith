import { test, expect } from '@playwright/test';

/**
 * Monitoring tools tests
 * Tests for Grafana and Prometheus integration
 * Note: These tests assume monitoring tools are running separately
 */

test.describe('Grafana Dashboard', () => {
  test.skip('should login to Grafana', async ({ page }) => {
    // Skip by default as Grafana runs on a different port
    // Enable this test when running full stack with docker-compose

    await page.goto('http://localhost:3000/login');

    // Login to Grafana
    await page.getByTestId('data-testid Username input field').click();
    await page.getByTestId('data-testid Username input field').fill('admin');

    await page.getByTestId('data-testid Password input field').click();
    await page.getByTestId('data-testid Password input field').fill('admin');

    await page.getByTestId('data-testid Login button').click();

    // Wait for potential password change prompt
    await page.waitForTimeout(1000);

    // Check if password change is required
    const newPasswordField = page.getByRole('textbox', { name: 'New password', exact: true });
    if (await newPasswordField.isVisible()) {
      await newPasswordField.fill('SecurePassword123!');

      const confirmPasswordField = page.getByRole('textbox', { name: 'Confirm new password' });
      await confirmPasswordField.click();
      await confirmPasswordField.fill('SecurePassword123!');

      await page.getByRole('button', { name: 'Submit' }).click();
    }

    // Verify successful login
    await page.waitForTimeout(1000);
    // Add assertions based on Grafana's post-login page
  });
});

test.describe('Prometheus Metrics', () => {
  test.skip('should access Prometheus query interface', async ({ page }) => {
    // Skip by default as Prometheus runs on a different port
    // Enable this test when running full stack with docker-compose

    await page.goto('http://localhost:9090/query');

    // Navigate to Alerts
    const alertsLink = page.getByRole('banner').getByRole('link', { name: 'Alerts' });
    await alertsLink.click();

    // Verify alerts page loaded
    await page.waitForTimeout(500);

    // Add appropriate assertions for Prometheus UI
  });

  test.skip('should interact with Prometheus UI elements', async ({ page }) => {
    // Skip by default
    await page.goto('http://localhost:9090/query');

    // Interact with Prometheus UI elements
    // Note: These selectors are auto-generated and might be fragile
    const targetElement = page.locator('#mantine-onxcev7gm-target');

    if (await targetElement.isVisible()) {
      await targetElement.click();
      await page.waitForTimeout(300);
      await targetElement.click();
    }

    // Add meaningful assertions
  });
});
