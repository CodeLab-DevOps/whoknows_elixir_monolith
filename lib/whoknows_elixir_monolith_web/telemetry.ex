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
      ),

      # Business Metrics - User Analytics
      last_value("whoknows.users.count",
        event_name: [:whoknows, :users],
        measurement: :count,
        description: "Total number of users in the system"
      ),
      counter("whoknows.user.registration",
        event_name: [:whoknows, :user, :registration],
        measurement: :count,
        description: "New user registration counter"
      ),
      counter("whoknows.user.login",
        event_name: [:whoknows, :user, :login],
        measurement: :count,
        tags: [:status],
        description: "User login attempts (success/failure)"
      ),

      # Business Metrics - Content
      last_value("whoknows.pages.count",
        event_name: [:whoknows, :pages],
        measurement: :count,
        description: "Total number of pages in the system"
      ),
      last_value("whoknows.pages.by_language",
        event_name: [:whoknows, :pages, :by_language],
        measurement: :count,
        tags: [:language],
        description: "Number of pages by language"
      ),

      # Business Metrics - Search Analytics
      counter("whoknows.search.query.count",
        event_name: [:whoknows, :search, :query],
        measurement: :count,
        tags: [:language, :query, :has_results],
        description: "Search query counter by language and search term"
      ),
      summary("whoknows.search.results",
        event_name: [:whoknows, :search, :query],
        measurement: :results,
        tags: [:language],
        description: "Number of results returned per search"
      ),
      counter("whoknows.search.no_results",
        event_name: [:whoknows, :search, :no_results],
        measurement: :count,
        tags: [:language, :query],
        description: "Searches that returned zero results"
      )
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      {__MODULE__, :emit_user_count, []},
      {__MODULE__, :emit_page_count, []},
      {__MODULE__, :emit_pages_by_language, []}
    ]
  end

  def emit_user_count do
    count = WhoknowsElixirMonolith.Repo.aggregate(WhoknowsElixirMonolith.User, :count)
    :telemetry.execute([:whoknows, :users], %{count: count}, %{})
  end

  def emit_page_count do
    count = WhoknowsElixirMonolith.Repo.aggregate(WhoknowsElixirMonolith.Page, :count)
    :telemetry.execute([:whoknows, :pages], %{count: count}, %{})
  end

  def emit_pages_by_language do
    import Ecto.Query

    WhoknowsElixirMonolith.Repo.all(
      from p in WhoknowsElixirMonolith.Page,
      group_by: p.language,
      select: {p.language, count(p.id)}
    )
    |> Enum.each(fn {language, count} ->
      :telemetry.execute([:whoknows, :pages, :by_language], %{count: count}, %{language: language})
    end)
  end
end
