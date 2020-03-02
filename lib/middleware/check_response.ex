defmodule JikanEx.Middleware.CheckResponse do
  @moduledoc false
  @behaviour Tesla.Middleware

  # checks the HTTP response and returns :error on errors
  def call(env, next, _options) do
    resp = Tesla.run(env, next)

    case resp do
      {:ok, %{status: status}} = resp when status < 300 ->
        # already has {:ok, resp}
        resp

      {_, err_resp} ->
        {:error, err_resp}
    end
  end
end
