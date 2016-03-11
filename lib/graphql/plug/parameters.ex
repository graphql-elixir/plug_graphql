defmodule GraphQL.Plug.Parameters do
  @moduledoc """
  This module provides the functions for parsing out parameters
  from a `Plug.Conn`
  """
  
  @spec operation_name(Plug.Conn.t) :: String.t
  def operation_name(conn) do
    Map.get(conn.params, "operationName") ||
    Map.get(conn.params, "operation_name")
  end

  @spec query(Plug.Conn.t) :: String.t | nil
  def query(conn) do
    query = Map.get(conn.params, "query")
    if query && String.strip(query) != "", do: query, else: nil
  end

  @spec variables(Plug.Conn.t) :: Map
  def variables(conn) do
    decode_variables Map.get(conn.params, "variables", %{})
  end

  defp decode_variables(variables) when is_binary(variables) do
    case Poison.decode(variables) do
      {:ok, variables} -> variables
      {:error, _} -> %{} # express-graphql ignores these errors currently
    end
  end
  defp decode_variables(vars), do: vars

end
