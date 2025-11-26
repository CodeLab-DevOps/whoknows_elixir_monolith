defmodule WhoknowsElixirMonolithWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix HTTP Request Metrics - for understanding user behavior
      counter("phoenix.endpoint.stop.duration",
        tags: [:method, :status],
        tag_values: fn %{conn: conn} ->
          %{
            method: conn.method,
            status: conn.status
          }
        end,
        description: "HTTP request counter by method and status code"
      ),
      counter("phoenix.router_dispatch.stop.duration",
        tags: [:route, :method],
        tag_values: fn %{conn: conn, route: route} ->
          %{
            route: route,
            method: conn.method
          }
        end,
        description: "Route access counter by endpoint and method"
      ),
      counter("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        description: "Count of exceptions in route handling"
      ),

      # Database Query Metrics
      counter("whoknows_elixir_monolith.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "Database query counter"
      ),

      # VM Metrics
      last_value("vm.memory.total",
        unit: {:byte, :kilobyte},
        description: "Total VM memory"
      ),
      last_value("vm.total_run_queue_lengths.total",
        description: "Total run queue length"
      ),
      last_value("vm.total_run_queue_lengths.cpu",
        description: "CPU run queue length"
      ),
      last_value("vm.total_run_queue_lengths.io",
        description: "IO run queue length"
      )
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {WhoknowsElixirMonolithWeb, :count_users, []}
    ]
  end
end
