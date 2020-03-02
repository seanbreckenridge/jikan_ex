defmodule JikanEx.Base do
  @moduledoc """
  Creates the Tesla client for Jikan. Encodes/Decodes the JSON response. Called from `JikanEx.client/1`
  """

  use Tesla, only: [:get]

  # order matters, since simplifyresponse changes the key names
  plug(JikanEx.Middleware.CheckResponse)
  plug(Tesla.Middleware.FollowRedirects, max_redirects: 3)
  plug(Tesla.Middleware.JSON)

  @defaults [
    base_url: "https://api.jikan.moe/v3/"
  ]

  @doc """
  Creates a JikanEx Client. Takes a keyword list as first argument. If the base_url key is missing, uses the default (api.jikan.moe)

  These client that's returned is passed to each request in `JikanEx.Request`.

  Returns `Tesla.Client`

  ## Examples

      iex> JikanEx.Base.new([])
      iex> JikanEx.Base.new()
      %Tesla.Client{
        adapter: nil,
        fun: nil,
        post: [],
        pre: [
          {Tesla.Middleware.BaseUrl, :call, ["https://api.jikan.moe/v3/"]}
        ]
      }
      iex> JikanEx.Base.new([base_url: "http://localhost:8000/v3/"])
      %Tesla.Client{
        adapter: nil,
        fun: nil,
        post: [],
        pre: [
          {Tesla.Middleware.BaseUrl, :call, ["http://localhost:8000/v3/"]}
        ]
      }

  """

  def new(options \\ []) do
    options = Keyword.merge(@defaults, options) |> Enum.into(%{})

    Tesla.client([
      {Tesla.Middleware.BaseUrl, options.base_url}
    ])
  end

  @doc """
  Get the Base Url from a `Tesla.Client`

  ## Example

      iex> client = JikanEx.client()
      iex> JikanEx.Base.get_base_url(client)
      "https://api.jikan.moe/v3/"
  """
  def get_base_url(client) do
    {Tesla.Middleware.BaseUrl, _, base_urls} =
      client.pre
      |> Enum.find(
        # default value
        {Tesla.Middleware.BaseUrl, nil, ""},
        &(&1 |> Tuple.to_list() |> List.first() == Tesla.Middleware.BaseUrl)
      )

    List.first(base_urls)
  end
end
