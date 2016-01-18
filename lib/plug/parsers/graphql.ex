defmodule Plug.Parsers.GRAPHQL do
  @moduledoc """
  Parses a GraphQL request body.

  An empty request body is parsed as an empty map.
  """

  @behaviour Plug.Parsers
  import Plug.Conn

  def parse(conn, "application", "graphql", _headers, opts) do
    conn
    |> read_body(opts)
    |> decode
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end

  defp decode({:more, _, conn}),  do: {:error, :too_large, conn}
  defp decode({:ok, "", conn}),   do: {:ok, %{}, conn}
  defp decode({:ok, body, conn}), do: {:ok, %{"query" => body}, conn}
end
