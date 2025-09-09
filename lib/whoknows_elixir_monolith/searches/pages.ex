defmodule WhoknowsElixirMonolith.Searches.Pages do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pages" do
    field :title, :string
    field :url, :string
    field :language, :string
    field :last_updated, :utc_datetime
    field :content, :string

    timestamps()
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:title, :content, :url, :language, :last_updated])
    |> validate_required([:title, :content, :url, :language, :last_updated])
  end

end
