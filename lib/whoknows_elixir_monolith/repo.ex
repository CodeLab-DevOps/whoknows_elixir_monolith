defmodule WhoknowsElixirMonolith.Repo do
  use Ecto.Repo,
    otp_app: :whoknows_elixir_monolith,
    adapter: Ecto.Adapters.Postgres
end
