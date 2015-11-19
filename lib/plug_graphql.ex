defmodule GraphQL.Plug.GraphQLEndpoint do
  import Plug.Conn
  alias Plug.Conn

  @behaviour Plug

  def init(schema) do
    schema
  end

  def call(%Conn{ method: "GET" } = conn, schema) do
    query = "{greeting}"
    result = GraphQL.execute(schema, query)
    json = Poison.encode(result)
    case json do
      {:ok, data} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, data)
      {:error, errors} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, "Error")
    end
  end

end
