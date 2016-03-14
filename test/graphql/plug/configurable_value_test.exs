defmodule GraphQL.Plug.ConfigurableValueTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias GraphQL.Plug.ConfigurableValue
  doctest GraphQL.Plug.ConfigurableValue

  defmodule Config do
    def foo(arg), do: arg
    def bar(arg, _), do: arg
  end

  test "returns default when no value is configured" do
    value = %{}
            |> ConfigurableValue.evaluate(nil, :default)

    assert :default === value
  end

  test "executes {module, fun} function" do
    value = %{}
            |> ConfigurableValue.evaluate({Config, :foo}, :default)

    assert %{} === value
  end

  test "executes &mod.fun/1 when configured" do
    value = %{}
            |> ConfigurableValue.evaluate(&Config.foo/1, :default)

    assert %{} === value
  end

  test "raises error when function does not accept 1 arg" do
    assert_raise(
      RuntimeError,
      "Configured function must only be arity of 1 that accepts a value of Plug.Conn",
      fn ->
        %{}
        |> ConfigurableValue.evaluate(&Config.bar/2, :default)
      end)
  end

  test "raises error when {mod, fun} is not arity/1" do
    # TODO: This should have a better error messsage as this is not useful
    assert_raise(
      UndefinedFunctionError,
      "undefined function GraphQL.Plug.ConfigurableValueTest.Config.bar/1",
      fn ->
        %{}
        |> ConfigurableValue.evaluate({Config, :bar}, :default)
      end)
  end

  test "returns configured value" do
    data = %{foo: "bar"}
    value = %{}
            |> ConfigurableValue.evaluate(data, :default)

    assert data === value
  end
end
