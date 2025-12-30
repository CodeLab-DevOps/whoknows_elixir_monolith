import { Page, Locator } from '@playwright/test';

/**
 * Page Object Model for the Home Page
 * This encapsulates the home page elements and actions for better test maintainability
 */
export class HomePage {
  readonly page: Page;
  readonly searchInput: Locator;
  readonly searchButton: Locator;
  readonly loginLink: Locator;
  readonly registerLink: Locator;

  constructor(page: Page) {
    this.page = page;
    this.searchInput = page.locator('#search-input');
    this.searchButton = page.locator('#search-button');
    this.loginLink = page.locator('#nav-login');
    this.registerLink = page.locator('#nav-register');
  }

  async goto() {
    await this.page.goto('/');
  }

  async search(query: string) {
    await this.searchInput.fill(query);
    await this.searchButton.click();
  }

  async goToLogin() {
    await this.loginLink.click();
    await this.page.waitForURL(/\/login/);
  }

  async goToRegister() {
    await this.registerLink.click();
    await this.page.waitForURL(/\/register/);
  }
}
