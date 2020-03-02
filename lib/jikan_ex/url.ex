defmodule JikanEx.Url do
  @moduledoc """
  Interface to build Jikan URLs. These are then passed onto `JikanEx.Request.request/3`.

  In here, generally, URLs shouldn't start with a slash, and should typically have a slash at the end. The final / is removed when adding query parameters or in `JikanEx.Request.request/3`.
  """

  @type url :: String.t()
  @type path :: String.t() | atom()

  @type parameter_key :: String.t() | atom()
  @type parameter_val :: String.t() | integer()
  @type parameters :: %{optional(parameter_key) => parameter_val} | %{}

  @doc """
  Add the endpoint (a string or atom) to the URL

  ## Example

      iex> JikanEx.Url.path("anime/5/", "videos")
      "anime/5/videos/"
  """
  @spec path(url(), path()) :: url()
  def path(prev_url, endpoint) do
    prev_url <> convert_to_string(endpoint) <> "/"
  end

  @doc """
  Adds multiple URL parts (joined by '/') to a URL

  ## Example

      iex> JikanEx.Url.paths("anime/", [1, :character_staff])
      "anime/1/character_staff/"
  """
  @spec paths(url(), [path()]) :: url()
  def paths(prev_url, paths) when is_list(paths) do
    url_parts =
      paths
      |> Enum.map(&convert_to_string(&1))
      |> Enum.join("/")

    prev_url <> url_parts <> "/"
  end

  @doc """
  Add a page number to the URL, calls `JikanEx.Url.path/2`

  ## Example

      iex> JikanEx.Url.page("animelist/all/", 2)
      "animelist/all/2/"
  """
  @spec page(url(), integer()) :: url()
  def page(prev_url, endpoint), do: path(prev_url, endpoint)

  @doc """
  Formats a map of GET params into a URL

  ## Example

      iex> JikanEx.Url.params("animelist/all/2", %{year: 2019, airing_status: "complete"})
      "animelist/all/2?airing_status=complete&year=2019&"
  """
  @spec params(url(), parameters()) :: url()
  def params(prev_url, parameter_map) when is_map(parameter_map) do
    Enum.reduce(parameter_map, prev_url, fn {key, val}, acc -> add_key_val(acc, key, val) end)
  end

  @doc """
  Formats a GET key and value into a URL

  ## Example

      iex> JikanEx.Url.params("animelist/all/2/", "year", 2019)
      "animelist/all/2?year=2019&"
  """
  @spec params(url(), parameter_key(), parameter_val()) :: url()
  def params(prev_url, key, val) do
    add_key_val(prev_url, key, val)
  end

  # adds a key value pair to a URL
  # adds a ? if needed
  defp add_key_val(prev_url, key, val) do
    case prev_url |> String.last() do
      "&" ->
        prev_url
        |> add_key_val_naive(key |> convert_to_string(), val)

      _ ->
        prev_url
        |> trim_url()
        |> Kernel.<>("?")
        |> add_key_val_naive(key |> convert_to_string(), val)
    end
  end

  # assumes the URL already has the correct last character (& or ?)
  defp add_key_val_naive(prev_url, key, val) do
    "#{prev_url}#{key}=#{val}&"
  end

  @doc """
  Removes a trailing forward slash from a URL

      iex> JikanEx.Url.trim_url("username/animelist/2/")
      "username/animelist/2"
      iex> JikanEx.Url.trim_url("username/animelist/2")
      "username/animelist/2"

  """
  @spec trim_url(url()) :: url()
  def trim_url(prev_url) do
    prev_url |> String.trim_trailing("/")
  end

  defp convert_to_string(string) when is_binary(string), do: string
  defp convert_to_string(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp convert_to_string(integer) when is_integer(integer), do: Integer.to_string(integer)
end
