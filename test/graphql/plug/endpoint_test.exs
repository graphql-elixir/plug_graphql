defmodule GraphQL.Plug.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import ExUnit.TestHelpers

  defmodule TestSchema do
    def schema do
      %GraphQL.Schema{
        query: %GraphQL.Type.ObjectType{
          name: "Greeting",
          fields: %{
            greeting: %{
              type: "String",
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

  defmodule TestPlug do
    use Plug.Builder

    plug GraphQL.Plug, schema: {TestSchema, :schema}
  end

  test "GET and POST successful query" do
    success = ~S({"data":{"greeting":"Hello, world!"}})
    assert_query TestPlug, {:get,  "/", query: "{greeting}"}, {200, success}
    assert_query TestPlug, {:post, "/", query: "{greeting}"}, {200, success}
  end

  test "root data can be set at request time" do
    defmodule TestRootPlug do
      use Plug.Builder
      def root_eval(_conn), do: %{greeting: "Root"}
      plug GraphQL.Plug.Endpoint, [schema: {TestSchema, :schema}, root: &TestRootPlug.root_eval/1 ]
    end

    conn = conn(:get, "/", query: "{greeting}")
    conn = TestRootPlug.call conn, []

    assert conn.resp_body == ~S({"data":{"greeting":"Hello, Root!"}})
  end

  test "specify schema using {module, fun} syntax" do
    defmodule TestMFPlug do
      use Plug.Builder
      
      plug GraphQL.Plug.Endpoint, schema: {TestSchema, :schema}
    end
    success = ~S({"data":{"greeting":"Hello, world!"}})
    assert_query TestMFPlug, {:get,  "/", query: "{greeting}"}, {200, success}
  end

  test "missing query" do
    no_query_found_error = ~S({"errors":[{"message":"Must provide query string."}]})
    assert_query TestPlug, {:get,  "/", nil},         {400, no_query_found_error}
    assert_query TestPlug, {:get,  "/", query: nil},  {400, no_query_found_error}
    assert_query TestPlug, {:get,  "/", query: ""},   {400, no_query_found_error}
    assert_query TestPlug, {:get,  "/", query: "  "}, {400, no_query_found_error}
    assert_query TestPlug, {:post, "/", nil},         {400, no_query_found_error}
    assert_query TestPlug, {:post, "/", query: nil},  {400, no_query_found_error}
    assert_query TestPlug, {:post, "/", query: ""},   {400, no_query_found_error}
    assert_query TestPlug, {:post, "/", query: "  "}, {400, no_query_found_error}
  end

  test "invalid query error" do
    syntax_error = ~S({"errors":[{"message":"GraphQL: syntax error before:  on line 1","line_number":1}]})
    assert_query TestPlug, {:get,  "/", query: "{"}, {400, syntax_error}
    assert_query TestPlug, {:post, "/", query: "{"}, {400, syntax_error}
  end

  test "invalid http verbs" do
    invalid_verb_error = ~S({"errors":[{"message":"GraphQL only supports GET and POST requests."}]})
    assert_query TestPlug, {:put,     "/", query: "{greeting}"}, {400, invalid_verb_error}
    assert_query TestPlug, {:patch,   "/", query: "{greeting}"}, {400, invalid_verb_error}
    assert_query TestPlug, {:delete,  "/", query: "{greeting}"}, {400, invalid_verb_error}
    assert_query TestPlug, {:options, "/", query: "{greeting}"}, {400, invalid_verb_error}
    assert_query TestPlug, {:head,    "/", query: "{greeting}"}, {400, ""}
  end

  # more test inspiration from here
  # https://github.com/graphql/express-graphql/blob/master/src/__tests__/http-test.js
end
