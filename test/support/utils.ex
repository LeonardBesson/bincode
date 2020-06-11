defmodule Bincode.TestUtils do
  @moduledoc """
  Utilities to remove boilerplate in tests
  """
  defmacro test_serialization(input, output, type) do
    quote do
      test "#{inspect(unquote(type))} serialization (#{inspect(unquote(input))})" do
        assert {:ok, serialized} = Bincode.serialize(unquote(input), unquote(type))
        assert Bincode.serialize!(unquote(input), unquote(type)) == serialized
        assert serialized == unquote(output)
        assert Bincode.deserialize(serialized, unquote(type)) == {:ok, {unquote(input), ""}}
        assert Bincode.deserialize!(serialized, unquote(type)) == {unquote(input), ""}
      end
    end
  end

  defmacro test_serialization_fail(input, output, type) do
    quote do
      test "#{inspect(unquote(type))} serialization fail (#{inspect(unquote(input))})" do
        assert {:error, _} = Bincode.serialize(unquote(input), unquote(type))
        assert_raise(ArgumentError, fn -> Bincode.serialize!(unquote(input), unquote(type)) end)
        assert {:error, _} = Bincode.deserialize(unquote(output), unquote(type))

        assert_raise(ArgumentError, fn -> Bincode.deserialize!(unquote(output), unquote(type)) end)
      end
    end
  end

  defmacro test_struct_serialization(struct, binary) do
    quote do
      test to_string(unquote(struct).__struct__) do
        struct_module = unquote(struct).__struct__
        assert {:ok, unquote(binary)} = struct_module.serialize(unquote(struct))
        assert {:ok, {unquote(struct), ""}} = struct_module.deserialize(unquote(binary))
      end
    end
  end
end
