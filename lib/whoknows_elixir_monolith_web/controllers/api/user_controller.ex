defmodule WhoknowsElixirMonolithWeb.Api.UserController do
  use WhoknowsElixirMonolithWeb, :controller

  alias WhoknowsElixirMonolith.Accounts

  def register(conn, %{"user" => user_params}) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/")
    else
      case Accounts.create_user(user_params) do
        {:ok, user} ->
          token = Accounts.generate_user_session_token(user)
          conn
          |> put_session(:user_token, token)
          |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
          |> put_status(:ok)
          |> json(%{statusCode: 200, message: "User registered successfully"})

        {:error, %Ecto.Changeset{} = changeset} ->
          errors = format_changeset_errors(changeset)
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{detail: errors})
      end
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      token = Accounts.generate_user_session_token(user)
      conn
      |> put_session(:user_token, token)
      |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
      |> put_status(:ok)
      |> json(%{statusCode: 200, message: "Login successful"})
    else
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{detail: [%{loc: ["password"], msg: "Invalid email or password", type: "value_error"}]})
    end
  end

  def logout(conn, _params) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    conn
    |> clear_session()
    |> json(%{statusCode: 200, message: "Logout successful"})
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {field, messages} ->
      messages
      |> List.wrap()
      |> Enum.map(fn message ->
        %{
          loc: [to_string(field)],
          msg: message,
          type: "value_error"
        }
      end)
    end)
    |> List.flatten()
  end
end