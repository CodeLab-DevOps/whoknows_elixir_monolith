import { test, expect } from '@playwright/test';

test.describe('Weather Page', () => {
  test('should navigate to weather page', async ({ page }) => {
    await page.goto('/');

    // Navigate to weather page directly
    await page.goto('/weather');

    // Check that we're on the weather page
    await expect(page).toHaveURL(/\/weather/);

    // Check that the page loaded successfully
    await expect(page.locator('body')).toBeVisible();
  });

  test('should display weather interface', async ({ page }) => {
    await page.goto('/weather');

    // Wait for the page to load
    await page.waitForLoadState('networkidle');

    // Basic check that the page is responsive
    await expect(page.locator('body')).toBeVisible();
  });
});
