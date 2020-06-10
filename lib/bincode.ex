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

  # Signed
  for int_type <- [:i8, :i16, :i32, :i64, :i128] do
    {size, ""} = to_string(int_type) |> String.trim_leading("i") |> Integer.parse()

    def serialize(value, unquote(int_type)) when is_integer(value) do
      {:ok, <<value::little-integer-signed-size(unquote(size))>>}
    end

    def deserialize(
          <<value::little-integer-signed-size(unquote(size)), rest::binary>>,
          unquote(int_type)
        ) do
      {:ok, {value, rest}}
    end
  end

  # Float
  for float_type <- [:f32, :f64] do
    {size, ""} = to_string(float_type) |> String.trim_leading("f") |> Integer.parse()

    def serialize(value, unquote(float_type)) when is_float(value) do
      {:ok, <<value::little-float-size(unquote(size))>>}
    end

    def deserialize(
          <<value::little-float-size(unquote(size)), rest::binary>>,
          unquote(float_type)
        ) do
      {:ok, {value, rest}}
    end
  end

  # Bool
  for boolean <- [true, false] do
    v = if boolean, do: 1, else: 0

    def serialize(unquote(boolean), :bool) do
      {:ok, <<unquote(v)::size(8)>>}
    end

    def deserialize(<<unquote(v)::size(8), rest::binary>>, :bool) do
      {:ok, {unquote(boolean), rest}}
    end
  end

  # String
  def serialize(value, :string) when is_binary(value) do
    {:ok, <<byte_size(value)::little-integer-size(64), value::binary>>}
  end

  def deserialize(
        <<string_size::little-integer-size(64), content::binary-size(string_size), rest::binary>>,
        :string
      ) do
    {:ok, {content, rest}}
  end

  # List
  def serialize(list, {:list, inner}) when is_list(list) do
    serialize(list, 0, <<>>, {:list, inner})
  end

  defp serialize([], length, result, {:list, inner}) do
    {:ok, <<length::little-integer-size(64), IO.iodata_to_binary(result)::binary>>}
  end

  defp serialize([head | tail], length, result, {:list, inner}) do
    case serialize(head, inner) do
      {:ok, serialized} ->
        result = [result, serialized]
        serialize(tail, length + 1, result, {:list, inner})

      {:error, msg} ->
        {:error, msg}
    end
  end

  def deserialize(<<size::little-integer-size(64), rest::binary>>, {:list, inner}) do
    deserialize(rest, size, [], {:list, inner})
  end

  defp deserialize(rest, 0, result, {:list, _}) do
    result = Enum.reverse(result)
    {:ok, {result, rest}}
  end

  defp deserialize(rest, remaining, result, {:list, inner}) do
    case deserialize(rest, inner) do
      {:ok, {deserialized, rest}} ->
        result = [deserialized | result]
        deserialize(rest, remaining - 1, result, {:list, inner})

      {:error, msg} ->
        {:error, msg}
    end
  end

  # Map
  def serialize(map, {:map, {key_type, value_type}}) when is_map(map) do
    serialize(map, Map.keys(map), 0, <<>>, {:map, {key_type, value_type}})
  end

  defp serialize(map, [], length, result, {:map, {key_type, value_type}}) do
    {:ok, <<length::little-integer-size(64), IO.iodata_to_binary(result)::binary>>}
  end

  defp serialize(map, [key | keys], length, result, {:map, {key_type, value_type}}) do
    case serialize(key, key_type) do
      {:ok, serialized_key} ->
        case serialize(map[key], value_type) do
          {:ok, serialized_value} ->
            result = [result, serialized_key, serialized_value]
            serialize(map, keys, length + 1, result, {:map, {key_type, value_type}})

          {:error, msg} ->
            {:error, msg}
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  def deserialize(<<size::little-integer-size(64), rest::binary>>, {:map, {key_type, value_type}}) do
    deserialize(rest, size, %{}, {:map, {key_type, value_type}})
  end

  defp deserialize(rest, 0, result, {:map, {_, _}}) do
    {:ok, {result, rest}}
  end

  defp deserialize(rest, remaining, result, {:map, {key_type, value_type}}) do
    case deserialize(rest, key_type) do
      {:ok, {deserialized_key, rest}} ->
        case deserialize(rest, value_type) do
          {:ok, {deserialized_value, rest}} ->
            result = Map.put(result, deserialized_key, deserialized_value)
            deserialize(rest, remaining - 1, result, {:map, {key_type, value_type}})

          {:error, msg} ->
            {:error, msg}
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  # Set
  def serialize(%MapSet{} = set, {:set, inner}) do
    serialize(MapSet.to_list(set), {:list, inner})
  end

  def deserialize(<<rest::binary>>, {:set, inner}) do
    case deserialize(rest, {:list, inner}) do
      {:ok, {list, rest}} -> {:ok, {MapSet.new(list), rest}}
      {:error, msg} -> {:error, msg}
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
