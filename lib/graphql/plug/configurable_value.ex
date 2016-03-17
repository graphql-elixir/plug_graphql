defmodule GraphQL.Plug.ConfigurableValue do
  @moduledoc """
  This module provides the functions that are used for
  evaluating configuration options that can be set as
  raw strings, or functions in the form of {_ModuleName_, _:function_}
  or in the syntax of _&ModuleName.function/arity_

  In order for a function to be callable it needs to be
  an arity of 1 accepting a `Plug.Conn`.
  """

  alias Plug.Conn

  @type t :: {module, atom} | (Conn.t -> Map) | Map | nil
  @spec evaluate(Conn.t, t, any) :: Map

  @error_msg "Configured function must only be arity of 1 that accepts a value of Plug.Conn"

  def evaluate(conn, {mod, func}, _) do
    if :erlang.function_exported(mod, func, 1) do
      apply(mod, func, [conn])
    else
      raise @error_msg
    end
  end

  def evaluate(conn, root_fn, _) when is_function(root_fn, 1) do
    apply(root_fn, [conn])
  end

  def evaluate(_, root_fn, _) when is_function(root_fn) do
    raise @error_msg
  end

  def evaluate(_, nil, default) do
    default
  end

  def evaluate(_, root_value, _) do
    root_value
  end
end
