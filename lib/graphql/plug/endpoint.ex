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

  This plug currently includes _GraphiQL_ support but this should end
  up in it's own plug.
  """

  import Plug.Conn
  alias Plug.Conn

  @behaviour Plug

  @graphiql_version "0.4.9"
  @graphiql_instructions """
  # Welcome to GraphQL Elixir!
  #
  # GraphiQL is an in-browser IDE for writing, validating, and
  # testing GraphQL queries.
  #
  # Type queries into this side of the screen, and you will
  # see intelligent typeaheads aware of the current GraphQL type schema and
  # live syntax and validation errors highlighted within the text.
  #
  # To bring up the auto-complete at any point, just press Ctrl-Space.
  #
  # Press the run button above, or Cmd-Enter to execute the query, and the result
  # will appear in the pane to the right.
  """

  # Load GraphiQL HTML view
  require EEx
  EEx.function_from_file :defp, :graphiql_html,
    Path.absname(Path.relative_to_cwd("templates/graphiql.eex")),
    [:graphiql_version, :query, :variables, :result]

  def init(opts) do
    schema = case Keyword.get(opts, :schema) do
      {mod, func} -> apply(mod, func, [])
      s -> s
    end
    root_value = Keyword.get(opts, :root_value, %{})
    %{schema: schema, root_value: root_value}
  end

  def call(%Conn{method: m} = conn, opts) when m in ["GET", "POST"] do
    if conn.assigns[:graphql_options] do
      opts = Map.merge(opts, conn.assigns[:graphql_options])
    end
    %{schema: schema, root_value: root_value} = opts

    query = query(conn)
    variables = variables(conn)
    operation_name = operation_name(conn)
    evaluated_root_value = evaluate_root_value(conn, root_value)

    cond do
      use_graphiql?(conn) ->
        handle_graphiql_call(conn, schema, evaluated_root_value, query, variables, operation_name)
      query ->
        handle_call(conn, schema, evaluated_root_value, query, variables, operation_name)
      true ->
        handle_error(conn, "Must provide query string.")
    end
  end

  def call(%Conn{method: _} = conn, _) do
    handle_error(conn, "GraphQL only supports GET and POST requests.")
  end

  defp handle_call(conn, schema, root_value, query, variables, operation_name) do
    conn
    |> put_resp_content_type("application/json")
    |> execute(schema, root_value, query, variables, operation_name)
  end

  defp escape_string(s) do
    s
    |> String.replace(~r/\n/, "\\n")
    |> String.replace(~r/'/, "\\'")
  end

  defp handle_graphiql_call(conn, schema, root_value, query, variables, operation_name) do
    # TODO construct a simple query from the schema (ie `schema.query.fields[0].fields[0..5]`)
    query = query || @graphiql_instructions <> "\n{\n\tfield\n}\n"
    {_, data} = GraphQL.execute(schema, query, root_value, variables, operation_name)
    {:ok, variables} = Poison.encode(variables, pretty: true)
    {:ok, result}    = Poison.encode(data, pretty: true)
    graphiql = graphiql_html(@graphiql_version, escape_string(query), escape_string(variables), escape_string(result))
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, graphiql)
  end

  defp handle_error(conn, message) do
    {:ok, errors} = Poison.encode %{errors: [%{message: message}]}
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, errors)
  end

  defp execute(conn, schema, root_value, query, variables, operation_name) do
    case GraphQL.execute(schema, query, root_value, variables, operation_name) do
      {:ok, data} ->
        case Poison.encode(data) do
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

  defp evaluate_root_value(conn, {mod, func}) do
    apply(mod, func, [conn])
  end

  defp evaluate_root_value(conn, root_fn) when is_function(root_fn, 1) do
    apply(root_fn, [conn])
  end

  defp evaluate_root_value(_, nil) do
    %{}
  end

  defp evaluate_root_value(_, root_value) do
    root_value
  end

  defp query(conn) do
    query = Map.get(conn.params, "query")
    if query && String.strip(query) != "", do: query, else: nil
  end

  defp variables(conn) do
    decode_variables Map.get(conn.params, "variables", %{})
  end

  defp decode_variables(variables) when is_binary(variables) do
    case Poison.decode(variables) do
      {:ok, variables} -> variables
      {:error, _} -> %{} # express-graphql ignores these errors currently
    end
  end
  defp decode_variables(vars), do: vars

  defp operation_name(conn) do
    Map.get(conn.params, "operationName") ||
    Map.get(conn.params, "operation_name")
  end

  defp use_graphiql?(conn) do
    case get_req_header(conn, "accept") do
      [accept_header | _] ->
        String.contains?(accept_header, "text/html") &&
        !Map.has_key?(conn.params, "raw")
      _ ->
        false
    end
  end
end
