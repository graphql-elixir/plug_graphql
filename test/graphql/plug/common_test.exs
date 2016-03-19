defmodule GraphQL.Plug.CommonTest do
  use ExUnit.Case
  use Plug.Test
  import ExUnit.TestHelpers

  alias GraphQL.Type.String, as: GraphQLString

  defmodule TestSchema do
    def schema do
      %GraphQL.Schema{
        query: %GraphQL.Type.ObjectType{
          name: "Greeting",
          fields: %{
            greeting: %{
              type: %GraphQLString{},
              args: %{
                name: %{type: %GraphQLString{}}
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

  defmodule TestEndpointPlug do
    use Plug.Builder
    plug GraphQL.Plug.Endpoint, schema: {TestSchema, :schema}
  end

  defmodule TestGraphiQLPlug do
    use Plug.Builder
    plug GraphQL.Plug.GraphiQL, schema: {TestSchema, :schema}
  end

  setup do
    {
      :ok,
      [
        plugs: [TestEndpointPlug, TestGraphiQLPlug],
        bare_plugs: [GraphQL.Plug.Endpoint, GraphQL.Plug.GraphiQL]
      ]
    }
  end


  test "root data can be set at request time using function reference", context do
    Enum.map(context.bare_plugs, fn(test_plug) ->
      module_name = String.to_atom("TestRootPlugWithFunctionReference_#{to_string(test_plug)}")
      defmodule module_name do
        use Plug.Builder
        def root_eval(_conn), do: %{greeting: "Root"}
        plug test_plug, [schema: {TestSchema, :schema}, root_value: &module_name.root_eval/1 ]
      end

      success = ~S({"data":{"greeting":"Hello, Root!"}})
      assert_query module_name, {:get, "/", query: "{greeting}"}, {200, success}
    end)
  end

  test "root data can be hard coded at init time.", context do
    Enum.map(context.bare_plugs, fn(test_plug) ->
      module_name = String.to_atom("TestRootPlugWithHardCodedData#{to_string(test_plug)}")
      defmodule module_name do
        use Plug.Builder
        plug test_plug, [schema: {TestSchema, :schema}, root_value: %{greeting: "Hard Coded"}]
      end

      success = ~S({"data":{"greeting":"Hello, Hard Coded!"}})
      assert_query module_name, {:get, "/", query: "{greeting}"}, {200, success}
    end)
  end

  test "root data can be set using {module, fun} syntax", context do
    Enum.map(context.bare_plugs, fn(test_plug) ->
      module_name = String.to_atom("TestRootPlugWithMF#{to_string(test_plug)}")
      defmodule module_name do
        use Plug.Builder
        def root_eval(_conn), do: %{greeting: "MF"}
        plug test_plug, [schema: {TestSchema, :schema}, root_value: {module_name, :root_eval}]
      end

      success = ~S({"data":{"greeting":"Hello, MF!"}})
      assert_query module_name, {:get, "/", query: "{greeting}"}, {200, success}
    end)
  end

  test "specify schema using {module, fun} syntax", context do
    Enum.map(context.bare_plugs, fn(test_plug) ->
      module_name = String.to_atom("TestMFPlug#{to_string(test_plug)}")
      defmodule module_name do
        use Plug.Builder

        plug test_plug, schema: {TestSchema, :schema}
      end
      success = ~S({"data":{"greeting":"Hello, world!"}})
      assert_query module_name, {:get,  "/", query: "{greeting}"}, {200, success}
    end)
  end

  test "executes MF function when configured", context do
    Enum.map(context.bare_plugs, fn(test_plug) ->
      module_name = String.to_atom("TestPlugWithMFQuery#{to_string(test_plug)}")
      defmodule module_name do
        use Plug.Builder
        plug test_plug, [schema: {TestSchema, :schema}, query: "{greeting}"]
        def query(_conn), do: "{greeting}"
      end

      success = ~S({"data":{"greeting":"Hello, world!"}})
      assert_query module_name, {:get,  "/", nil},         {200, success}
      assert_query module_name, {:get,  "/", query: nil},  {200, success}
      assert_query module_name, {:get,  "/", query: ""},   {200, success}
      assert_query module_name, {:get,  "/", query: "  "}, {200, success}
    end)
  end

  test "uses configured query when no query specified", context do
    Enum.map(context.bare_plugs, fn(test_plug) ->
      module_name = String.to_atom("TestPlugWithQuery#{to_string(test_plug)}")
      defmodule module_name do
        use Plug.Builder
        plug test_plug, [schema: {TestSchema, :schema}, query: "{greeting}"]
      end

      success = ~S({"data":{"greeting":"Hello, world!"}})
      assert_query module_name, {:get,  "/", nil},         {200, success}
      assert_query module_name, {:get,  "/", query: nil},  {200, success}
      assert_query module_name, {:get,  "/", query: ""},   {200, success}
      assert_query module_name, {:get,  "/", query: "  "}, {200, success}
    end)
  end

  test "GET and POST successful query", context do
    success = ~S({"data":{"greeting":"Hello, world!"}})

    Enum.map(context.plugs, fn(test_plug) ->
      assert_query test_plug, {:get,  "/", query: "{greeting}"}, {200, success}
      assert_query test_plug, {:post, "/", query: "{greeting}"}, {200, success}
    end)
  end

  test "GET with variables", context do
    success = ~S({"data":{"greeting":"Hello, Josh!"}})
    query = "query hi($name: String) { greeting(name: $name) }"

    Enum.map(context.plugs, fn(test_plug) ->
      assert_query test_plug, {:get,  "/", query: query, variables: ~S({"name":"Josh"})}, {200, success}
    end)
  end

  test "GET with variables ignores invalid variables string", context do
    success = ~S({"data":{"greeting":"Hello, world!"}})
    query = "query hi($name: String) { greeting(name: $name) }"

    Enum.map(context.plugs, fn(test_plug) ->
      assert_query test_plug, {:get,  "/", query: query, variables: "x}"}, {200, success}
    end)
  end

  test "GET with operation name", context do
    success = ~S({"data":{"greeting":"Hello, you!"}})
    query = """
      query hi { greeting(name: "there") }
      query hey { greeting(name: "you") }
      query hello { greeting(name: "Josh") }
    """

    Enum.map(context.plugs, fn(test_plug) ->
      assert_query test_plug, {:get,  "/", query: query, operation_name: "hey"}, {200, success}
      assert_query test_plug, {:get,  "/", query: query, operationName: "hey"}, {200, success}
    end)
  end

  test "GET without operation name errors with multiple queries", context do
    error = ~S({"errors":[{"message":"Must provide operation name if query contains multiple operations."}]})
    query = """
      query hi { greeting(name: "there") }
      query hey { greeting(name: "you") }
    """

    Enum.map(context.plugs, fn(test_plug) ->
      assert_query test_plug, {:get,  "/", query: query}, {400, error}
    end)
  end

  test "missing query", context do
    no_query_found_error = ~S({"errors":[{"message":"Must provide query string."}]})

    Enum.map(context.plugs, fn(test_plug) ->
      assert_query test_plug, {:get,  "/", nil},         {400, no_query_found_error}
      assert_query test_plug, {:get,  "/", query: nil},  {400, no_query_found_error}
      assert_query test_plug, {:get,  "/", query: ""},   {400, no_query_found_error}
      assert_query test_plug, {:get,  "/", query: "  "}, {400, no_query_found_error}
      assert_query test_plug, {:post, "/", nil},         {400, no_query_found_error}
      assert_query test_plug, {:post, "/", query: nil},  {400, no_query_found_error}
      assert_query test_plug, {:post, "/", query: ""},   {400, no_query_found_error}
      assert_query test_plug, {:post, "/", query: "  "}, {400, no_query_found_error}
    end)
  end

  test "invalid query error", context do
    syntax_error = ~S({"errors":[{"message":"GraphQL: syntax error before:  on line 1","line_number":1}]})

    Enum.map(context.plugs, fn(test_plug) ->
      assert_query test_plug, {:get,  "/", query: "{"}, {400, syntax_error}
      assert_query test_plug, {:post, "/", query: "{"}, {400, syntax_error}
    end)
  end

  test "invalid http verbs", context do
    invalid_verb_error = ~S({"errors":[{"message":"GraphQL only supports GET and POST requests."}]})

    Enum.map(context.plugs, fn(test_plug) ->
      assert_query test_plug, {:put,     "/", query: "{greeting}"}, {400, invalid_verb_error}
      assert_query test_plug, {:patch,   "/", query: "{greeting}"}, {400, invalid_verb_error}
      assert_query test_plug, {:delete,  "/", query: "{greeting}"}, {400, invalid_verb_error}
      assert_query test_plug, {:options, "/", query: "{greeting}"}, {400, invalid_verb_error}
      assert_query test_plug, {:head,    "/", query: "{greeting}"}, {400, ""}
    end)
  end

  # more test inspiration from here
  # https://github.com/graphql/express-graphql/blob/master/src/__tests__/http-test.js
end
