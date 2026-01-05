defmodule WhoknowsElixirMonolithWeb.Plugs.PathNormalizer do
  @moduledoc """
  Plug to normalize paths by removing consecutive slashes.
  Converts //api/login to /api/login
  """

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    # Normalize the path by removing consecutive slashes
    normalized_path = String.replace(conn.request_path, ~r{/+}, "/")

    # Only update if the path changed
    if normalized_path != conn.request_path do
      %{conn | request_path: normalized_path}
    else
      conn
    end
  end
end
