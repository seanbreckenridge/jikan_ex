defmodule JikanEx do
  @moduledoc """
  A thin elixir wrapper for the Jikan API. Start by creating a `JikanEx.client/1`, which is then passed to each request (see `JikanEx.Request`).

  You can set the base url to use in your application configuration:

  ```
  # config/config.exs
  import Config

  config :jikan_ex,
    base_url: "http://localhost:8000/v3/"
  ```

  If you're [self-hosting](https://github.com/jikan-me/jikan-rest) an instance of Jikan and have issue connecting to the server, start it so that its accessible from any machine, like:

  `php -S 0.0.0.0:25639 -t public`

  ## Quickstart

  ```
  alias JikanEx.Request
  client = JikanEx.client()
  response = client |> Request.anime!(1)
  IO.puts response["title"]  # Prints 'Cowboy Bebop'
  ```

  """

  # options are included to make this extensible
  # and for the future of Jikan, since JWT will
  # be implemented

  @doc """
  Creates a new Jikan client. Attempts to get the base url from your application config. If that doesn't exist, uses the remote `api.jikan.moe` endpoint.


  You can optionally pass a keyword list with options instead.

  Returns `Tesla.Client`

  ## Examples

      iex> JikanEx.client()
      %Tesla.Client{
        adapter: nil,
        fun: nil,
        post: [],
        pre: [{Tesla.Middleware.BaseUrl, :call, ["https://api.jikan.moe/v3/"]}]
      }
      iex> Application.put_env(:jikan_ex, :base_url, "http://localhost:8000/v3/")
      iex> JikanEx.client()
      %Tesla.Client{
        adapter: nil,
        fun: nil,
        post: [],
        pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:8000/v3/"]}]
      }
      iex> Application.delete_env(:jikan_ex, :base_url)
      iex> JikanEx.client([base_url: "http://localhost:8000/v3/"])
      %Tesla.Client{
        adapter: nil,
        fun: nil,
        post: [],
        pre: [{Tesla.Middleware.BaseUrl, :call, ["http://localhost:8000/v3/"]}]
      }

  """
  @spec client(List.t()) :: Telsa.Client.t()
  def client(options \\ []) when is_list(options) do
    # if user passed base url
    options
    |> passed_or_get_env(:base_url)
    |> JikanEx.Base.new()
  end

  defp passed_or_get_env(opts, atom) do
    # if user passed value manually, use that
    if Keyword.has_key?(opts, atom) do
      opts
    else
      env_value = Application.get_env(:jikan_ex, atom)
      # if application config has the atom, use that
      # else don't add the atom
      if env_value != nil do
        Keyword.put(opts, atom, env_value)
      else
        opts
      end
    end
  end
end
