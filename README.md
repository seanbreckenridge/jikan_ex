# JikanEx

A thin elixir wrapper for the [Jikan](https://github.com/jikan-me/jikan) API.

See the [documentation](https://hexdocs.pm/jikan_ex/0.1.0) for usage.

### Quickstart

```elixir
alias JikanEx.Request
client = JikanEx.client()
response = client |> Request.anime!(1)
IO.puts response["title"]  # Prints 'Cowboy Bebop'
```

## Installation

Add the following to your `mix.exs`:

```elixir
def deps do
  [
    {:jikan_ex, "~> 0.1.0"}
  ]
end
```
