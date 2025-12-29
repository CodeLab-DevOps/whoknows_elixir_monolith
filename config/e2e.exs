import Config

# E2E test environment configuration
# This config is for running Playwright end-to-end tests with a live server

# Configure your database
config :whoknows_elixir_monolith, WhoknowsElixirMonolith.Repo,
  database: "priv/repo/e2e#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool_size: 10

# We NEED to run a server for E2E tests
config :whoknows_elixir_monolith, WhoknowsElixirMonolithWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: "VXyEFObT/lNJQ5TWGf4EdPeqEsjrkog6Ji1eCPr2scqYj+DwOzyvnBitSHSDCI5M",
  server: true

# In test we don't send emails
config :whoknows_elixir_monolith, WhoknowsElixirMonolith.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
