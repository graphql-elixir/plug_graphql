# GraphQL Plug

## Installation

The package can be installed as follows:

  1. Add plug_graphql to your list of dependencies in `mix.exs`:

  ```elixir
    def deps do
      [{:plug_graphql, "~> 0.0.1"}]
    end
  ```

  2. Ensure `plug_graphql` is started before your application:

  ```elixir
    def application do
      [applications: [:plug_graphql]]
    end
  ```

  3. Define a Schema

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

  4. Use the plug like so:

  ```elixir
    plug GraphQL.Plug.GraphQLEndpoint, TestSchema.schema
  ```
