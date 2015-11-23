defmodule GraphQL.Plug.GraphQLEndpoint do
  import Plug.Conn
  alias Plug.Conn

  @behaviour Plug

  def init(schema) do
    schema
  end

  def call(%Conn{method: req_method, params: %{"query" => query}} = conn, schema)
  when req_method in ["GET", "POST"] do
    handle_call(conn, schema, query)
  end

  def call(%Conn{method: _} = conn, _) do
    handle_error(conn)
  end

  defp handle_call(conn, schema, query) do
    conn
    |> put_resp_content_type("application/json")
    |> execute(schema, query)
    |> halt
  end

  defp handle_error(conn) do
    {:ok, errors} = Poison.encode %{errors: [%{message: "GraphQL only supports GET and POST requests."}]}
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, errors)
    |> halt
  end

  defp execute(conn, schema, query) do
    case GraphQL.execute(schema, query) do
      {:ok, data} ->
        case Poison.encode(%{data: data}) do
          {:ok, json}      -> send_resp(conn, 200, json)
          {:error, errors} -> send_resp(conn, 400, errors)
        end
      {:error, errors} ->
        case Poison.encode(errors) do
          {:ok, json} ->      send_resp(conn, 400, json)
          {:error, errors} -> send_resp(conn, 400, errors)
        end
    end
  end
end
