# GraphQL Plug

[![Build Status](https://travis-ci.org/graphql-elixir/plug_graphql.svg)](https://travis-ci.org/graphql-elixir/plug_graphql)
[![Public Slack Discussion](https://graphql-slack.herokuapp.com/badge.svg)](https://graphql-slack.herokuapp.com/)

`plug_graphql` is a [Plug](https://github.com/elixir-lang/plug) integration for the [GraphQL Elixir](https://github.com/graphql-elixir/graphql) implementation of Facebook's GraphQL.

This [Plug](https://github.com/elixir-lang/plug) allows you to easily mount a GraphQL endpoint in Phoenix. This example project shows you how:

* [Phoenix GraphQL example project](https://github.com/graphql-elixir/hello_graphql_phoenix)


## Installation

  1. Make a new Phoenix app, or add it to your existing app.

    ```sh
    mix phoenix.new hello_graphql
    cd hello_graphql
    ```

    ```sh
    git clone https://github.com/graphql-elixir/hello_graphql_phoenix
    ```

  2. Add `plug_graphql` to your list of dependencies and applications in `mix.exs` and install the package with `mix deps.get`.

    ```elixir
    def application do
      # Add the application to your list of applications.
      # This will ensure that it will be included in a release.
      [applications: [:logger, :plug_graphql]]
    end

    def deps do
      [{:plug_graphql, "~> 0.3.1"}]
    end
    ```

## Usage

  1. Define a simple schema in `web/graphql/test_schema.ex`:

    ```elixir
    defmodule TestSchema do
      def schema do
        %GraphQL.Schema{
          query: %GraphQL.Type.ObjectType{
            name: "Hello",
            fields: %{
              greeting: %{
                type: %GraphQL.Type.String{},
                args: %{
                  name: %{
                    type: %GraphQL.Type.String{}
                  }
                },
                resolve: {TestSchema, :greeting}
              }
            }
          }
        }
      end

      def greeting(_, %{name: name}, _), do: "Hello, #{name}!"
      def greeting(_, _, _), do: "Hello, world!"
    end
    ```

  2. Your `api` pipeline should have this as a minimum:

    ```elixir
    pipeline :api do
      plug :accepts, ["json"]
    end
    ```

  3. Mount the GraphQL endpoint as follows:

    ```elixir
    scope "/api" do
      pipe_through :api

      forward "/", GraphQL.Plug, schema: {TestSchema, :schema}
    end
    ```

  4. Start Phoenix

    ```sh
    mix phoenix.server
    ```

  5. Open your browser to `http://localhost:4000/api?query={greeting}` and you should see something like this:

    ```json
    {
      "data": {
        "greeting": "Hello, world!"
      }
    }
    ```

## Contributions

This is pretty early days, the GraphQL Elixir ecosystem needs a lot more work to be useful.

However we can't get there without your help, so any questions, bug reports, feedback,
feature requests and/or PRs are most welcome!

## Acknowledgements

Thanks and appreciation goes to the following contributors for PRs, discussions, answering many questions and providing helpful feedback:

* Daniel Neighman (https://github.com/hassox)
* Chris McCord (https://github.com/chrismccord)
* Aaron Weiker (https://github.com/aweiker)
* James Hiscock (https://github.com/bockit)

Thanks also to everyone who has submitted PRs, logged issues, given feedback or asked questions.
