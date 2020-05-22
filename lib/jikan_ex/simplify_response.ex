defmodule JikanEx.SimplifyResponse do
  @moduledoc false

  @keep_http_values [:headers, :status, :url, :body]

  # remove unnecessary items from Mix.Env responses
  def simplify(http_response) do
    http_response
    |> flatten_response()
  end

  defp flatten_response({:ok, env}), do: {:ok, flatten_env(env)}
  defp flatten_response({:error, err}) when is_map(err), do: {:error, flatten_env(err)}
  # some atom value, e.g. :errconnrefused
  defp flatten_response({:error, err}), do: {:error, err}

  # ignore the method, opts, query, module and client
  # prepend the headers, url and status with http_, move the nested items
  # from the body to the top level of the map
  defp flatten_env(env) do
    {body, resp} =
      Map.take(env, @keep_http_values)
      |> Enum.map(fn {k, v} -> {"http_#{Atom.to_string(k)}", v} end)
      |> Enum.into(%{})
      |> Map.pop("http_body", %{})

    Map.merge(resp, body)
  end
end
