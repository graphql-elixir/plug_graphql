defmodule PlugGraphqlTest do
  use ExUnit.Case, async: true
  use Plug.Test

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


  defmodule TestPlug do
    use Plug.Builder

    plug GraphQL.Plug.GraphQLEndpoint, TestSchema.schema
  end

  test "simple query" do
    conn = conn(:get, "/")
    |> TestPlug.call []

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"data":{"greeting":"Hello, world!"}}
    """
  end
end
