defmodule WhoknowsElixirMonolithWeb.PageController do
  use WhoknowsElixirMonolithWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def register(conn, _params) do
    render(conn, :register)
  end
end
