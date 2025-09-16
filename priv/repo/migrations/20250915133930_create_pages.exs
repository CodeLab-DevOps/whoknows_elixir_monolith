defmodule WhoknowsElixirMonolith.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages, primary_key: false) do
      add :title, :string
      add :url, :string, null: false
      add :language, :string, null: false
      add :last_updated, :utc_datetime
      add :content, :text, null: false

      timestamps()
    end

    create unique_index(:pages, [:url])
    create index(:pages, [:language])
    create index(:pages, [:title])
  end
end
