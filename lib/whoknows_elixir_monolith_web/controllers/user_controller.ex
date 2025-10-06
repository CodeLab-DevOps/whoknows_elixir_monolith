defmodule WhoknowsElixirMonolithWeb.UserController do
  use WhoknowsElixirMonolithWeb, :controller

  alias WhoknowsElixirMonolith.Accounts
  alias WhoknowsElixirMonolith.User

  def register(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/")
    else
      changeset = Accounts.change_user(%User{})
      render(conn, :register, changeset: changeset)
    end
  end

  def login(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/")
    else
      render(conn, :login)
    end
  end
end
