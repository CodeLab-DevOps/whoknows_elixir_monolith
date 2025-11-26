defmodule WhoknowsElixirMonolith.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WhoknowsElixirMonolithWeb.Telemetry,
      WhoknowsElixirMonolith.Repo,
      {DNSCluster, query: Application.get_env(:whoknows_elixir_monolith, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WhoknowsElixirMonolith.PubSub},
      # Prometheus metrics exporter - exposes metrics at :9568/metrics for Prometheus scraping
      {TelemetryMetricsPrometheus,
       [metrics: WhoknowsElixirMonolithWeb.Telemetry.metrics(),
        port: 9568]},
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
