defmodule WhoknowsElixirMonolithWeb.UserController do
    use WhoknowsElixirMonolithWeb, :controller


    def register(conn, _params) do
      render(conn, :register )
    end

    # POST /api/register
 # POST /api/register
  def p_register(conn, params) do
    render(conn, :p_register, %{payload: params})
    # Alternative if you want to skip the JSON view module:
    # json(conn, %{ok: true, payload: params})
  end
end
