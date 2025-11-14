defmodule WhoknowsElixirMonolith.BetterStackLogger do
  @moduledoc """
  Logger handler that sends logs to BetterStack via HTTP.
  """

  require Logger

  def attach(token, host) do
    config = %{
      token: token,
      host: host
    }

    :logger.add_handler(__MODULE__, __MODULE__, config)
  end

  # Logger handler callback
  def log(log_event, config) do
    %{
      level: level,
      msg: {msg_format, args},
      meta: _meta
    } = log_event

    message = try do
      :io_lib.format(msg_format, args) |> to_string()
    rescue
      _ -> msg_format |> to_string()
    end

    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    payload = %{
      "dt" => timestamp,
      "level" => level |> to_string(),
      "message" => message,
      "source" => "elixir-app"
    }

    send_to_betterstack(payload, config)
  end

  defp send_to_betterstack(payload, %{token: token, host: host}) do
    url = "https://#{host}"
    _headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(payload)

    Task.start(fn ->
      try do
        :httpc.request(:post, {String.to_charlist(url), [], ~c"application/json", body}, [], [])
      rescue
        e -> Logger.debug("BetterStack log send failed: #{inspect(e)}")
      end
    end)
  end
end
