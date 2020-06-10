defmodule Bincode do
  @moduledoc """
  Documentation for `Bincode`.
  """

  # Unsigned
  for int_type <- [:u8, :u16, :u32, :u64, :u128] do
    {size, ""} = to_string(int_type) |> String.trim_leading("u") |> Integer.parse()

    def serialize(value, unquote(int_type)) when value < 0 do
      raise ArgumentError,
        message:
          "Attempt to serialize negative integer #{inspect(value)} into #{unquote(int_type)}"
    end

    def serialize(value, unquote(int_type)) when is_integer(value) do
      {:ok, <<value::little-integer-size(unquote(size))>>}
    end

    def deserialize(
          <<value::little-integer-size(unquote(size)), rest::binary>>,
          unquote(int_type)
        ) do
      {:ok, {value, rest}}
    end
  end

  # Fallback
  def serialize(value, type) do
    {:error, "Cannot serialize value #{inspect(value)} into type #{inspect(type)}"}
  end

  def serialize!(value, type) do
    case serialize(value, type) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  def deserialize(value, type) do
    {:error, "Cannot deserialize value #{inspect(value)} into type #{inspect(type)}"}
  end

  def deserialize!(value, type) do
    case deserialize(value, type) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message: message
    end
  end
end
