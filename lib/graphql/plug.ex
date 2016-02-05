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

  plug Plug.Parsers,
    parsers: [:graphql, :urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug GraphQL.Plug.Endpoint
  # TODO extract
  # plug GraphQL.Plug.GraphiQL

  # TODO remove duplication call GraphQL.Plug.Helper.extract_init_options/1 here
  def init(opts) do
    schema = case Keyword.get(opts, :schema) do
      {mod, func} -> apply(mod, func, [])
      s -> s
    end
    root_value = Keyword.get(opts, :root_value, %{})
    %{:schema => schema, :root_value => root_value}
  end

  def call(conn, opts) do
    conn = assign(conn, :graphql_options, opts)
    super(conn, opts)
  end
end
