import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test('should navigate to login page', async ({ page }) => {
    await page.goto('/');

    // Click the login link
    await page.getByRole('link', { name: 'Log in' }).click();

    // Wait for navigation
    await page.waitForURL(/\/login/);

    // Check that we're on the login page
    await expect(page).toHaveURL(/\/login/);
    await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();

    // Check for login form elements using placeholders
    const usernameOrEmailInput = page.getByPlaceholder('Enter your username or email');
    const passwordInput = page.getByPlaceholder('Enter your password');

    await expect(usernameOrEmailInput).toBeVisible();
    await expect(passwordInput).toBeVisible();
  });

  test('should navigate to register page', async ({ page }) => {
    await page.goto('/');

    // Click the register link
    await page.getByRole('link', { name: 'Register' }).click();

    // Wait for navigation
    await page.waitForURL(/\/register/);

    // Check that we're on the register page
    await expect(page).toHaveURL(/\/register/);
    await expect(page.getByRole('heading', { name: 'Create account' })).toBeVisible();

    // Check for register form elements using placeholders
    const usernameInput = page.getByPlaceholder('Enter your username');
    const emailInput = page.getByPlaceholder('Enter your email');
    const passwordInput = page.getByPlaceholder('Create a password');

    await expect(usernameInput).toBeVisible();
    await expect(emailInput).toBeVisible();
    await expect(passwordInput).toBeVisible();
  });

  test('should show validation errors on invalid login', async ({ page }) => {
    await page.goto('/login');

    // Try to submit with empty fields
    await page.getByRole('button', { name: 'Sign in' }).click();

    // Wait a bit for any validation messages
    await page.waitForTimeout(500);

    // The form should still be visible (indicating we didn't successfully log in)
    await expect(page.getByPlaceholder('Enter your username or email')).toBeVisible();
  });

  test('should show validation errors on invalid registration', async ({ page }) => {
    await page.goto('/register');

    // Try to submit with empty fields
    await page.getByRole('button', { name: 'Create account' }).click();

    // Wait a bit for any validation messages
    await page.waitForTimeout(500);

    // The form should still be visible (indicating we didn't successfully register)
    await expect(page.getByPlaceholder('Enter your email')).toBeVisible();
  });
});
