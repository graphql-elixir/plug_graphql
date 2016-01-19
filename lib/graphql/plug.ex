defmodule GraphQL.Plug do
  use Plug.Builder

  plug Plug.Parsers,
    parsers: [:graphql, :urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug GraphQL.Plug.Endpoint
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
