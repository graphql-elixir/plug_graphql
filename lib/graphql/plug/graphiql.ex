defmodule GraphQL.Plug.GraphiQL do
  @moduledoc """
  This is the GraphiQL plug for mounting a GraphQL server.

  You can build your own pipeline by mounting the
  `GraphQL.Plug.GraphiQL` plug directly.

  ```elixir
  forward "/graphql", GraphQL.Plug.GraphiQL, schema: {MyApp.Schema, :schema}
  ```

  You may want to look at how `GraphQL.Plug` configures its pipeline.
  Specifically note how `Plug.Parsers` are configured, as this is required
  for pre-parsing the various POST bodies depending on `content-type`.
  """
  import Plug.Conn
  alias Plug.Conn
  alias GraphQL.Plug.Endpoint
  alias GraphQL.Plug.ConfigurableValue
  alias GraphQL.Plug.Parameter

  @behaviour Plug

  @graphiql_version "0.6.1"
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
    allow_graphiql? = Keyword.get(opts, :allow_graphiql?, true)

    GraphQL.Plug.Endpoint.init(opts) ++ [allow_graphiql?: allow_graphiql?]
  end

  def call(%Conn{method: m} = conn, opts) when m in ["GET", "POST"] do
    query           = Parameter.query(conn) ||
                      ConfigurableValue.evaluate(conn, opts[:query], nil)
    variables       = Parameter.variables(conn)
    operation_name  = Parameter.operation_name(conn)
    root_value      = ConfigurableValue.evaluate(conn, opts[:root_value], %{})

    cond do
      use_graphiql?(conn, opts) ->
        handle_graphiql_call(conn, opts[:schema], root_value, query, variables, operation_name)
      query ->
        Endpoint.handle_call(conn, opts[:schema], root_value, query, variables, operation_name)
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

  def use_graphiql?(%Conn{method: "GET"} = conn, opts) do
    case opts[:allow_graphiql?] && get_req_header(conn, "accept") do
      [accept_header | _] ->
        String.contains?(accept_header, "text/html") &&
        !Map.has_key?(conn.params, "raw")
      _ ->
        false
    end
  end
  def use_graphiql?(_, _), do: false
end
