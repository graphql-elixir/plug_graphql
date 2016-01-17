defmodule GraphQL.Plug.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test

  # Simplest possible TestSchema
  defmodule TestSchema do
    def schema do
      %GraphQL.Schema{
        query: %GraphQL.ObjectType{
          name: "Greeting",
          fields: %{
            greeting: %{
              type: "String",
              resolve: &TestSchema.greeting/3,
            }
          }
        }
      }
    end

    def greeting(_, %{name: name}, _), do: "Hello, #{name}!"
    def greeting(_, _, _), do: greeting(%{}, %{name: "world"}, %{})
  end

  defmodule TestPlug do
    use Plug.Builder

    plug GraphQL.Plug.Endpoint, schema: TestSchema.schema
  end

  def assert_query({method, path, params}, {status, body}) do
    assert_response conn(method, path, params), status, body
  end

  def assert_response(conn, status, body) do
    conn = TestPlug.call conn, []

    assert conn.status == status
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == body
  end

  test "GET and POST successful query" do
    success = ~S({"data":{"greeting":"Hello, world!"}})
    assert_query {:get,  "/", query: "{greeting}"}, {200, success}
    assert_query {:post, "/", query: "{greeting}"}, {200, success}
  end

  test "specify schema using {module, fun} syntax" do
    defmodule TestMFPlug do
      use Plug.Builder

      plug GraphQL.Plug.Endpoint, schema: {TestSchema, :schema}
    end
    conn = conn(:get, "/", query: "{greeting}")
    conn = TestMFPlug.call conn, []

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == ~S({"data":{"greeting":"Hello, world!"}})
  end

  test "missing query" do
    no_query_found_error = ~S({"errors":[{"message":"Must provide query string."}]})
    assert_query {:get,  "/", nil},         {400, no_query_found_error}
    assert_query {:get,  "/", query: nil},  {400, no_query_found_error}
    assert_query {:get,  "/", query: ""},   {400, no_query_found_error}
    assert_query {:get,  "/", query: "  "}, {400, no_query_found_error}
    assert_query {:post, "/", nil},         {400, no_query_found_error}
    assert_query {:post, "/", query: nil},  {400, no_query_found_error}
    assert_query {:post, "/", query: ""},   {400, no_query_found_error}
    assert_query {:post, "/", query: "  "}, {400, no_query_found_error}
  end

  test "invalid query error" do
    syntax_error = ~S({"errors":[{"message":"GraphQL: syntax error before:  on line 1","line_number":1}]})
    assert_query {:get,  "/", query: "{"}, {400, syntax_error}
    assert_query {:post, "/", query: "{"}, {400, syntax_error}
  end

  test "invalid http verbs" do
    invalid_verb_error = ~S({"errors":[{"message":"GraphQL only supports GET and POST requests."}]})
    assert_query {:put,     "/", query: "{greeting}"}, {400, invalid_verb_error}
    assert_query {:patch,   "/", query: "{greeting}"}, {400, invalid_verb_error}
    assert_query {:delete,  "/", query: "{greeting}"}, {400, invalid_verb_error}
    assert_query {:options, "/", query: "{greeting}"}, {400, invalid_verb_error}
    assert_query {:head,    "/", query: "{greeting}"}, {400, ""}
  end

  test "content-type application/graphql" do
    success = ~S({"data":{"greeting":"Hello, world!"}})
    conn = conn(:post, "/", "{greeting}") |> put_req_header("content-type", "application/graphql")
    assert_response(conn, 200, success)
  end

  test "content-type application/graphql no body" do
    empty_body_error = ~S({"errors":[{"message":"Must provide query body."}]})

    conn = conn(:post, "/", nil) |> put_req_header("content-type", "application/graphql")
    assert_response(conn, 400, empty_body_error)

    conn = conn(:post, "/", "") |> put_req_header("content-type", "application/graphql")
    assert_response(conn, 400, empty_body_error)

    conn = conn(:post, "/", "  ") |> put_req_header("content-type", "application/graphql")
    assert_response(conn, 400, empty_body_error)
  end

  # more test inspiration from here
  # https://github.com/graphql/express-graphql/blob/master/src/__tests__/http-test.js
end
