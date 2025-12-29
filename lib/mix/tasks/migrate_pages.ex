defmodule Mix.Tasks.MigratePages do
  use Mix.Task

  @shortdoc "Migrates pages from old database to current database"

  def run(_args) do
    Mix.Task.run("app.start")

    # Update this path
    old_db_path = "whoknows.db"

    IO.puts("Starting pages migration from #{old_db_path}")

    # Connect to old database
    {:ok, old_conn} = Exqlite.Sqlite3.open(old_db_path)

    # Get all pages from old database
    {:ok, statement} =
      Exqlite.Sqlite3.prepare(
        old_conn,
        "SELECT title, url, language, last_updated, content FROM pages"
      )

    page_rows = collect_all_rows(old_conn, statement)

    IO.puts("Found #{length(page_rows)} pages to migrate")

    # Insert into new database
    {migrated_count, error_count} =
      page_rows
      |> Enum.with_index(1)
      |> Enum.reduce({0, 0}, fn {[title, url, language, last_updated, content], index},
                                {migrated, errors} ->
        parsed_timestamp = parse_timestamp(last_updated)

        page_attrs = %{
          title: title,
          url: url,
          language: language,
          last_updated: parsed_timestamp,
          content: content
        }

        changeset =
          WhoknowsElixirMonolith.Page.changeset(%WhoknowsElixirMonolith.Page{}, page_attrs)

        case WhoknowsElixirMonolith.Repo.insert(changeset) do
          {:ok, _page} ->
            if rem(index, 10) == 0 do
              IO.puts("Migrated #{index} pages...")
            end

            {migrated + 1, errors}

          {:error, changeset} ->
            IO.puts("Failed to migrate page #{url}: #{inspect(changeset.errors)}")
            {migrated, errors + 1}
        end
      end)

    IO.puts("Migration complete!")
    IO.puts("Successfully migrated: #{migrated_count} pages")
    IO.puts("Errors: #{error_count} pages")

    # Close connections
    Exqlite.Sqlite3.close(old_conn)
  end

  defp collect_all_rows(conn, statement, acc \\ []) do
    case Exqlite.Sqlite3.step(conn, statement) do
      {:row, row} ->
        collect_all_rows(conn, statement, [row | acc])

      {:done} ->
        Enum.reverse(acc)

      other ->
        IO.puts("Unexpected result: #{inspect(other)}")
        Enum.reverse(acc)
    end
  end

  defp parse_timestamp(nil), do: nil
  defp parse_timestamp(""), do: nil

  defp parse_timestamp(timestamp_str) when is_binary(timestamp_str) do
    case DateTime.from_iso8601(timestamp_str <> "Z") do
      {:ok, dt, _} ->
        dt

      {:error, _} ->
        # Try parsing without timezone
        case NaiveDateTime.from_iso8601(timestamp_str) do
          {:ok, ndt} -> DateTime.from_naive!(ndt, "Etc/UTC")
          {:error, _} -> nil
        end
    end
  end

  defp parse_timestamp(_), do: nil
end
