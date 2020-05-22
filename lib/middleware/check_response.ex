defmodule JikanEx.Middleware.CheckResponse do
  @moduledoc false
  @behaviour Tesla.Middleware

  # sanity check to make sure respose is parsed
  # despite Tesla.Middleware.JSON encoding/decoding
  # the request, if the content-type doesnt match
  # application/json, it wont do anything. When
  # self-hosting on 0.0.0.0:8000 (like I recommend),
  # the Content-Type can be 'text/html; charset=UTF-8'
  # This just checks to make  sure the content is decoded,
  # and throws an returns an error if it cant be.
  defp parse_json({:ok, resp}) do
    case resp do
      # if body is still a string
      %{body: body} = resp when is_bitstring(body) ->
        # parse using Jason
        case Jason.decode(body) do
          {:ok, parsed_json} ->
            {:ok, %{resp | body: parsed_json}}

          {:error, err} ->
            {:error, err}
        end

      # is already parsed
      _ ->
        {:ok, resp}
    end
  end

  # checks the HTTP response and returns :error on errors
  def call(env, next, _options) do
    resp = Tesla.run(env, next)

    case resp do
      {:ok, %{status: status}} = resp when status < 400 ->
        # already has {:ok, resp}
        parse_json(resp)

      {_, err_resp} ->
        {:error, err_resp}
    end
  end
end
