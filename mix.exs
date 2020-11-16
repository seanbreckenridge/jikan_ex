defmodule JikanEx.MixProject do
  use Mix.Project

  @github_url "https://github.com/seanbreckenridge/jikan_ex"
  @description "A thin elixir wrapper for the Jikan API"

  def project do
    [
      app: :jikan_ex,
      version: "0.1.5",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Docs
      name: "JikanEx",
      source_url: @github_url,
      homepage_url: @github_url,
      docs: [extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :hackney]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.3.2"},
      {:jason, ">= 1.1.0"},
      {:hackney, ">= 1.15.2"},
      {:exvcr, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Sean Breckenridge <seanbrecke@gmail.com>"],
      files: ["lib", "LICENSE", "README.md", "mix.exs"],
      licenses: ["MIT"],
      links: %{"Github" => @github_url},
      description: @description
    ]
  end
end
