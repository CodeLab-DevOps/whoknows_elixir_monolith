import { test, expect } from '@playwright/test';

test.describe('Home Page', () => {
  test('should load the home page successfully', async ({ page }) => {
    await page.goto('/');

    // Check that the page loaded
    await expect(page).toHaveTitle(/Who Knows/i);

    // Check for the main search input
    const searchInput = page.locator('#search-input');
    await expect(searchInput).toBeVisible();

    // Check for the search button
    const searchButton = page.locator('#search-button');
    await expect(searchButton).toBeVisible();
  });

  test('should have navigation links', async ({ page }) => {
    await page.goto('/');

    // Check for navigation elements
    const loginLink = page.locator('#nav-login');
    await expect(loginLink).toBeVisible();

    const registerLink = page.locator('#nav-register');
    await expect(registerLink).toBeVisible();
  });

  test('should display search interface', async ({ page }) => {
    await page.goto('/');

    // Check that the search placeholder is present
    const searchInput = page.getByPlaceholder('What would you like to know?');
    await expect(searchInput).toBeVisible();
  });
});
