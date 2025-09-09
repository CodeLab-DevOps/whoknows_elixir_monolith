defmodule WhoknowsElixirMonolith.Searches do
  @moduledoc """
  The Searches context. All Searches related functions and business logic
  """
  import Ecto.Query, warn: false
  alias WhoknowsElixirMonolith.Repo
  alias WhoknowsElixirMonolith.Searches.Pages

end

@doc """
Return all searches with optional filter
"""
def list_searches(filters \\ %{}) do
  Pages
  |> apply_filters(filters)
  |> Repo.all()
end

defp apply_filters(query, filters) do
  Enum.reduce(filters, query, fn
    {:title, title}, query when is_binary(title) ->
      from p in query, where: ilike(p.title, ^"%#{title}%")

    {:language, language}, query when is_binary(language) ->
      from p in query, where: p.language == ^language

    {_key, _value}, query ->
      query  # Ignorer ukendte filtre
  end)
end
