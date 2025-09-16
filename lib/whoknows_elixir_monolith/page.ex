defmodule WhoknowsElixirMonolith.Page do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
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
    |> cast(attrs, [:title, :url, :language, :last_updated, :content])
    |> validate_required([:url, :language, :content])
    |> unique_constraint(:url)
  end
end
