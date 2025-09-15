defmodule WhoknowsElixirMonolithWeb.WeatherController do
  use WhoknowsElixirMonolithWeb, :controller

  def index(conn, _params) do
    conn
    |> put_status(501)
    |> put_view(html: WhoknowsElixirMonolithWeb.ErrorHTML)
    |> render(:"501")
  end
end
