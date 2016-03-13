defmodule GraphQL.Plug.GraphiQL do
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
  alias GraphQL.Plug.Endpoint
  alias GraphQL.Plug.FunctionalValue
  alias GraphQL.Plug.Parameters

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
    GraphQL.Plug.init(opts)
  end

  def call(%Conn{method: m} = conn, opts) when m in ["GET", "POST"] do
    %{schema: schema, root_value: root_value, query: query} = conn.assigns[:graphql_options] || opts

    query = Parameters.query(conn) || FunctionalValue.evaluate(conn, query, nil)
    variables = Parameters.variables(conn)
    operation_name = Parameters.operation_name(conn)
    evaluated_root_value = FunctionalValue.evaluate(conn, root_value, %{})

    cond do
      use_graphiql?(conn) ->
        handle_graphiql_call(conn, schema, evaluated_root_value, query, variables, operation_name)
      query ->
        Endpoint.handle_call(conn, schema, evaluated_root_value, query, variables, operation_name)
      true ->
        Endpoint.handle_error(conn, "Must provide query string.")
    end
  end

  def call(%Conn{method: _} = conn, _) do
    Endpoint.handle_error(conn, "GraphQL only supports GET and POST requests.")
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

  def use_graphiql?(%Conn{method: "GET"} = conn) do
    accept_headers = get_req_header(conn, "accept")

    case accept_headers do
      [accept_header | _] ->
        IO.inspect accept_header
        String.contains?(accept_header, "text/html") &&
        !Map.has_key?(conn.params, "raw")
      _ ->
        false
    end
  end
  def use_graphiql?(_), do: false
end
