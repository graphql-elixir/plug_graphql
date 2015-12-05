defmodule PlugGraphql.Mixfile do
  use Mix.Project

  @version "0.0.6"

  @description "A Plug integration for the Elixir implementation of Facebook's GraphQL"
  @repo_url "https://github.com/joshprice/plug_graphql"

  def project do
    [app: :plug_graphql,
     description: @description,
     version: @version,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps,
     docs: [main: "readme", extras: ["README.md"]]]
  end

  def application do
    [applications: [:logger, :plug, :cowboy]]
  end

  defp deps do
    [{:earmark, "~> 0.1", only: :docs},
     {:ex_doc, "~> 0.11", only: :docs},
     {:cowboy, "~> 1.0"},
     {:plug, "~> 0.14 or ~> 1.0"},
     {:poison, "~> 1.5"},
     {:graphql, "~> 0.0.6"}]
  end

  defp package do
    [maintainers: ["Josh Price"],
     licenses: ["BSD"],
     links: %{"GitHub" => @repo_url},
     files: ~w(lib mix.exs *.md LICENSE)]
  end
end
