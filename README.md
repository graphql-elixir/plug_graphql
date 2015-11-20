# GraphQL Plug

[![Build Status](https://travis-ci.org/joshprice/plug_graphql.svg)](https://travis-ci.org/joshprice/plug_graphql)
[![Public Slack Discussion](https://graphql-slack.herokuapp.com/badge.svg)](https://graphql-slack.herokuapp.com/)

A Plug integration for the Elixir implementation of Facebook's GraphQL. Allows you to mount a GraphQL endpoint in Phoenix.

## Installation

The package can be installed as follows:

Make a new Phoenix app

```sh
  mix phoenix.new hello_graphql --no-ecto
  cd hello_graphql
```

Add `plug_graphql` to your list of dependencies in `mix.exs`:

```elixir
  def deps do
    [{:plug_graphql, "~> 0.0.1"}]
  end
```

Then install the package

```sh
  mix deps.get
```

Define a Schema

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

Add the plug to your `api` pipeline:

```elixir
  pipeline :api do
    plug :accepts, ["json"]

    plug GraphQL.Plug.GraphQLEndpoint, TestSchema.schema
  end
```

And add an endpoint so this route fires

```elixir
  scope "/api", HelloGraphql do
    pipe_through :api
    get "/", PageController, :index
  end
```

Start Phoenix

    mix phoenix.server

Open your browser and hit

    http://localhost:4000/api?query={greeting}

You should see something like this:

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
