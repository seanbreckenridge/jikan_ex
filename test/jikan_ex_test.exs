defmodule JikanExTest do
  use ExUnit.Case, async: false

  doctest JikanEx
  doctest JikanEx.Url
  doctest JikanEx.Base
  doctest JikanEx.UrlBuilders
  # doctest JikanEx.Request
end
