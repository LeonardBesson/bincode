defmodule Bincode.TestUtils do
  @moduledoc """
  Utilities to remove boilerplate in tests
  """
  defmacro test_serialization(input, output, type, opts \\ []) do
    quote do
      test "#{inspect(unquote(type))} serialization (#{inspect(unquote(input))})" do
        assert {:ok, serialized} = Bincode.serialize(unquote(input), unquote(type), unquote(opts))
        assert Bincode.serialize!(unquote(input), unquote(type), unquote(opts)) == serialized
        assert serialized == unquote(output)

        assert Bincode.deserialize(serialized, unquote(type), unquote(opts)) ==
                 {:ok, {unquote(input), ""}}

        assert Bincode.deserialize!(serialized, unquote(type), unquote(opts)) ==
                 {unquote(input), ""}
      end
    end
  end

  defmacro test_serialization_fail(input, output, type, opts \\ []) do
    quote do
      test "#{inspect(unquote(type))} serialization fail (#{inspect(unquote(input))})" do
        assert {:error, _} = Bincode.serialize(unquote(input), unquote(type), unquote(opts))

        assert_raise(ArgumentError, fn ->
          Bincode.serialize!(unquote(input), unquote(type), unquote(opts))
        end)

        assert {:error, _} = Bincode.deserialize(unquote(output), unquote(type), unquote(opts))

        assert_raise(ArgumentError, fn ->
          Bincode.deserialize!(unquote(output), unquote(type), unquote(opts))
        end)
      end
    end
  end

  defmacro test_struct_serialization(struct, binary, opts \\ []) do
    quote do
      test "#{to_string(unquote(struct).__struct__)} (#{inspect(unquote(binary))})" do
        struct_module = unquote(struct).__struct__

        assert {:ok, unquote(binary)} =
                 Bincode.serialize(unquote(struct), struct_module, unquote(opts))

        assert Bincode.serialize!(unquote(struct), struct_module, unquote(opts)) ==
                 unquote(binary)

        assert {:ok, {unquote(struct), ""}} =
                 Bincode.deserialize(unquote(binary), struct_module, unquote(opts))

        assert {unquote(struct), ""} =
                 Bincode.deserialize!(unquote(binary), struct_module, unquote(opts))
      end
    end
  end

  defmacro test_struct_serialization_fail(struct_module, input, output, opts \\ []) do
    quote do
      test "#{to_string(unquote(struct_module))} fail (#{inspect(unquote(input))})" do
        assert {:error, _} =
                 Bincode.serialize(unquote(input), unquote(struct_module), unquote(opts))

        assert_raise(ArgumentError, fn ->
          Bincode.serialize!(unquote(input), unquote(struct_module), unquote(opts))
        end)

        assert {:error, _} =
                 Bincode.deserialize(unquote(output), unquote(struct_module), unquote(opts))

        assert_raise(ArgumentError, fn ->
          Bincode.deserialize!(unquote(output), unquote(struct_module), unquote(opts))
        end)
      end
    end
  end
end
