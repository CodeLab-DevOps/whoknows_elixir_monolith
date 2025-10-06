defmodule WhoknowsElixirMonolithWeb.SafeURL do
  @moduledoc """
  Helper module to sanitize URLs and prevent XSS attacks through javascript: and data: URL schemes.
  Only allows http and https URLs.
  """

  @allowed ~w(http https)

  @doc """
  Sanitizes a URL by validating its scheme and host.
  Returns the URL if it has an allowed scheme (http/https) and a valid host.
  Returns "#" for any invalid, nil, or unsafe URLs.

  ## Examples

      iex> WhoknowsElixirMonolithWeb.SafeURL.sanitize("https://example.com")
      "https://example.com"

      iex> WhoknowsElixirMonolithWeb.SafeURL.sanitize("javascript:alert('xss')")
      "#"

      iex> WhoknowsElixirMonolithWeb.SafeURL.sanitize(nil)
      "#"
  """
  def sanitize(nil), do: "#"

  def sanitize(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} = uri when scheme in @allowed and is_binary(host) ->
        URI.to_string(uri)

      _ ->
        "#"
    end
  end

  def sanitize(_), do: "#"
end
