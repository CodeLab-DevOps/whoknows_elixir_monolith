defmodule WhoknowsElixirMonolithWeb.UserJSON do
  def p_register(%{errors: changeset}) do
    %{
      ok: false,
      errors: translate_errors(changeset)
    }
  end

  def p_login(%{error: error}) do
    %{
      ok: false,
      error: error
    }
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  defp translate_error({msg, opts}) do
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end
