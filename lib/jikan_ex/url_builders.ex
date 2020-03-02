defmodule JikanEx.UrlBuilders do
  @moduledoc """
  Creates the URLs for Jikan endpoints. These are called from `JikanEx.Request` and aren't typically used by calling them directly.
  """

  alias JikanEx.Url

  @doc """
  Builds a URL from a list of paths and a param_map

  # Example

      iex> JikanEx.UrlBuilders.build([:user, "nekomata1037", :animelist, :completed, 2], %{year: 2019})
      "user/nekomata1037/animelist/completed/2?year=2019&"
  """
  @spec build(
          [JikanEx.Url.path()],
          JikanEx.Url.parameters()
        ) :: JikanEx.Url.url()
  def build(path_list, param_map \\ %{}) do
    "" |> Url.paths(path_list) |> Url.params(param_map)
  end

  @doc """
  Build a URL from a function name, (MAL) id, paths, parameter map

  Accepts the `__ENV__.function` from the calling function as the first argument (to turn into the first URL part), the MAL ID for the second and additional paths/params as third/fourth

  ## Example

      iex> JikanEx.UrlBuilders.build_url({:anime!, 0}, 1, [:characters_staff], %{})
      "anime/1/characters_staff/"

  """
  @spec build_url(
          tuple(),
          pos_integer(),
          [JikanEx.Url.path()],
          JikanEx.Url.parameters()
        ) :: JikanEx.Url.url()
  def build_url(function_env, id, paths, parameters) do
    {function_atom, _} = function_env

    build(
      [function_atom |> Atom.to_string() |> String.trim_trailing("!"), id | paths],
      parameters
    )
  end

  @doc """
  Similar to `build_url/4` but doesn't accept a MAL ID

  ## Example

      iex> JikanEx.UrlBuilders.build_url({:search!, 0}, [:anime], %{:q => "k-on", "limit" => 5})
      "search/anime?q=k-on&limit=5&"
  """
  @spec build_url(
          tuple(),
          [JikanEx.Url.path()],
          JikanEx.Url.parameters()
        ) :: JikanEx.Url.url()
  def build_url(function_env, paths, parameters) do
    {function_atom, _} = function_env
    build([function_atom |> Atom.to_string() |> String.trim_trailing("!") | paths], parameters)
  end
end
