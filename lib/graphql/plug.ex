defmodule GraphQL.Plug do
  @moduledoc """
  This is the primary plug for mounting a GraphQL server.

  It includes GraphiQL support and a default pipeline
  which parses various content-types for POSTs
  (including `application/graphql`, `application/json`, form and multipart).

  You mount `GraphQL.Plug` using Plug or Phoenix, and pass it your schema:

  ```elixir
  forward "/graphql", GraphQL.Plug, schema: {MyApp.Schema, :schema}
  ```

  You can build your own pipeline by mounting the
  `GraphQL.Plug.Endpoint` plug directly. You may want to preserve how this
  pipeline configures the `Plug.Parsers` in that case.
  """

  use Plug.Builder

  require Logger

  plug Plug.Parsers,
    parsers: [:graphql, :urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  def init(opts) do
    opts
    |> GraphQL.Plug.Endpoint.init
    |> allow_graphiql?
  end

  def call(conn, opts) do
    # TODO use private
    conn = assign(conn, :graphql_options, opts)
    conn = super(conn, opts)

    conn = if opts.allow_graphiql? do
      GraphQL.Plug.GraphiQL.call(conn, opts)
    else
      GraphQL.Plug.Endpoint.call(conn, opts)
    end

    # TODO consider not logging instrospection queries
    Logger.debug """
    Processed GraphQL query:

    #{conn.params["query"]}
    """

    conn
  end

  defp allow_graphiql?(opts) do
    config = Application.get_env(:plug_graphql, __MODULE__, [])
    allow? = Keyword.get(config, :allow_graphiql, false)
    Map.merge(opts, %{allow_graphiql?: allow?})
  end
end
