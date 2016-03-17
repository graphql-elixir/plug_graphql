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

  @type init :: %{
    schema: GraphQL.Schema.t,
    root_value: ConfigurableValue.t,
    query:  ConfigurableValue.t,
    allow_graphiql?: true | false
  }

  @spec init(Map) :: init
  def init(opts) do
    graphiql = GraphQL.Plug.GraphiQL.init(opts)
    endpoint = GraphQL.Plug.Endpoint.init(opts)

    opts = Keyword.merge(graphiql, endpoint)
    Enum.dedup(opts)
  end

  def call(conn, opts) do
    conn = super(conn, opts)

    conn = if GraphQL.Plug.GraphiQL.use_graphiql?(conn, opts) do
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
end
