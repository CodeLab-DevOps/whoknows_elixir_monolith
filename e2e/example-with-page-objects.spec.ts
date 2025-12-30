import { test, expect } from '@playwright/test';
import { HomePage } from './pages/HomePage';
import { LoginPage } from './pages/LoginPage';

/**
 * Example test file demonstrating the use of Page Object Models
 * This is a best practice for organizing and maintaining E2E tests
 */

test.describe('Example with Page Objects', () => {
  test('should navigate using page objects', async ({ page }) => {
    const homePage = new HomePage(page);

    await homePage.goto();

    // Verify we're on the home page
    await expect(homePage.searchInput).toBeVisible();
    await expect(homePage.searchButton).toBeVisible();
  });

  test('should perform search using page object', async ({ page }) => {
    const homePage = new HomePage(page);

    await homePage.goto();
    await homePage.search('elixir phoenix');

    // Verify search was executed
    await expect(page).toHaveURL(/\//);
  });

  test('should navigate to login page using page object', async ({ page }) => {
    const homePage = new HomePage(page);
    const loginPage = new LoginPage(page);

    await homePage.goto();
    await homePage.goToLogin();

    // Verify we're on the login page
    await expect(page).toHaveURL(/\/login/);
    await expect(loginPage.emailInput).toBeVisible();
    await expect(loginPage.passwordInput).toBeVisible();
  });

  test('should show page object pattern for login', async ({ page }) => {
    const loginPage = new LoginPage(page);

    await loginPage.goto();
    await loginPage.loginWithInvalidCredentials('test@example.com', 'wrongpassword');

    // Verify login form is still visible (login failed)
    await expect(loginPage.emailInput).toBeVisible();
  });
});
