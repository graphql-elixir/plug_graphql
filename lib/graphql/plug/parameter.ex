defmodule GraphQL.Plug.Parameter do
  @moduledoc """
  This module provides the functions for parsing out a parameter
  value from `Plug.Conn`
  """

  alias Plug.Conn

  @spec operation_name(Conn.t) :: String.t
  def operation_name(conn) do
    conn
    |> operation_name_params
    |> cleanup_string
  end

  @spec query(Conn.t) :: String.t | nil
  def query(conn) do
    conn.params
    |> Map.get("query")
    |> cleanup_string
  end

  @spec variables(Conn.t) :: Map
  def variables(conn) do
    decode_variables(Map.get(conn.params, "variables", %{}))
  end

  defp cleanup_string(s) do
    if s && String.strip(s) != "", do: s, else: nil
  end

  defp operation_name_params(conn) do
    Map.get(conn.params, "operationName") ||
    Map.get(conn.params, "operation_name")
  end

  defp decode_variables(values) when is_binary(values) do
    case Poison.decode(values) do
      {:ok, values} -> values
      {:error, _} -> %{} # express-graphql ignores these errors currently
    end
  end
  defp decode_variables(vars), do: vars
end
