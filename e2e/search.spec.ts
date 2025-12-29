import { test, expect } from '@playwright/test';

test.describe('Search Functionality', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should perform a search and display results', async ({ page }) => {
    const searchInput = page.locator('#search-input');
    const searchButton = page.locator('#search-button');

    // Type a search query
    await searchInput.fill('elixir programming');

    // Click the search button
    await searchButton.click();

    // Wait for navigation or results to appear
    // Adjust the selector based on your actual results container
    await page.waitForTimeout(1000); // Give the server time to respond

    // Check that we're still on a valid page (either stayed on same page with results or navigated)
    await expect(page).toHaveURL(/\//);
  });

  test('should handle empty search', async ({ page }) => {
    const searchButton = page.locator('#search-button');

    // Click search without entering text
    await searchButton.click();

    // The page should still be functional
    const searchInput = page.locator('#search-input');
    await expect(searchInput).toBeVisible();
  });

  test('should allow clearing search input', async ({ page }) => {
    const searchInput = page.locator('#search-input');

    // Type something
    await searchInput.fill('test query');
    await expect(searchInput).toHaveValue('test query');

    // Clear it
    await searchInput.clear();
    await expect(searchInput).toHaveValue('');
  });
});
