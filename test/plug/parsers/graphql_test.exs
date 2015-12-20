defmodule Plug.Parsers.GRAPHQLTest do
  use ExUnit.Case, async: true
  use Plug.Test

  def graphql_conn(body, content_type \\ "application/graphql") do
    conn(:post, "/", body) |> put_req_header("content-type", content_type)
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [:graphql])
    Plug.Parsers.call(conn, Plug.Parsers.init(opts))
  end

  test "parses the request body" do
    conn = graphql_conn("{hello}") |> parse()
    assert conn.params["query"] == "{hello}"
  end

  test "handles empty body as blank map" do
    conn = graphql_conn(nil) |> parse()
    assert conn.params == %{}
  end

  test "raises on too large bodies" do
    exception = assert_raise Plug.Parsers.RequestTooLargeError, fn ->
      graphql_conn("{hello}") |> parse(length: 5)
    end
    assert Plug.Exception.status(exception) == 413
  end
end
