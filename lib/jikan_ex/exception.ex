defmodule JikanEx.Exception do
  @moduledoc """
  Defines the API Error class. It has two fields, a `message` and `response`. `message` is the error message from the Jikan response, and the response is the Response map from `JikanEx.Request`
  """
  defexception [:message, :response]

  @default_error "An Unexpected error occurred"

  @doc """
  Error raised by bang functions in `JikanEx.Request`
  """
  def exception(resp_error) when is_map(resp_error) do
    msg =
      unless Map.has_key?(resp_error, "http_status") do
        @default_error
      else
        resp_error["message"] || resp_error["error"] || "Unknown API error"
      end

    %__MODULE__{
      message: ~s(HTTP Error #{resp_error["http_status"]}: #{msg}),
      response: resp_error
    }
  end
end
