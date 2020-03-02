defmodule JikanEx.Request do
  @moduledoc """
  Wrapper functions for the corresponding endpoints.

  Each function (other than `JikanEx.Request.request/3` and `JikanEx.Request.request!/3`):
    * accepts:
      * the client as the first argument
      * zero or more required arguments as additional individual arguments
      * an additional list of URL parts
      * (optional) a map of GET parameters
      * (optional) a keyword list of `JikanEx.Request.option`
    * has a corresponding bang function. Functions without a bang return `{:ok, resp}` or `{:error, resp}`, and raise `Tesla.Error` (inherited from `Tesla`) when a connection couldn't be made, when there was a `Tesla.Adapter` error, or when there was a error decoding the response body. Bang functions raise errors on unsuccessful status codes.

  Though functions for each request exist, they're just wrappers for a couple function calls from `JikanEx.Url`:

  ```
  # for example, building:
  # https://api.jikan.moe/v3/user/nekomata1037/animelist/completed/2?year=2019
  alias JikanEx.Request
  import JikanEx.Url

  client = JikanEx.client()

  # Using JikanEx.Url calls
  response = "user/nekomata1037/"
  |> paths([:animelist, :completed, 2])
  |> params(:year, 2019)
  |> Request.request!(client)

  # same as...
  response = Request.user!(client, "nekomata1037", [:animelist, :all, 2], %{year: 2019})
  ```

  The response from each function is a map, which includes all the keys which Jikan returned. Additionally, it includes `http_headers`, `http_url` and `http_status`.

  A good minority of the Jikan requests don't allow you to pass extra URL parts or GET parameters, but every wrapper function here allows to you to pass a list of paths and a map as optional arguments. This keeps the interface the same for all similar functions.

  Using Jikans [ETag cache validation](https://jikan.docs.apiary.io/#introduction/json-error-response):

  ```
  alias JikanEx.Request

  client = JikanEx.client()

  response = Request.anime!(client, 1)
  etag = %Tesla.Env{headers: response["http_headers"]} |> Tesla.get_header("etag")

  # request using Tesla directly
  new_response = Tesla.get!(response["http_url"], [headers: [{"If-None-Match", etag}]])
  304 = new_response.status
  ```
  """

  alias JikanEx.{Base, Url, SimplifyResponse, UrlBuilders}

  @type option ::
          {:headers, Tesla.Env.headers()}
          | {:opts, Tesla.Env.opts()}

  @type http_response :: map()
  @type response ::
          http_response()
          | {:ok, http_response()}
          | {:error, http_response()}

  # helper functions for bang functions
  defp raise_on_status({:ok, response}), do: response
  defp raise_on_status({:error, response}), do: raise(JikanEx.Exception, response)

  @doc """
  The base request function for the client - all requests eventually call this. Pass a url (`String`) and a `JikanEx.client/1`

  Returns `{:ok, response}` on success and `{:error, response}` on error, where `response` is a `Map`

  ## Example
      iex> case JikanEx.Request.request("anime/1", client) do
      ...>   {:ok, response}
      ...>     -> response["title"]
      ...>   {:error, response}
      ...>     -> response["message"]
      ...> end
      "Cowboy Bebop"
  """
  @spec request(JikanEx.Url.url(), Tesla.Client.t(), [option]) :: response()
  def request(url, client, opts \\ []) do
    Base.get(client, url |> Url.trim_url() |> URI.encode(), opts)
    |> SimplifyResponse.simplify()
  end

  @doc """
  Same as `request/3`, but returns the response directly. Raises `JikanEx.Exception` on errors.
      iex> JikanEx.Request.request!("anime/1", client) |> Map.get("title")
      "Cowboy Bebop: Tengoku no Tobira"
  """
  @spec request!(JikanEx.Url.url(), Tesla.Client.t(), [option]) :: response()
  def request!(url, client, opts \\ []), do: request(url, client, opts) |> raise_on_status()

  @doc """
  Wrapper for the `/anime/` endpoint.
  """
  @spec anime(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def anime(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `anime/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.anime!(client, 26165)
      iex> response["title"]
      "Yuri Kuma Arashi"
      iex> response = JikanEx.Request.anime!(client, 11061, [:episodes, 2])
      iex> response["http_url"]
      "https://api.jikan.moe/v3/anime/11061/episodes/2"

  """
  @spec anime!(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def anime!(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/manga/` endpoint. Same interface as `anime/5`
  """
  @spec manga(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def manga(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `manga/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.manga!(client, 1, [:characters_staff])
      iex> response["characters"] |> List.first() |> Map.get("name")
      "Liebert, Anna"
  """
  @spec manga!(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def manga!(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/person/` endpoint. Same interface as `anime/5`
  """
  @spec person(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def person(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `person/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.person!(client, 40135)
      iex> response["url"]
      "https://myanimelist.net/people/40135/Rapparu"
  """
  @spec person!(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def person!(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/character/` endpoint. Same interface as `anime/5`
  """
  @spec character(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def character(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `character/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.character!(client, 16)
      iex> response["name"]
      "Edward Wong Hau Pepelu Tivrusky IV"
  """
  @spec character!(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def character!(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/producer/` endpoint. Same interface as `anime/5`
  """
  @spec producer(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def producer(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `producer/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.producer!(client, 2)
      iex> response["meta"]["name"]
      "Kyoto Animation"
  """
  @spec producer!(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def producer!(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/magazine/` endpoint. Same interface as `anime/5`
  """
  @spec magazine(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def magazine(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `magazine/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.magazine!(client, 21)
      iex> response["meta"]["name"]
      "Hana to Yume"
  """
  @spec magazine!(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def magazine!(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/club/` endpoint. Same interface as `anime/5`
  """
  @spec club(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def club(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `club/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.club!(client, 72940)
      iex> response["title"]
      "Minna no Uta"
  """
  @spec club!(
          Tesla.Client.t(),
          pos_integer(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def club!(client, id, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, id, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/season/`, `/season/archive/` and `/season/later/` endpoints.
  """
  @spec season(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def season(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `season/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.season!(client, [2020, :winter])
      iex> response["http_url"]
      "https://api.jikan.moe/v3/season/2020/winter"
      iex> response = JikanEx.Request.season!(client, [:later])
      iex> response["http_url"]
      "https://api.jikan.moe/v3/season/later"
  """
  @spec season!(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def season!(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/schedule/` endpoint
  """
  @spec schedule(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def schedule(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `schedule/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.schedule!(client, [:monday])
      iex> response["http_url"]
      "https://api.jikan.moe/v3/schedule/monday
  """
  @spec schedule!(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def schedule!(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/top/` endpoint.
  """
  @spec top(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def top(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `top/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.top!(client, [:anime, 1, :airing])
      iex> response["http_url"]
      "https://api.jikan.moe/v3/top/anime/1/airing"
  """
  @spec top!(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def top!(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/genre/` endpoint.
  """
  @spec genre(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def genre(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `genre/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      # first number is the genre ID on MAL, second number is the page
      iex> response = JikanEx.Request.genre!(client, [:anime, 8, 2])
      iex> response["http_url"]
      "https://api.jikan.moe/v3/genre/anime/8/2"
  """
  @spec genre!(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def genre!(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/meta/` endpoint.
  """
  @spec meta(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def meta(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `meta/5` but returns the response directly. Raises `JikanEx.Exception` on errors.


  ## Example
      iex> response = JikanEx.Request.meta!(client, [:requests, :anime, :today])
      iex> response["http_url"]
      "https://api.jikan.moe/v3/meta/requests/anime/today"
  """
  @spec meta!(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def meta!(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/search/` endpoint.

  """
  @spec search(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def search(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `search/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Example
      iex> response = JikanEx.Request.search!(client, [:anime], %{:q => "Rakugo Shinjuu", :page => 1})
      iex> response["results"] |> List.first() |> Map.get("title")
      "Shouwa Genroku Rakugo Shinjuu"
  """
  @spec search!(
          Tesla.Client.t(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def search!(client, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, paths, parameters)
    |> request!(client, opts)
  end

  @doc """
  Wrapper for the `/user/` endpoint.
  """
  @spec user(
          Tesla.Client.t(),
          JikanEx.Url.path(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def user(client, username, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, [username | paths], parameters)
    |> request(client, opts)
  end

  @doc """
  Same as `user/5` but returns the response directly. Raises `JikanEx.Exception` on errors.

  ## Examples
      iex> response = JikanEx.Request.user!(client, :xinil, [:animelist, :all, 2], %{year: 2019})
      iex> response["http_url"]
      "https://api.jikan.moe/v3/user/xinil/animelist/all/2?year=2019&"
      iex> response = JikanEx.Request.user!(client, :xinil)  # request profile
      iex> response["joined"]
      "2004-11-05T00:00:00+00:00"
      iex> response = JikanEx.Request.user!(client, :xinil, [:friends, 2])
      iex> response["http_url"]
      "https://api.jikan.moe/v3/user/xinil/friends/2"
  """
  @spec user!(
          Tesla.Client.t(),
          JikanEx.Url.path(),
          [JikanEx.Url.url()],
          JikanEx.Url.parameters(),
          [option]
        ) :: response()
  def user!(client, username, paths \\ [], parameters \\ %{}, opts \\ []) do
    UrlBuilders.build_url(__ENV__.function, [username | paths], parameters)
    |> request!(client, opts)
  end
end
