# GraphQL Plug

[![Build Status](https://travis-ci.org/joshprice/plug_graphql.svg)](https://travis-ci.org/joshprice/plug_graphql)
[![Public Slack Discussion](https://graphql-slack.herokuapp.com/badge.svg)](https://graphql-slack.herokuapp.com/)

`graphql_plug` is a Plug integration for the [GraphQL Elixir](https://github.com/joshprice/graphql-elixir) implementation of Facebook's GraphQL.

Allows you to easily mount a GraphQL endpoint in Phoenix.

## Installation

  1. Make a new Phoenix app

    ```sh
    mix phoenix.new hello_graphql --no-ecto
    cd hello_graphql
    ```

  2. Add `plug_graphql` to your list of dependencies in `mix.exs` and install the package with `mix deps.get`.

    ```elixir
    def deps do
      [{:plug_graphql, "~> 0.0.2"}]
    end
    ```

## Usage

  1. Define a Schema. Here's a simple one to try out:

    ```elixir
    # The GraphQL schema we're going to use
    defmodule TestSchema do
      def schema do
        %GraphQL.Schema{
          query: %GraphQL.ObjectType{
            name: "RootQueryType",
            fields: [
              %GraphQL.FieldDefinition{
                name: "greeting",
                type: "String",
                resolve: &TestSchema.greeting/1,
              }
            ]
          }
        }
      end

      def greeting(name: name), do: "Hello, #{name}!"
      def greeting(_), do: greeting(name: "world")
    end
    ```

  2. Add the plug to your `api` pipeline:

    ```elixir
    pipeline :api do
      plug :accepts, ["json"]

      plug GraphQL.Plug.Endpoint, TestSchema.schema
    end
    ```

  3. Add an endpoint so this route fires

    ```elixir
    scope "/api", HelloGraphql do
      pipe_through :api
      get "/", PageController, :index
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

This is pretty early days, the graphql execution engine needs a lot more work to be useful.

However we can't get there without your help, so any questions, bug reports, feedback,
feature requests and/or PRs are most welcome!
