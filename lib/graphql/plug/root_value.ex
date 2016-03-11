defmodule GraphQL.Plug.RootValue do
  @moduledoc """
  This module provides the functions that are used for
  evaluating the root value in the Plug prior to submitting
  the query for execution.
  """
  @type root_value :: {module, atom} | (Plug.Conn.t -> Map) | Map | nil
  @spec evaluate(Plug.Conn.t, root_value) :: Map

  def evaluate(conn, {mod, func}) do
    apply(mod, func, [conn])
  end

  def evaluate(conn, root_fn) when is_function(root_fn, 1) do
    apply(root_fn, [conn])
  end

  def evaluate(_, nil) do
    %{}
  end

  def evaluate(_, root_value) do
    root_value
  end
end
