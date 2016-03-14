defmodule GraphQL.Plug.ParametersTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias GraphQL.Plug.Parameters
  doctest GraphQL.Plug.Parameters

  # Parameters.operation
  test "retrieves operation as the operation_name parameter" do
    operation = conn(:GET, "/graphql", operation_name: "foo")
                |> Parameters.operation_name

    assert "foo" === operation
  end

  test "retrieves operation as the operationName parameter" do
    operation = conn(:GET, "/graphql", operationName: "foo")
                |> Parameters.operation_name

    assert "foo" === operation
  end

  test "retrieves nil operation when empty string" do
    operation = conn(:GET, "/graphql", operation_name: "")
                |> Parameters.operation_name

    assert nil === operation
  end

  test "retrieves nil operation when nil" do
    operation = conn(:GET, "/graphql", operation_name: nil)
                |> Parameters.operation_name

    assert nil === operation
  end

  test "retrieves nil operation when white space" do
    operation = conn(:GET, "/graphql", operation_name: "  ")
                |> Parameters.operation_name

    assert nil === operation
  end

  test "retrieves nil operation when not specified" do
    operation = conn(:GET, "/graphql", nil)
                |> Parameters.operation_name

    assert nil === operation
  end

  # Parameters.query

  test "retrieves query as the query parameter" do
    query = conn(:GET, "/graphql", query: "foo")
            |> Parameters.query

    assert "foo" === query
  end

  test "retrieves nil query when empty string" do
    query = conn(:GET, "/graphql", query: "")
            |> Parameters.query

    assert nil === query
  end

  test "retrieves nil query when nil" do
    query = conn(:GET, "/graphql", query: nil)
            |> Parameters.query

    assert nil === query
  end

  test "retrieves nil query when white space" do
    query = conn(:GET, "/graphql", query: "  ")
                |> Parameters.query

    assert nil === query
  end

  test "retrieves nil query when not specified" do
    query = conn(:GET, "/graphql", nil)
                |> Parameters.query

    assert nil === query
  end

  # Parameters.variables
  test "returns empty map when no variables" do
    variables = conn(:GET, "/graphql", nil)
                |> Parameters.variables

    assert %{} == variables
  end

  test "returns empty map when invalid JSON" do
    variables = conn(:GET, "/graphql", variables: "{id}")
                |> Parameters.variables

    assert %{} == variables
  end

  test "returns map when valid JSON" do
    variables = conn(:GET, "/graphql", variables: ~S({"id" : "5"}))
                |> Parameters.variables

    assert %{"id" => "5"} == variables
  end

  test "returns map when is a map" do
    variables = conn(:GET, "/graphql", variables: %{id: 5})
                |> Parameters.variables

    assert %{"id" => 5} == variables
  end
end
