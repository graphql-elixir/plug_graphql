defmodule GraphQL.Plug.Endpoint do
  import Plug.Conn
  alias Plug.Conn

  @behaviour Plug

  def init(opts) do
    schema = case Keyword.get(opts, :schema) do
      {mod, func} -> apply(mod, func, [])
      s -> s
    end
    %{schema: schema}
  end

  def call(%Conn{method: m, params: %{"query" => query}} = conn, %{schema: schema}) when m in ["GET", "POST"] do
    cond do
      query && String.strip(query) != "" -> handle_call(conn, schema, query)
      true -> handle_error(conn, "Must provide query string.")
    end
  end

  def call(%Conn{method: m} = conn, schema) when m in ["GET", "POST"] do
    if graphql?(conn) do
      case read_whole_body(conn) do
        {:error, reason} -> handle_error(conn, reason)
        {:ok, query} ->
          cond do
            String.strip(query) != "" -> handle_call(conn, schema, query)
            true -> handle_error(conn, "Must provide query body.")
          end
      end
    else
      handle_error(conn, "Must provide query string.")
    end
  end

  def call(%Conn{method: _} = conn, _) do
    handle_error(conn, "GraphQL only supports GET and POST requests.")
  end

  defp handle_call(conn, schema, query) do
    conn
    |> put_resp_content_type("application/json")
    |> execute(schema, query)
  end

  defp handle_error(conn, message) do
    {:ok, errors} = Poison.encode %{errors: [%{message: message}]}
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, errors)
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
          {:ok, json}      -> send_resp(conn, 400, json)
          {:error, errors} -> send_resp(conn, 400, errors)
        end
    end
  end

  defp graphql?(conn) do
    {"content-type", "application/graphql"} in conn.req_headers
  end

  defp read_whole_body(conn) do
    read_whole_body(read_body(conn), "")
  end

  defp read_whole_body({:ok, body, _conn}, acc), do: {:ok, acc <> body}
  defp read_whole_body({:more, partial_body, conn}, acc) do
    read_whole_body(read_body(conn), acc <> partial_body)
  end
  defp read_whole_body({:error, reason}, _acc), do: {:error, reason}
end
