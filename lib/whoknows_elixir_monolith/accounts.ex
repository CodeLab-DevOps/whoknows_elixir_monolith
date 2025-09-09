defmodule WhoknowsElixirMonolith.Accounts do
  import Ecto.Query, warn: false
  alias WhoknowsElixirMonolith.Repo
  alias WhoknowsElixirMonolith.Accounts.User

  def authenticate_user(email, password) do
    user = Repo.get_by(User, email: email)

    if user && valid_password?(user, password) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end

  defp valid_password?(user, password) do
    :crypto.hash(:sha256, password) == user.password_hash
  end

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end
end
