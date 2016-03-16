defmodule GraphQL.Plug.GraphiQLTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "use GraphiQL defaults to true" do
    opts = GraphQL.Plug.GraphiQL.init([])

    assert opts[:allow_graphiql?]
  end

  test "use GraphiQL on GET request with accept of `text/html`" do
    opts = GraphQL.Plug.GraphiQL.init([])
    conn = conn(:get, "/")
           |> put_req_header("accept", "text/html")

    result = GraphQL.Plug.GraphiQL.use_graphiql?(conn, opts)

    assert result === true
  end

  test "DO NOT use GraphiQL on POST request with accept of `text/html`" do
    opts = GraphQL.Plug.GraphiQL.init([])
    conn = conn(:post, "/")
           |> put_req_header("accept", "text/html")

    result = GraphQL.Plug.GraphiQL.use_graphiql?(conn, opts)

    assert result === false
  end

  test "DO NOT use GraphiQL on GET request with accept of `application/json`" do
    opts = GraphQL.Plug.GraphiQL.init([])
    conn = conn(:get, "/")
           |> put_req_header("accept", "application/json")

    result = GraphQL.Plug.GraphiQL.use_graphiql?(conn, opts)

    assert result === false
  end

  test "DO NOT use GraphiQL on GET request with accept of `text/html` when config is off" do
    opts = GraphQL.Plug.GraphiQL.init([allow_graphiql?: false])
    conn = conn(:get, "/")
           |> put_req_header("accept", "text/html")

    result = GraphQL.Plug.GraphiQL.use_graphiql?(conn, opts)

    assert result === false
  end

  test "init sets configuration" do
    opts = GraphQL.Plug.GraphiQL.init([
      allow_graphiql?: true,
      schema: "schema",
      root_value: "root",
      query: "query"])

    assert opts[:allow_graphiql?] == true
    assert opts[:query] == "query"
    assert opts[:schema] == "schema"
    assert opts[:root_value] == "root"
  end
end
