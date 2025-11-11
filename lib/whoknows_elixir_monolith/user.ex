defmodule WhoknowsElixirMonolith.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Bitwise

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_confirmation, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :name, :string
    field :confirmed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation, :name])
    |> validate_email(opts)
    |> validate_confirmation(:password)
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
  changeset
  |> validate_required([:email])
  |> update_change(:email, &String.downcase/1)
  |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
  |> validate_length(:email, max: 160)
  |> maybe_validate_unique_email(opts)
end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end
  


  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Cap at a generous byte limit to avoid DoS on extreme lengths
      |> validate_length(:password, max: 4096, count: :bytes)
      |> put_change(:password_hash, hash_password(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, WhoknowsElixirMonolith.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  @doc """
  A user changeset for updating profile information (email and name).
  Does not require password.
  """
  def profile_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :name])
    |> validate_email(opts)
    |> validate_length(:name, max: 160)
  end

  @spec password_changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @spec password_changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @spec password_changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @spec confirm_changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            }
        ) :: Ecto.Changeset.t()
  @doc """
  Confirms the account by setting confirmed_at to the current time.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%WhoknowsElixirMonolith.User{password_hash: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    try_verify_password(password, password_hash)
  end

  def valid_password?(_, _) do
    try_no_user_verify()
    false
  end

  defp hash_password(password) do
    try_hash_password(password)
  end

  # Secure password hashing using PBKDF2
  @pbkdf2_rounds 100_000
  @salt_length 16

  defp try_verify_password(password, stored_hash) do
    case String.split(stored_hash, "$") do
      ["pbkdf2", rounds_str, salt_b64, hash_b64] ->
        rounds = String.to_integer(rounds_str)
        salt = Base.decode64!(salt_b64)
        stored_hash_binary = Base.decode64!(hash_b64)

        computed_hash = :crypto.pbkdf2_hmac(:sha256, password, salt, rounds, 32)
        crypto_equal?(computed_hash, stored_hash_binary)

      _ ->
        # Invalid hash format
        false
    end
  rescue
    _ -> false
  end

  defp try_hash_password(password) do
    salt = :crypto.strong_rand_bytes(@salt_length)
    hash = :crypto.pbkdf2_hmac(:sha256, password, salt, @pbkdf2_rounds, 32)

    # Format: pbkdf2$rounds$salt_base64$hash_base64
    "pbkdf2$#{@pbkdf2_rounds}$#{Base.encode64(salt)}$#{Base.encode64(hash)}"
  end

  defp try_no_user_verify do
    # Simulate the same computational time as password verification
    dummy_salt = :crypto.strong_rand_bytes(@salt_length)
    :crypto.pbkdf2_hmac(:sha256, "dummy_password", dummy_salt, @pbkdf2_rounds, 32)
    :ok
  end

  # Constant-time comparison to prevent timing attacks
  defp crypto_equal?(a, b) when byte_size(a) == byte_size(b) do
    crypto_equal?(a, b, 0) == 0
  end

  defp crypto_equal?(a, b) when byte_size(a) != byte_size(b), do: false

  defp crypto_equal?(<<a, rest_a::binary>>, <<b, rest_b::binary>>, acc) do
    crypto_equal?(rest_a, rest_b, acc ||| bxor(a, b))
  end

  defp crypto_equal?("", "", acc), do: acc
end
