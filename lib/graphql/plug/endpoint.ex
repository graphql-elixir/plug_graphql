defmodule GraphQL.Plug.Endpoint do
  import Plug.Conn
  alias Plug.Conn

  @behaviour Plug

  def init(opts) do
    schema = case Keyword.get(opts, :schema) do
      {mod, func} -> apply(mod, func, [])
      s -> s
    end
    root_value = Keyword.get(opts, :root_value, %{})
    %{root_value: root_value, schema: schema}
  end

  def call(%Conn{method: m} = conn, opts) when m in ["GET", "POST"] do
    %{root_value: root_value, schema: schema} = conn.assigns[:graphql_options] || opts

    query = query(conn)
    evaluated_root_value = evaluate_root_value(conn, root_value)
    cond do
      query && use_graphiql?(conn) -> handle_graphiql_call(conn, schema, evaluated_root_value, query)
      query -> handle_call(conn, schema, evaluated_root_value, query)
      true -> handle_error(conn, "Must provide query string.")
    end
  end

  def call(%Conn{method: _} = conn, _) do
    handle_error(conn, "GraphQL only supports GET and POST requests.")
  end

  defp handle_call(conn, schema, root_value, query) do
    conn
    |> put_resp_content_type("application/json")
    |> execute(schema, root_value, query)
  end

  defp handle_graphiql_call(conn, schema, root_value, query) do
    {:ok, data} = GraphQL.execute(schema, query, root_value)
    {:ok, result} = Poison.encode(%{data: data})
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, graphiql_html(query, nil, result))
  end

  defp handle_error(conn, message) do
    {:ok, errors} = Poison.encode %{errors: [%{message: message}]}
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, errors)
  end

  defp execute(conn, schema, root_value, query) do

    case GraphQL.execute(schema, query, root_value) do
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

  defp evaluate_root_value(conn, {mod, func}) do
    apply(mod, func, [conn])
  end

  defp evaluate_root_value(conn, root_value) when is_function(root_value, 1) do
    apply(root_value, [conn])
  end

  defp evaluate_root_value(_, nil) do
    %{}
  end

  defp evaluate_root_value(_, root_value) do
    root_value
  end

  defp query(%Conn{params: %{"query" => query}}) do
    if query && String.strip(query) != "", do: query, else: nil
  end

  defp query(_) do
    nil
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

  @graphiql_version "0.4.4"
  defp graphiql_html(query, variables \\ "", result) do
    """
    <!--
    The request to this GraphQL server provided the header "Accept: text/html"
    and as a result has been presented GraphiQL - an in-browser IDE for
    exploring GraphQL.

    If you wish to receive JSON, provide the header "Accept: application/json" or
    add "&raw" to the end of the URL within a browser.
    -->
    <!DOCTYPE html>
    <html>
    <head>
      <link href="//cdn.jsdelivr.net/graphiql/#{@graphiql_version}/graphiql.css" rel="stylesheet" />
      <script src="//cdn.jsdelivr.net/fetch/0.9.0/fetch.min.js"></script>
      <script src="//cdn.jsdelivr.net/react/0.14.2/react.min.js"></script>
      <script src="//cdn.jsdelivr.net/react/0.14.2/react-dom.min.js"></script>
      <script src="//cdn.jsdelivr.net/graphiql/#{@graphiql_version}/graphiql.js"></script>
    </head>
    <body>
      <script>
        // Collect the URL parameters
        var parameters = {};
        window.location.search.substr(1).split('&').forEach(function (entry) {
          var eq = entry.indexOf('=');
          if (eq >= 0) {
            parameters[decodeURIComponent(entry.slice(0, eq))] =
              decodeURIComponent(entry.slice(eq + 1));
          }
        });

        // Produce a Location query string from a parameter object.
        function locationQuery(params) {
          return '?' + Object.keys(params).map(function (key) {
            return encodeURIComponent(key) + '=' +
              encodeURIComponent(params[key]);
          }).join('&');
        }

        // Derive a fetch URL from the current URL, sans the GraphQL parameters.
        var graphqlParamNames = {
          query: true,
          variables: true,
          operationName: true
        };

        var otherParams = {};
        for (var k in parameters) {
          if (parameters.hasOwnProperty(k) && graphqlParamNames[k] !== true) {
            otherParams[k] = parameters[k];
          }
        }
        var fetchURL = locationQuery(otherParams);

        // Defines a GraphQL fetcher using the fetch API.
        function graphQLFetcher(graphQLParams) {
          return fetch(fetchURL, {
            method: 'post',
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json'
            },
            body: JSON.stringify(graphQLParams),
            credentials: 'include',
          }).then(function (response) {
            return response.json();
          });
        }

        // When the query and variables string is edited, update the URL bar so
        // that it can be easily shared.
        function onEditQuery(newQuery) {
          parameters.query = newQuery;
          updateURL();
        }

        function onEditVariables(newVariables) {
          parameters.variables = newVariables;
          updateURL();
        }

        function updateURL() {
          history.replaceState(null, null, locationQuery(parameters));
        }

        console.log("#{query}")
        // Render <GraphiQL /> into the body.
        React.render(
          React.createElement(GraphiQL, {
            fetcher: graphQLFetcher,
            onEditQuery: onEditQuery,
            onEditVariables: onEditVariables,
            query: '#{query}',
            response: '#{result}',
            variables: '#{variables}'
          }),
          document.body
        );
      </script>
    </body>
    </html>
    """
  end
end
