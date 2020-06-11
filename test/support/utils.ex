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
      test "#{to_string(unquote(struct).__struct__)} (#{inspect(unquote(binary))})" do
        struct_module = unquote(struct).__struct__
        assert {:ok, unquote(binary)} = Bincode.serialize(unquote(struct), struct_module)
        assert Bincode.serialize!(unquote(struct), struct_module) == unquote(binary)
        assert {:ok, {unquote(struct), ""}} = Bincode.deserialize(unquote(binary), struct_module)
        assert {unquote(struct), ""} = Bincode.deserialize!(unquote(binary), struct_module)
      end
    end
  end

  defmacro test_struct_serialization_fail(struct_module, input, output) do
    quote do
      test "#{to_string(unquote(struct_module))} fail (#{inspect(unquote(input))})" do
        assert {:error, _} = Bincode.serialize(unquote(input), unquote(struct_module))

        assert_raise(ArgumentError, fn ->
          Bincode.serialize!(unquote(input), unquote(struct_module))
        end)

        assert {:error, _} = Bincode.deserialize(unquote(output), unquote(struct_module))

        assert_raise(ArgumentError, fn ->
          Bincode.deserialize!(unquote(output), unquote(struct_module))
        end)
      end
    end
  end
end
