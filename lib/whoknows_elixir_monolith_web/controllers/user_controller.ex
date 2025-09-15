defmodule WhoknowsElixirMonolithWeb.UserController do
    use WhoknowsElixirMonolithWeb, :controller


    def register(conn, _params) do
      render(conn, :register )
    end
end
