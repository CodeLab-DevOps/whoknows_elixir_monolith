defmodule WhoknowsElixirMonolith.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Initialize OpenTelemetry instrumentation
    # This must be done before any web server components start
    :ok = :opentelemetry_cowboy.setup()
    :ok = OpentelemetryPhoenix.setup(adapter: :cowboy2)

    # Start BetterStack logger if token is configured
    betterstack_token = System.get_env("BETTERSTACK_OTLP_TOKEN")
    betterstack_host = System.get_env("BETTERSTACK_OTLP_HOST") || "s1589488.eu-nbg-2.betterstackdata.com"

    if betterstack_token do
      WhoknowsElixirMonolith.BetterStackLogger.attach(betterstack_token, betterstack_host)
    end

    :logger.info(~c"OpenTelemetry instrumentation initialized")

    children = [
      WhoknowsElixirMonolithWeb.Telemetry,
      WhoknowsElixirMonolith.Repo,
      {DNSCluster, query: Application.get_env(:whoknows_elixir_monolith, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WhoknowsElixirMonolith.PubSub},
      # Start a worker by calling: WhoknowsElixirMonolith.Worker.start_link(arg)
      # {WhoknowsElixirMonolith.Worker, arg},
      # Start to serve requests, typically the last entry
      WhoknowsElixirMonolithWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WhoknowsElixirMonolith.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WhoknowsElixirMonolithWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
