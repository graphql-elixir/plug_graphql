defmodule GraphQL.Plug.GraphiQLTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import ExUnit.TestHelpers

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

  defmodule TestPlug do
    use Plug.Builder

    plug GraphQL.Plug.GraphiQL, schema: {TestSchema, :schema}
  end

  test "GET and POST successful query" do
    success = ~S({"data":{"greeting":"Hello, world!"}})
    assert_query TestPlug, {:get,  "/", query: "{greeting}"}, {200, success}
    assert_query TestPlug, {:post, "/", query: "{greeting}"}, {200, success}
  end

  test "root data can be set at request time using function reference" do
    defmodule TestRootPlugWithFunctionReference do
      use Plug.Builder
      def root_eval(_conn), do: %{greeting: "Root"}
      plug GraphQL.Plug.Endpoint, [schema: {TestSchema, :schema}, root_value: &TestRootPlugWithFunctionReference.root_eval/1 ]
    end

    success = ~S({"data":{"greeting":"Hello, Root!"}})
    assert_query TestRootPlugWithFunctionReference, {:get, "/", query: "{greeting}"}, {200, success}
  end

  test "root data can be hard coded at init time." do
    defmodule TestRootPlugWithHardCodedData do
      use Plug.Builder
      plug GraphQL.Plug.Endpoint, [schema: {TestSchema, :schema}, root_value: %{greeting: "Hard Coded"}]
    end

    success = ~S({"data":{"greeting":"Hello, Hard Coded!"}})
    assert_query TestRootPlugWithHardCodedData, {:get, "/", query: "{greeting}"}, {200, success}
  end

  test "root data can be set using {module, fun} syntax" do
    defmodule TestRootPlugWithMF do
      use Plug.Builder
      def root_eval(_conn), do: %{greeting: "MF"}
      plug GraphQL.Plug.Endpoint, [schema: {TestSchema, :schema}, root_value: {TestRootPlugWithMF, :root_eval}]
    end

    success = ~S({"data":{"greeting":"Hello, MF!"}})
    assert_query TestRootPlugWithMF, {:get, "/", query: "{greeting}"}, {200, success}
  end

  test "GET with variables" do
    success = ~S({"data":{"greeting":"Hello, Josh!"}})
    query = "query hi($name: String) { greeting(name: $name) }"
    assert_query TestPlug, {:get,  "/", query: query, variables: ~S({"name":"Josh"})}, {200, success}
  end

  test "GET with variables ignores invalid variables string" do
    success = ~S({"data":{"greeting":"Hello, !"}})
    query = "query hi($name: String) { greeting(name: $name) }"
    assert_query TestPlug, {:get,  "/", query: query, variables: "x}"}, {200, success}
  end

  test "GET with operation name" do
    success = ~S({"data":{"greeting":"Hello, you!"}})
    query = """
      query hi { greeting(name: "there") }
      query hey { greeting(name: "you") }
      query hello { greeting(name: "Josh") }
    """
    assert_query TestPlug, {:get,  "/", query: query, operation_name: "hey"}, {200, success}
    assert_query TestPlug, {:get,  "/", query: query, operationName: "hey"}, {200, success}
  end

  test "GET without operation name errors with multiple queries" do
    error = ~S({"errors":[{"message":"Must provide operation name if query contains multiple operations."}]})
    query = """
      query hi { greeting(name: "there") }
      query hey { greeting(name: "you") }
    """
    assert_query TestPlug, {:get,  "/", query: query}, {400, error}
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
