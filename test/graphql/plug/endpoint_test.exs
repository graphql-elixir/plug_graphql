defmodule GraphQL.Plug.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias GraphQL.Type.String

  defmodule TestSchema do
    def schema do
      %GraphQL.Schema{
        query: %GraphQL.Type.ObjectType{
          name: "Greeting",
          fields: %{
            greeting: %{
              type: %String{},
              args: %{
                name: %{type: %String{}}
              },
              resolve: {TestSchema, :greeting},
            }
          }
        }
      }
    end

    def greeting(_, %{name: name}, _), do: "Hello, #{name}!"
    def greeting(%{greeting: name}, _, _), do: "Hello, #{name}!"
    def greeting(_, _, _), do: greeting(%{}, %{name: "world"}, %{})
  end

  test "init sets configuration" do
    opts = GraphQL.Plug.Endpoint.init([
      allow_graphiql?: false,
      schema: "schema",
      root_value: "root",
      query: "query"])

    assert Keyword.has_key?(opts, :allow_graphiql?) == false
    assert opts[:query] == "query"
    assert opts[:schema] == "schema"
    assert opts[:root_value] == "root"
  end
end
