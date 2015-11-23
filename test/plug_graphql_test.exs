defmodule PlugGraphqlTest do
  use ExUnit.Case, async: true
  use Plug.Test

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

  # Setup a Plug which calls the Plug under test
  defmodule TestPlug do
    use Plug.Builder

    plug GraphQL.Plug.GraphQLEndpoint, TestSchema.schema
  end

  test "GET query" do
    conn = conn(:get, "/", query: "{greeting}")
    |> TestPlug.call [] # Q: what can be passed in here instead of []? how does schema get through? is this Plug.Builder macro magic?

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"data":{"greeting":"Hello, world!"}}
    """
    assert conn.halted == true
  end

  test "GET no query" do
    conn = conn(:get, "/")
    |> TestPlug.call []

    assert conn.status == 400
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"errors":[{"message":"Must provide query string."}]}
    """
    assert conn.halted == true
  end

  test "GET blank query" do
    conn = conn(:get, "/", query: "")
    |> TestPlug.call []

    assert conn.status == 400
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"errors":[{"message":"Must provide query string."}]}
    """
    assert conn.halted == true
  end

  test "GET spaces only query" do
    conn = conn(:get, "/", query: "    ")
    |> TestPlug.call []

    assert conn.status == 400
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"errors":[{"message":"Must provide query string."}]}
    """
    assert conn.halted == true
  end

  test "GET empty query" do
    conn = conn(:get, "/", query: nil)
    |> TestPlug.call []

    assert conn.status == 400
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"errors":[{"message":"Must provide query string."}]}
    """
    assert conn.halted == true
  end

  test "GET error" do
    conn = conn(:get, "/", query: "{")
    |> TestPlug.call []

    assert conn.status == 400
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"errors":[{"message":"GraphQL: syntax error before:  on line 1","line_number":1}]}
    """
    assert conn.halted == true
  end

  test "POST query" do
    conn = conn(:get, "/", query: "{greeting}")
    |> TestPlug.call []

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"data":{"greeting":"Hello, world!"}}
    """
    assert conn.halted == true
  end

  test "POST error" do
    conn = conn(:post, "/", query: "{")
    |> TestPlug.call []

    assert conn.status == 400
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"errors":[{"message":"GraphQL: syntax error before:  on line 1","line_number":1}]}
    """
    assert conn.halted == true
  end

  test "PUT error" do
    conn = conn(:put, "/", query: "{")
    |> TestPlug.call []

    assert conn.status == 400
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"errors":[{"message":"GraphQL only supports GET and POST requests."}]}
    """
    assert conn.halted == true
  end

  test "PATCH error" do
    conn = conn(:patch, "/", query: "{")
    |> TestPlug.call []

    assert conn.status == 400
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"errors":[{"message":"GraphQL only supports GET and POST requests."}]}
    """
    assert conn.halted == true
  end

  test "DELETE error" do
    conn = conn(:patch, "/", query: "{")
    |> TestPlug.call []

    assert conn.status == 400
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == String.strip """
      {"errors":[{"message":"GraphQL only supports GET and POST requests."}]}
    """
    assert conn.halted == true
  end
end
