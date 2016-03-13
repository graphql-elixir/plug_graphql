defmodule GraphQL.Plug.FunctionalValue do
  @moduledoc """
  This module provides the functions that are used for
  evaluating the root value in the Plug prior to submitting
  the query for execution.
  """
  @type evaluated_value :: {module, atom} | (Plug.Conn.t -> Map) | Map | nil
  @spec evaluate(Plug.Conn.t, evaluated_value, any) :: Map

  def evaluate(conn, {mod, func}, _default) do
    apply(mod, func, [conn])
  end

  def evaluate(conn, root_fn, _default) when is_function(root_fn, 1) do
    apply(root_fn, [conn])
  end

  def evaluate(_, nil, default) do
    default
  end

  def evaluate(_, root_value, _default) do
    root_value
  end
end
