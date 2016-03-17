defmodule GraphQL.Plug.Endpoint do
  @moduledoc """
  This is the core plug for mounting a GraphQL server.

  You can build your own pipeline by mounting the
  `GraphQL.Plug.Endpoint` plug directly.

  ```elixir
  forward "/graphql", GraphQL.Plug.Endpoint, schema: {MyApp.Schema, :schema}
  ```

  You may want to look at how `GraphQL.Plug` configures its pipeline.
  Specifically note how `Plug.Parsers` are configured, as this is required
  for pre-parsing the various POST bodies depending on `content-type`.
  """

  import Plug.Conn
  alias Plug.Conn
  alias GraphQL.Plug.ConfigurableValue
  alias GraphQL.Plug.Parameter

  @behaviour Plug

  def init(opts) do
    # NOTE: This code needs to be kept in sync with
    #       GraphQL.Plug.GraphiQL and GraphQL.Plugs.Endpoint as the
    #       returned data structure is shared.
    schema = case Keyword.get(opts, :schema) do
      {mod, func} -> apply(mod, func, [])
      s           -> s
    end

    root_value    = Keyword.get(opts, :root_value, %{})
    query         = Keyword.get(opts, :query, nil)

    [
      schema:     schema,
      root_value: root_value,
      query:      query
    ]
  end

  def call(%Conn{method: m} = conn, opts) when m in ["GET", "POST"] do
    args = extract_arguments(conn, opts)
    handle_call(conn, args)
  end

  def call(%Conn{method: _} = conn, _) do
    handle_error(conn, "GraphQL only supports GET and POST requests.")
  end

  def extract_arguments(conn, opts) do
    query           = Parameter.query(conn) ||
                      ConfigurableValue.evaluate(conn, opts[:query], nil)
    variables       = Parameter.variables(conn)
    operation_name  = Parameter.operation_name(conn)
    root_value      = ConfigurableValue.evaluate(conn, opts[:root_value], %{})

    %{
      query:          query,
      variables:      variables,
      operation_name: operation_name,
      root_value:     root_value,
      schema:         opts[:schema]
    }
  end

  def handle_error(conn, message) do
    {:ok, errors} = Poison.encode(%{errors: [%{message: message}]})
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, errors)
  end

  def handle_call(conn, %{query: nil}) do
    handle_error(conn, "Must provide query string.")
  end
  def handle_call(conn, args) do
    conn
    |> put_resp_content_type("application/json")
    |> execute(args)
  end

  defp execute(conn, args) do
    case GraphQL.execute(args.schema, args.query, args.root_value, args.variables, args.operation_name) do
      {:ok, data} ->
        case Poison.encode(data) do
          {:ok, json}      -> send_resp(conn, 200, json)
          {:error, errors} -> send_resp(conn, 500, errors)
        end
      {:error, errors} ->
        case Poison.encode(errors) do
          {:ok, json}      -> send_resp(conn, 400, json)
          {:error, errors} -> send_resp(conn, 400, errors)
        end
    end
  end
end
