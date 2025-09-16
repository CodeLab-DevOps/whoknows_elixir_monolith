defmodule WhoknowsElixirMonolithWeb.UserJSON do
  # Called by render(conn, :p_register, %{payload: params})
  def p_register(%{payload: payload}) do
    %{
      ok: true,
      payload: payload
    }
  end
end
