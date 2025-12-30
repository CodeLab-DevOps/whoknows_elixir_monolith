defmodule WhoknowsElixirMonolithWeb.Api.SearchController do
  use WhoknowsElixirMonolithWeb, :controller
  alias WhoknowsElixirMonolith.Page
  alias WhoknowsElixirMonolith.Repo
  import Ecto.Query

  def search(conn, params) do
    query = params["q"] || ""
    language = params["language"] || "en"

    search_results =
      if query == "" do
        []
      else
        search_pages(query, language)
      end

    json(conn, %{search_results: search_results})
  end

  defp search_pages(query, language) do
    # SQLite3 doesn't support ilike, so we use like for case-insensitive search
    search_pattern = "%#{String.downcase(query)}%"

    Page
    |> where([p], p.language == ^language)
    |> where([p], like(fragment("LOWER(?)", p.content), ^search_pattern))
    |> Repo.all()
    |> Enum.map(&format_page_for_api/1)
  end

  defp format_page_for_api(page) do
    %{
      title: page.title,
      url: page.url,
      language: page.language,
      last_updated: page.last_updated,
      content: page.content
    }
  end
end
