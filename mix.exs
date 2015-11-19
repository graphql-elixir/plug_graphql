defmodule PlugGraphql.Mixfile do
  use Mix.Project

  def project do
    [app: :plug_graphql,
     description: "A Phoenix Plug integration for the GraphQL package",
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     deps: deps,
     docs: [extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :plug, :cowboy]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev},
     {:cowboy, "~> 1.0"},
     {:plug, "~> 0.14 or ~> 1.0"},
     {:poison, "~> 1.5"},
     {:graphql, "~> 0.0.4"}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Josh Price"],
     licenses: ["BSD"],
     links: %{"GitHub" => "https://github.com/joshprice/plug_graphql"}]
  end
end
