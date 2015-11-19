defmodule GraphQL.Plug.GraphQLEndpoint do
  import Plug.Conn
  alias Plug.Conn

  @behaviour Plug

  def init(schema) do
    schema
  end

  def call(%Conn{method: "GET", params: %{"query" => query}} = conn, schema) do
    conn = put_resp_content_type(conn, "application/json")

    case GraphQL.execute(schema, query) do
      {:ok, data} ->
        case Poison.encode(%{data: data}) do
          {:ok, json} ->
            send_resp(conn, 200, json)
          {:error, errors} ->
            send_resp(conn, 400, errors)
        end
      {:error, errors} ->
        case Poison.encode(errors) do
          {:ok, json} ->
            send_resp(conn, 400, json)
          {:error, errors} ->
            send_resp(conn, 400, errors)
        end
    end
  end

end
