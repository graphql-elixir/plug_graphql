defmodule GraphQL.PlugTest do
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
    def greeting(_, _, _), do: greeting(%{}, %{name: "world"}, %{})
  end

  defmodule TestPlug do
    use Plug.Builder

    plug GraphQL.Plug, schema: {TestSchema, :schema}
  end

  test "content-type application/graphql" do
    success = ~S({"data":{"greeting":"Hello, world!"}})
    conn = conn(:post, "/", "{greeting}") |> put_req_header("content-type", "application/graphql")
    assert_response(TestPlug, conn, 200, success)
  end

  test "content-type application/graphql no body" do
    empty_body_error = ~S({"errors":[{"message":"Must provide query string."}]})

    conn = conn(:post, "/", nil) |> put_req_header("content-type", "application/graphql")
    assert_response(TestPlug, conn, 400, empty_body_error)

    conn = conn(:post, "/", "") |> put_req_header("content-type", "application/graphql")
    assert_response(TestPlug, conn, 400, empty_body_error)

    conn = conn(:post, "/", "  ") |> put_req_header("content-type", "application/graphql")
    assert_response(TestPlug, conn, 400, empty_body_error)
  end

  test "content-type application/json" do
    success = ~S({"data":{"greeting":"Hello, world!"}})
    {:ok, json_body} = Poison.encode(%{query: "{greeting}"})
    conn = conn(:post, "/", json_body) |> put_req_header("content-type", "application/json")
    assert_response(TestPlug, conn, 200, success)
  end

  test "content-type application/json no body" do
    empty_body_error = ~S({"errors":[{"message":"Must provide query string."}]})

    conn = conn(:post, "/", nil) |> put_req_header("content-type", "application/json")
    assert_response(TestPlug, conn, 400, empty_body_error)

    conn = conn(:post, "/", "") |> put_req_header("content-type", "application/json")
    assert_response(TestPlug, conn, 400, empty_body_error)

    # conn = conn(:post, "/", "  ") |> put_req_header("content-type", "application/json")
    # assert_response(TestPlug, conn, 400, empty_body_error)
  end
end
