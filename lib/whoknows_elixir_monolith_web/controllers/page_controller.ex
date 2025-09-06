defmodule WhoknowsElixirMonolithWeb.PageController do
  use WhoknowsElixirMonolithWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
