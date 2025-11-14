defmodule WhoknowsElixirMonolith.BetterStackLogger do
  @moduledoc """
  Logger handler that sends logs to BetterStack via HTTP.
  """

  require Logger
  require Kernel

  def attach(token, host) do
    handler_config = %{
      "token" => token,
      "host" => host
    }

    :logger.add_handler(__MODULE__, __MODULE__, handler_config)
    :ok
  end

  # Logger handler callback - this is called by the Erlang logger
  def log(log_event, handler_config) do
    try do
      %{
        level: level,
        msg: msg,
        meta: _meta
      } = log_event

      message = format_message(msg)

      timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

      payload = %{
        "dt" => timestamp,
        "level" => level |> to_string(),
        "message" => message,
        "source" => "elixir-app"
      }

      token = handler_config["token"]
      host = handler_config["host"]
      send_to_betterstack(payload, token, host)
    rescue
      _e -> :ok
    end
  end

  defp format_message({:string, str}), do: to_string(str)
  defp format_message({msg_format, args}) when is_list(args) do
    try do
      :io_lib.format(msg_format, args) |> to_string()
    rescue
      _ -> to_string(msg_format)
    end
  end
  defp format_message(msg), do: to_string(msg)

  defp send_to_betterstack(payload, token, host) do
    url = "https://#{host}/v1/logs"
    auth_header = "Bearer #{token}"
    headers = [
      {~c"authorization", String.to_charlist(auth_header)},
      {~c"content-type", ~c"application/json"}
    ]

    body = Jason.encode!(payload)

    Task.start(fn ->
      try do
        :httpc.request(:post, {String.to_charlist(url), headers, ~c"application/json", body}, [], [])
      rescue
        _e -> :ok
      end
    end)
  end
end
