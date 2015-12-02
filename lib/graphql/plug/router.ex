defmodule GraphQL.Plug.Router do
  use Plug.Router

  plug :match
  plug :dispatch
  # plug GraphQL.Plug.Endpoint, schema: nil

  get "/graphql" do
    GraphQL.Plug.Endpoint.call(conn, [])
  end

  match _ do
    send_resp(conn, 400, "oops")
  end
end
