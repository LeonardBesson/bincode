defmodule Bincode.TestUtils do
  @moduledoc """
  Utilities to remove boilerplate in tests
  """
  defmacro test_serialization(input, output, type) do
    title = "#{inspect(type)} serialization (#{inspect(input)})"

    quote do
      test unquote(title) do
        assert {:ok, serialized} = Bincode.serialize(unquote(input), unquote(type))
        assert serialized == unquote(output)
        assert Bincode.deserialize(serialized, unquote(type)) == {:ok, {unquote(input), ""}}
      end
    end
  end

  defmacro test_serialization_fail(input, output, type) do
    title = "#{inspect(type)} serialization fail (#{inspect(input)})"

    quote do
      test unquote(title) do
        assert {:error, _} = Bincode.serialize(unquote(input), unquote(type))
        assert {:error, _} = Bincode.deserialize(unquote(output), unquote(type))
      end
    end
  end
end
