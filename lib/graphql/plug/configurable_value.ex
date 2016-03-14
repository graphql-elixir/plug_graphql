defmodule GraphQL.Plug.ConfigurableValue do
  @moduledoc """
  This module provides the functions that are used for
  evaluating configuration options that can be set as
  raw strings, or functions in the form of {_ModuleName_, _:function_}
  or in the syntax of _&ModuleName.function/arity_
  """

  @type t :: {module, atom} | (Plug.Conn.t -> Map) | Map | nil
  @spec evaluate(Plug.Conn.t, t, any) :: Map

  def evaluate(conn, {mod, func}, _) do
    apply(mod, func, [conn])
  end

  def evaluate(conn, root_fn, _) when is_function(root_fn, 1) do
    apply(root_fn, [conn])
  end

  def evaluate(_, root_fn, _) when is_function(root_fn) do
    raise "Configured function must only be arity of 1 that accepts a value of Plug.Conn"
  end

  def evaluate(_, nil, default) do
    default
  end

  def evaluate(_, root_value, _) do
    root_value
  end
end
