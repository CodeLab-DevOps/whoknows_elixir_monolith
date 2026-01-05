import { Page, Locator } from '@playwright/test';

/**
 * Page Object Model for the Login Page
 * This encapsulates the login page elements and actions
 */
export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly rememberMeCheckbox: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.getByPlaceholder('Enter your username or email');
    this.passwordInput = page.getByPlaceholder('Enter your password');
    this.submitButton = page.getByRole('button', { name: 'Sign in' });
    this.rememberMeCheckbox = page.locator('input[type="checkbox"]');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string, rememberMe: boolean = false) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);

    if (rememberMe) {
      await this.rememberMeCheckbox.check();
    }

    await this.submitButton.click();
  }

  async loginWithInvalidCredentials(email: string, password: string) {
    await this.login(email, password);
    // Wait a bit for error message to appear
    await this.page.waitForTimeout(500);
  }
}
