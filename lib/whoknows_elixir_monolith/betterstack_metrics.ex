defmodule WhoknowsElixirMonolith.BetterStackMetrics do
  @moduledoc """
  Metrics exporter that sends metrics to BetterStack.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def init(opts) do
    token = Keyword.fetch!(opts, :token)
    host = Keyword.fetch!(opts, :host)

    config = %{
      token: token,
      host: host
    }

    # Subscribe to telemetry events for basic metrics
    :telemetry.attach_many(
      "betterstack-metrics",
      [
        [:phoenix, :endpoint, :stop],
        [:whoknows_elixir_monolith, :repo, :query]
      ],
      &handle_event/4,
      config
    )

    {:ok, config}
  end

  def handle_event([:phoenix, :endpoint, :stop], measurements, _metadata, config) do
    duration = Map.get(measurements, :duration, 0)

    gauge = %{
      "name" => "http_request_duration",
      "gauge" => %{"value" => duration / 1_000_000},  # Convert to seconds
      "dt" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    send_metric(gauge, config)
  end

  def handle_event([:whoknows_elixir_monolith, :repo, :query], measurements, _metadata, config) do
    query_time = Map.get(measurements, :total_time, 0)

    gauge = %{
      "name" => "db_query_duration",
      "gauge" => %{"value" => query_time / 1_000_000},  # Convert to seconds
      "dt" => DateTime.utc_now() |> DateTime.to_iso8601()
    }

    send_metric(gauge, config)
  end

  def handle_event(_event, _measurements, _metadata, _config), do: :ok

  defp send_metric(payload, %{token: _token, host: host}) do
    url = "https://#{host}/metrics"

    body = Jason.encode!(payload)

    Task.start(fn ->
      try do
        :httpc.request(:post, {String.to_charlist(url), [], ~c"application/json", body}, [], [])
      rescue
        e -> Logger.debug("BetterStack metric send failed: #{inspect(e)}")
      end
    end)
  end
end
