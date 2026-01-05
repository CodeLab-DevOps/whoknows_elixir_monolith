defmodule WhoknowsElixirMonolithWeb.Plugs.RequestLogger do
  @moduledoc """
  Custom plug to log request bodies for debugging.
  Logs the full request body for POST requests to help with debugging.
  """

  require Logger
  alias Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    # Only log POST requests with JSON content
    if conn.method == "POST" and String.contains?(conn.request_path, "/api/") do
      # Read the body
      {:ok, body, conn} = Conn.read_body(conn)

      # Log it
      Logger.info("""
      [REQUEST LOGGER] POST #{conn.request_path}
      Headers: #{inspect(conn.req_headers)}
      Body: #{inspect(body)}
      """)

      conn
    else
      conn
    end
  end
end
