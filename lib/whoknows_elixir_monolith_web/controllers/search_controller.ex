defmodule WhoknowsElixirMonolithWeb.SearchController do
  use WhoknowsElixirMonolithWeb, :controller
  alias WhoknowsElixirMonolith.Page
  alias WhoknowsElixirMonolith.Repo
  import Ecto.Query

  def index(conn, params) do
    query = params["q"] || ""
    language = params["language"] || "en"

    search_results =
      if query == "" do
        []
      else
        search_pages(query, language)
      end

    render(conn, :index, search_results: search_results, query: query, language: language)
  end

  defp search_pages(query, language) do
    # SQLite3 doesn't support ilike, so we use like for case-insensitive search
    search_pattern = "%#{String.downcase(query)}%"

    Page
    |> where([p], p.language == ^language)
    |> where([p], like(fragment("LOWER(?)", p.content), ^search_pattern))
    |> Repo.all()
  end
end
