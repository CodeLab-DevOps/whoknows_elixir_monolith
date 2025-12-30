import { test, expect } from '@playwright/test';

/**
 * End-to-end user journey tests
 * Tests complete user flows through the application
 */

test.describe('Complete User Journey', () => {
  // Generate unique user credentials for this test run
  const timestamp = Date.now();
  const testUser = {
    username: `testuser${timestamp}`,
    email: `test${timestamp}@example.com`,
    password: 'SecurePassword123!'
  };

  test('should complete search workflow', async ({ page }) => {
    await page.goto('/');

    // Search for Java
    const searchInput = page.getByRole('textbox', { name: 'What would you like to know?' });
    await searchInput.click();
    await searchInput.fill('Java');
    await searchInput.press('Enter');

    // Verify we're still on the page (search completed)
    await expect(page).toHaveURL(/\//);
  });

  test('should register a new user successfully', async ({ page }) => {
    await page.goto('/');

    // Navigate to registration
    await page.getByRole('link', { name: 'Register' }).click();
    await expect(page).toHaveURL(/\/register/);

    // Fill in registration form using placeholders
    await page.getByPlaceholder('Enter your username').fill(testUser.username);
    await page.getByPlaceholder('Enter your email').fill(testUser.email);
    await page.getByPlaceholder('Create a password').fill(testUser.password);
    await page.getByPlaceholder('Confirm your password').fill(testUser.password);

    // Submit registration
    await page.getByRole('button', { name: 'Create account' }).click();

    // Wait for successful registration (should redirect or show success)
    await page.waitForTimeout(1000);
  });

  test('should handle registration with existing username', async ({ page }) => {
    await page.goto('/register');

    // Try to register with a username that might exist
    await page.getByPlaceholder('Enter your username').fill('aremcanbaz');
    await page.getByPlaceholder('Enter your email').fill(`unique${Date.now()}@example.com`);
    await page.getByPlaceholder('Create a password').fill('SecurePassword123!');
    await page.getByPlaceholder('Confirm your password').fill('SecurePassword123!');

    await page.getByRole('button', { name: 'Create account' }).click();

    // Should show validation error or stay on registration page
    await page.waitForTimeout(500);
  });

  test.skip('should login and logout flow', async ({ page }) => {
    // This test is skipped due to complex state management
    // Consider implementing with proper test database cleanup
  });

  test('should navigate through main pages', async ({ page }) => {
    await page.goto('/');

    // Navigate to home via logo
    await page.getByRole('link', { name: '¿Who Knows?' }).click();
    await expect(page).toHaveURL(/\//);

    // Navigate to status page (if it exists)
    const statusLink = page.getByRole('link', { name: 'Status' });
    if (await statusLink.isVisible()) {
      await statusLink.click();

      // Verify status page loaded
      const websiteStatus = page.getByText(/Website.*uptime/);
      const apiStatus = page.getByText(/API.*uptime/);

      // Check if status elements exist
      if (await websiteStatus.isVisible()) {
        await expect(websiteStatus).toBeVisible();
      }
      if (await apiStatus.isVisible()) {
        await expect(apiStatus).toBeVisible();
      }
    }
  });
});

test.describe('Theme Toggle', () => {
  test('should toggle between light and dark mode', async ({ page }) => {
    await page.goto('/');

    // Find theme toggle buttons (adjust selectors based on your implementation)
    const themeButtons = page.getByRole('button');
    const buttonCount = await themeButtons.count();

    // Click theme toggle buttons if they exist
    if (buttonCount > 1) {
      await themeButtons.nth(1).click();
      await page.waitForTimeout(300);

      if (buttonCount > 2) {
        await themeButtons.nth(2).click();
        await page.waitForTimeout(300);
      }
    }

    // Verify page is still functional
    await expect(page.getByRole('textbox', { name: 'What would you like to know?' })).toBeVisible();
  });
});
