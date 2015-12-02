defmodule GraphQL.Plug.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts GraphQL.Plug.Router.init([])

  def assert_query({method, path, params}, {status, body}) do
    assert_response conn(method, path, params), status, body
  end

  def assert_response(conn, status, body) do
    conn = GraphQL.Plug.Router.call conn, []

    IO.inspect conn

    assert conn.state == :sent
    assert conn.status == status
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert conn.resp_body == body
  end

  test "GET and POST successful query" do
    success = ~S({"data":{"greeting":"Hello, world!"}})
    assert_query {:get,  "/graphql", query: "{greeting}"}, {200, success}
    assert_query {:post, "/graphql", query: "{greeting}"}, {200, success}
  end

  # test "missing query" do
  #   no_query_found_error = ~S({"errors":[{"message":"Must provide query string."}]})
  #   assert_query {:get,  "/graphql", nil},         {400, no_query_found_error}
  #   assert_query {:get,  "/graphql", query: nil},  {400, no_query_found_error}
  #   assert_query {:get,  "/graphql", query: ""},   {400, no_query_found_error}
  #   assert_query {:get,  "/graphql", query: "  "}, {400, no_query_found_error}
  #   assert_query {:post, "/graphql", nil},         {400, no_query_found_error}
  #   assert_query {:post, "/graphql", query: nil},  {400, no_query_found_error}
  #   assert_query {:post, "/graphql", query: ""},   {400, no_query_found_error}
  #   assert_query {:post, "/graphql", query: "  "}, {400, no_query_found_error}
  # end
  #
  # test "invalid query error" do
  #   syntax_error = ~S({"errors":[{"message":"GraphQL: syntax error before:  on line 1","line_number":1}]})
  #   assert_query {:get,  "/graphql", query: "{"}, {400, syntax_error}
  #   assert_query {:post, "/graphql", query: "{"}, {400, syntax_error}
  # end
  #
  # test "invalid http verbs" do
  #   invalid_verb_error = ~S({"errors":[{"message":"GraphQL only supports GET and POST requests."}]})
  #   assert_query {:put,     "/graphql", query: "{greeting}"}, {400, invalid_verb_error}
  #   assert_query {:patch,   "/graphql", query: "{greeting}"}, {400, invalid_verb_error}
  #   assert_query {:delete,  "/graphql", query: "{greeting}"}, {400, invalid_verb_error}
  #   assert_query {:options, "/graphql", query: "{greeting}"}, {400, invalid_verb_error}
  #   assert_query {:head,    "/graphql", query: "{greeting}"}, {400, ""}
  # end
end
