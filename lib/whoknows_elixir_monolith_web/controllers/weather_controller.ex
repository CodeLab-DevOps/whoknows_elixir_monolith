defmodule WhoknowsElixirMonolithWeb.WeatherController do
  use WhoknowsElixirMonolithWeb, :controller

  def weather(conn, _params) do
    render(conn, :weather)
  end
end
