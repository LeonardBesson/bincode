defmodule Bincode do
  @moduledoc ~S"""
  Module defining the functionalities of Bincode.

  Bincode allows you to share data between Elixir and Rust using
  Rust's [Bincode](https://github.com/servo/bincode) binary format.

  You can implement your custom serialization manually, but for most use cases
  you can simply declare the Rust structs and enums using `Bincode.Structs.declare_struct/3` and
  `Bincode.Structs.declare_enum/3`

  ## Supported types

  Most Rust types are supported, plus user defined structs and enums.

  | Rust                   | Bincode notation          | Elixir typespec                  |
  |------------------------|---------------------------|----------------------------------|
  | `u8`                   | `:u8`                     | `non_neg_integer`                |
  | ...                    | ...                       | ...                              |
  | `u128`                 | `:u128`                   | `non_neg_integer`                |
  | `i8`                   | `:i8`                     | `integer`                        |
  | ...                    | ...                       | ...                              |
  | `i128`                 | `:i128`                   | `integer`                        |
  | `f32`                  | `:f32`                    | `float`                          |
  | `f64`                  | `:f64`                    | `float`                          |
  | `bool`                 | `:bool`                   | `boolean`                        |
  | `String`               | `:string`                 | `binary`                         |
  | `(u32, String)`        | `{:u32, :string}`         | `{non_neg_integer, binary}`      |
  | `Option<f32>`          | `{:option, :f32}`         | `float \| nil`                   |
  | `Vec<String>`          | `{:list, :string}`        | `[binary]`                       |
  | `HashMap<i64, String>` | `{:map, {:i64, :string}}` | `%{required(integer) => binary}` |
  | `HashSet<u8>`          | `{:set, :u8}`             | `MapSet.t(non_neg_integer)`      |

  User defined types such as structs and enums can be nested, in this case the type is
  the fully qualified module name. See `Bincode.Structs.declare_struct/3`.

  The endianness is little since that's the default used by Bincode.
  Tuples are implemented for a max size of 12 by default. That should be enough for
  most practical cases but if you need to serialize tuples with more elements, you can
  set `max_tuple_size` in the mix config, like so:

      config :bincode, max_tuple_size: 23


  ## Examples

  Consider the typical example where we want to send data structures across the network.
  Here with a Rust client and Elixir server:

  ```rust
  #[derive(Serialize, Deserialize)]
  pub struct PacketSendMessage {
    pub from: u64,
    pub to: u64,
    pub content: String,
  }

  pub fn send_message(sender_id: u64, receiver_id: u64) {
    let message = PacketSendMessage {
        from: sender_id,
        to: receiver_id,
        content: "hello!".to_owned()
    };
    let encoded: Vec<u8> = bincode::serialize(&message).unwrap();

    // now send "encoded" to Elixir app
  }
  ```

  On the Elixir side you can simply declare the same packet struct and deserialize the received bytes:

      defmodule Packets do
        import Bincode.Structs

        declare_struct(PacketSendMessage,
          from: :u64,
          to: :u64,
          content: :string
        )
      end

      alias Packets.PacketSendMessage

      # Receive "data" from the network
      {:ok, {%PacketSendMessage{} = message, rest}} = PacketSendMessage.deserialize(data)
      Logger.info("Received message packet #{inspect(message)}")

  """
  use Bitwise

  @type unsigned :: :u8 | :u16 | :u32 | :u64 | :u128
  @type signed :: :i8 | :i16 | :i32 | :i64 | :i128
  @type floating_point :: :f32 | :f64
  @type primitive ::
          unsigned | signed | floating_point | :bool | :string | tuple | {:option, bincode_type}
  @type collection :: {:list, bincode_type} | {:map, bincode_type} | {:set, bincode_type}
  @type user_defined :: module
  @type bincode_type :: primitive | collection | user_defined

  @type option :: {:varint, boolean}
  @type options :: list(option)

  @doc """
  Serializes the given `term` in binary representation according to the
  given `type`.

  Returns `{:ok, serialized_term}` when successful or `{:error, error_message}`
  otherwise.

  ## Options

  * `varint` - When set to true, enables variable-size integer encoding. It applies to signed
  and unsigned integers except for `:u8` and `:i8`. Signed integers are first mapped to unsigned
  integers using ZigZag encoding. Variable-size encoding will result in saved bytes the closer
  to 0 the value is. This is especially true for collections length and enum variants which
  for a lot of cases fit in a single byte instead of the usual `:u64` and `:u32`.

  ## Examples

      iex> Bincode.serialize(255, :u8)
      {:ok, <<255>>}

      iex> Bincode.serialize(12, :u64)
      {:ok, <<12, 0, 0, 0, 0, 0, 0, 0>>}

      iex> Bincode.serialize(12, :u64, varint: true)
      {:ok, <<12>>}

      iex> Bincode.serialize("Bincode", :string)
      {:ok, <<7, 0, 0, 0, 0, 0, 0, 0, 66, 105, 110, 99, 111, 100, 101>>}

      iex> Bincode.serialize({144, false}, {:u16, :bool})
      {:ok, <<144, 0, 0>>}

      iex> Bincode.serialize([1, 2, 3, 4], {:list, :u8})
      {:ok, <<4, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4>>}

      iex> Bincode.serialize(%{"some string key" => 429876423428}, {:map, {:string, :u64}})
      {:ok, <<1, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 115, 111, 109, 101, 32, 115, 116, 114, 105, 110, 103, 32, 107, 101, 121, 4, 171, 161, 22, 100, 0, 0, 0>>}

      iex> Bincode.serialize(%{}, :bool)
      {:error, "Cannot serialize value %{} into type :bool"}
  """
  @spec serialize(term, bincode_type, options) :: {:ok, binary} | {:error, String.t()}
  def serialize(value, type, opts \\ [])

  @doc """
  Deserializes the given `binary` data into an Elixir term according to the
  given `type`.

  Returns `{:ok, {term, rest}}` when successful or `{:error, error_message}`
  otherwise. The remaining binary data is returned.

  ## Options

  * `varint` - When set to true, enables variable-size integer encoding. It applies to signed
  and unsigned integers except for `:u8` and `:i8`. Signed integers are first mapped to unsigned
  integers using ZigZag encoding. Variable-size encoding will result in saved bytes the closer
  to 0 the value is. This is especially true for collections length and enum variants which
  for a lot of cases fit in a single byte instead of the usual `:u64` and `:u32`.

  ## Examples
      iex> Bincode.deserialize(<<255>>, :u8)
      {:ok, {255, ""}}

      iex> Bincode.deserialize(<<12, 0, 0, 0, 0, 0, 0, 0>>, :u64)
      {:ok, {12, ""}}

      iex> Bincode.deserialize(<<12>>, :u64, varint: true)
      {:ok, {12, ""}}

      iex> Bincode.deserialize(<<7, 0, 0, 0, 0, 0, 0, 0, 66, 105, 110, 99, 111, 100, 101>>, :string)
      {:ok, {"Bincode", ""}}

      iex> Bincode.deserialize(<<144, 0, 0>>, {:u16, :bool})
      {:ok, {{144, false}, ""}}

      iex> Bincode.deserialize(<<4, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4>>, {:list, :u8})
      {:ok, {[1, 2, 3, 4], ""}}

      iex> Bincode.deserialize(<<1, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0, 0, 0, 0, 0, 0, 115, 111, 109, 101, 32, 115, 116, 114, 105, 110, 103, 32, 107, 101, 121, 4, 171, 161, 22, 100, 0, 0, 0>>, {:map, {:string, :u64}})
      {:ok, {%{"some string key" => 429876423428}, ""}}

      iex> Bincode.deserialize([], :bool)
      {:error, "Cannot deserialize value [] into type :bool"}
  """
  @spec deserialize(binary, bincode_type, options) :: {:ok, {term, binary}} | {:error, String.t()}
  def deserialize(value, type, opts \\ [])

  @u16_max 0xFFFF
  @u32_max 0xFFFF_FFFF
  @u64_max 0xFFFF_FFFF_FFFF_FFFF

  @single_byte_max 250
  @u16_byte 251
  @u32_byte 252
  @u64_byte 253
  @u128_byte 254

  defp use_varint(opts) when is_list(opts), do: Keyword.get(opts, :varint, false)

  def zigzag_encode(value) when is_integer(value) and value < 0, do: ~~~value * 2 + 1
  def zigzag_encode(value) when is_integer(value), do: value * 2

  def zigzag_decode(value) when is_integer(value) and rem(value, 2) == 0, do: div(value, 2)
  def zigzag_decode(value) when is_integer(value), do: ~~~div(value, 2)

  defp serialize_varint(value) when is_integer(value) and value <= @single_byte_max do
    {:ok, <<value::size(8)>>}
  end

  defp serialize_varint(value) when is_integer(value) and value <= @u16_max do
    {:ok, <<@u16_byte::size(8), value::little-integer-size(16)>>}
  end

  defp serialize_varint(value) when is_integer(value) and value <= @u32_max do
    {:ok, <<@u32_byte::size(8), value::little-integer-size(32)>>}
  end

  defp serialize_varint(value) when is_integer(value) and value <= @u64_max do
    {:ok, <<@u64_byte::size(8), value::little-integer-size(64)>>}
  end

  defp serialize_varint(value) when is_integer(value) do
    {:ok, <<@u128_byte::size(8), value::little-integer-size(128)>>}
  end

  defp deserialize_varint(<<byte::size(8), rest::binary>>) when byte in 0..@single_byte_max do
    {:ok, {byte, rest}}
  end

  defp deserialize_varint(<<@u16_byte::size(8), value::little-integer-size(16), rest::binary>>) do
    {:ok, {value, rest}}
  end

  defp deserialize_varint(<<@u32_byte::size(8), value::little-integer-size(32), rest::binary>>) do
    {:ok, {value, rest}}
  end

  defp deserialize_varint(<<@u64_byte::size(8), value::little-integer-size(64), rest::binary>>) do
    {:ok, {value, rest}}
  end

  defp deserialize_varint(<<@u128_byte::size(8), value::little-integer-size(128), rest::binary>>) do
    {:ok, {value, rest}}
  end

  defp deserialize_varint(value) do
    {:error, "Cannot deserialize value #{inspect(value)} into variable-size integer"}
  end

  # Varint has no effect for u8/i8

  # Unsigned
  def serialize(value, :u8, _opts) when is_integer(value) do
    {:ok, <<value::little-integer-size(8)>>}
  end

  def deserialize(<<value::little-integer-size(8), rest::binary>>, :u8, _opts) do
    {:ok, {value, rest}}
  end

  for int_type <- [:u16, :u32, :u64, :u128] do
    {size, ""} = to_string(int_type) |> String.trim_leading("u") |> Integer.parse()

    def serialize(value, unquote(int_type), _opts) when value < 0 do
      {:error,
       "Attempt to serialize negative integer #{inspect(value)} into #{unquote(int_type)}"}
    end

    def serialize(value, unquote(int_type), opts) when is_integer(value) do
      if use_varint(opts) do
        serialize_varint(value)
      else
        {:ok, <<value::little-integer-size(unquote(size))>>}
      end
    end

    def deserialize(<<value::binary>>, unquote(int_type), opts) do
      if use_varint(opts) do
        deserialize_varint(value)
      else
        case value do
          <<int_value::little-integer-size(unquote(size)), rest::binary>> ->
            {:ok, {int_value, rest}}

          _ ->
            {:error,
             "Cannot deserialize value #{inspect(value)} into type #{inspect(unquote(int_type))}"}
        end
      end
    end
  end

  # Signed
  def serialize(value, :i8, _opts) when is_integer(value) do
    {:ok, <<value::little-integer-signed-size(8)>>}
  end

  def deserialize(<<value::little-integer-signed-size(8), rest::binary>>, :i8, _opts) do
    {:ok, {value, rest}}
  end

  for int_type <- [:i16, :i32, :i64, :i128] do
    {size, ""} = to_string(int_type) |> String.trim_leading("i") |> Integer.parse()

    def serialize(value, unquote(int_type), opts) when is_integer(value) do
      if use_varint(opts) do
        serialize_varint(zigzag_encode(value))
      else
        {:ok, <<value::little-integer-signed-size(unquote(size))>>}
      end
    end

    def deserialize(<<value::binary>>, unquote(int_type), opts) do
      if use_varint(opts) do
        with {:ok, {deserialized, rest}} <- deserialize_varint(value) do
          {:ok, {zigzag_decode(deserialized), rest}}
        end
      else
        case value do
          <<int_value::little-integer-signed-size(unquote(size)), rest::binary>> ->
            {:ok, {int_value, rest}}

          _ ->
            {:error,
             "Cannot deserialize value #{inspect(value)} into type #{inspect(unquote(int_type))}"}
        end
      end
    end
  end

  # Float
  for float_type <- [:f32, :f64] do
    {size, ""} = to_string(float_type) |> String.trim_leading("f") |> Integer.parse()

    def serialize(value, unquote(float_type), _opts) when is_float(value) do
      {:ok, <<value::little-float-size(unquote(size))>>}
    end

    def deserialize(
          <<value::little-float-size(unquote(size)), rest::binary>>,
          unquote(float_type),
          _opts
        ) do
      {:ok, {value, rest}}
    end
  end

  # Bool
  for boolean <- [true, false] do
    v = if boolean, do: 1, else: 0

    def serialize(unquote(boolean), :bool, _opts) do
      {:ok, <<unquote(v)::size(8)>>}
    end

    def deserialize(<<unquote(v)::size(8), rest::binary>>, :bool, _opts) do
      {:ok, {unquote(boolean), rest}}
    end
  end

  # String
  def serialize(value, :string, opts) when is_binary(value) do
    with {:ok, serialized_size} <- serialize(byte_size(value), :u64, opts) do
      {:ok, <<serialized_size::binary, value::binary>>}
    end
  end

  def deserialize(<<rest::binary>>, :string, opts) do
    with {:ok, {deserialized_size, rest}} <- deserialize(rest, :u64, opts),
         <<content::binary-size(deserialized_size), rest::binary>> <- rest do
      {:ok, {content, rest}}
    else
      _ -> {:error, "Cannot deserialize value #{inspect(rest)} into type :string"}
    end
  end

  # List
  def serialize(list, {:list, inner}, opts) when is_list(list) do
    serialize(list, 0, <<>>, {:list, inner}, opts)
  end

  defp serialize([], length, result, {:list, _inner}, opts) do
    with {:ok, serialized_size} <- serialize(length, :u64, opts) do
      {:ok, <<serialized_size::binary, IO.iodata_to_binary(result)::binary>>}
    end
  end

  defp serialize([head | tail], length, result, {:list, inner}, opts) do
    case serialize(head, inner, opts) do
      {:ok, serialized} ->
        result = [result, serialized]
        serialize(tail, length + 1, result, {:list, inner}, opts)

      {:error, msg} ->
        {:error, msg}
    end
  end

  def deserialize(<<rest::binary>>, {:list, inner}, opts) do
    with {:ok, {deserialized_size, rest}} <- deserialize(rest, :u64, opts) do
      deserialize(rest, deserialized_size, [], {:list, inner}, opts)
    else
      _ -> {:error, "Cannot deserialize value #{inspect(rest)} into type :list"}
    end
  end

  defp deserialize(rest, 0, result, {:list, _}, _opts) do
    result = Enum.reverse(result)
    {:ok, {result, rest}}
  end

  defp deserialize(rest, remaining, result, {:list, inner}, opts) do
    case deserialize(rest, inner, opts) do
      {:ok, {deserialized, rest}} ->
        result = [deserialized | result]
        deserialize(rest, remaining - 1, result, {:list, inner}, opts)

      {:error, msg} ->
        {:error, msg}
    end
  end

  # Map
  def serialize(map, {:map, {key_type, value_type}}, opts) when is_map(map) do
    serialize(map, Map.keys(map), 0, <<>>, {:map, {key_type, value_type}}, opts)
  end

  defp serialize(_map, [], length, result, {:map, {_, _}}, opts) do
    with {:ok, serialized_size} <- serialize(length, :u64, opts) do
      {:ok, <<serialized_size::binary, IO.iodata_to_binary(result)::binary>>}
    end
  end

  defp serialize(map, [key | keys], length, result, {:map, {key_type, value_type}}, opts) do
    case serialize(key, key_type, opts) do
      {:ok, serialized_key} ->
        case serialize(map[key], value_type, opts) do
          {:ok, serialized_value} ->
            result = [result, serialized_key, serialized_value]
            serialize(map, keys, length + 1, result, {:map, {key_type, value_type}}, opts)

          {:error, msg} ->
            {:error, msg}
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  def deserialize(<<rest::binary>>, {:map, {key_type, value_type}}, opts) do
    with {:ok, {deserialized_size, rest}} <- deserialize(rest, :u64, opts) do
      deserialize(rest, deserialized_size, %{}, {:map, {key_type, value_type}}, opts)
    else
      _ -> {:error, "Cannot deserialize value #{inspect(rest)} into type :map"}
    end
  end

  defp deserialize(rest, 0, result, {:map, {_, _}}, _opts) do
    {:ok, {result, rest}}
  end

  defp deserialize(rest, remaining, result, {:map, {key_type, value_type}}, opts) do
    case deserialize(rest, key_type, opts) do
      {:ok, {deserialized_key, rest}} ->
        case deserialize(rest, value_type, opts) do
          {:ok, {deserialized_value, rest}} ->
            result = Map.put(result, deserialized_key, deserialized_value)
            deserialize(rest, remaining - 1, result, {:map, {key_type, value_type}}, opts)

          {:error, msg} ->
            {:error, msg}
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  # Set
  def serialize(%MapSet{} = set, {:set, inner}, opts) do
    serialize(MapSet.to_list(set), {:list, inner}, opts)
  end

  def deserialize(<<rest::binary>>, {:set, inner}, opts) do
    case deserialize(rest, {:list, inner}, opts) do
      {:ok, {list, rest}} -> {:ok, {MapSet.new(list), rest}}
      {:error, msg} -> {:error, msg}
    end
  end

  # Option
  def serialize(nil, {:option, _}, _opts) do
    {:ok, <<0>>}
  end

  def serialize(value, {:option, inner}, opts) do
    case serialize(value, inner, opts) do
      {:ok, serialized} -> {:ok, <<1::size(8), serialized::binary>>}
      {:error, msg} -> {:error, msg}
    end
  end

  def deserialize(<<0::size(8), rest::binary>>, {:option, _}, _opts) do
    {:ok, {nil, rest}}
  end

  def deserialize(<<1::size(8), rest::binary>>, {:option, inner}, opts) do
    case deserialize(rest, inner, opts) do
      {:ok, {deserialized, rest}} -> {:ok, {deserialized, rest}}
      {:error, msg} -> {:error, msg}
    end
  end

  # Tuple
  max_tuple_size = Application.get_env(:bincode, :max_tuple_size) || 12

  for size <- 1..max_tuple_size do
    type_variables =
      for i <- 1..size do
        field_type = String.to_atom("tuple_type_#{i}")
        quote do: var!(unquote(Macro.var(field_type, __MODULE__)))
      end

    value_variables =
      for i <- 1..size do
        field_value = String.to_atom("tuple_field_#{i}")
        quote do: var!(unquote(Macro.var(field_value, __MODULE__)))
      end

    def serialize({unquote_splicing(value_variables)}, {unquote_splicing(type_variables)}, opts) do
      serialized_fields =
        Enum.reduce_while(
          Enum.zip([unquote_splicing(value_variables)], [unquote_splicing(type_variables)]),
          [],
          fn {value_var, type_var}, result ->
            case serialize(value_var, type_var, opts) do
              {:ok, serialized} -> {:cont, [result, serialized]}
              {:error, msg} -> {:halt, {:error, msg}}
            end
          end
        )

      case serialized_fields do
        {:error, msg} ->
          {:error, msg}

        _ ->
          {:ok, IO.iodata_to_binary(serialized_fields)}
      end
    end

    def deserialize(<<rest::binary>>, {unquote_splicing(type_variables)}, opts) do
      deserialized_fields =
        Enum.reduce_while(
          [unquote_splicing(type_variables)],
          {[], rest},
          fn type_var, {fields, rest} ->
            case deserialize(rest, type_var, opts) do
              {:ok, {deserialized, rest}} -> {:cont, {[deserialized | fields], rest}}
              {:error, msg} -> {:halt, {:error, msg}}
            end
          end
        )

      case deserialized_fields do
        {:error, msg} ->
          {:error, msg}

        {fields, rest} ->
          tuple = Enum.reverse(fields) |> List.to_tuple()
          {:ok, {tuple, rest}}
      end
    end
  end

  def serialize(value, type, opts) do
    if is_atom(type) and function_exported?(type, :serialize, 2) do
      apply(type, :serialize, [value, opts])
    else
      {:error, "Cannot serialize value #{inspect(value)} into type #{inspect(type)}"}
    end
  end

  @doc """
  Same as `serialize/3` but raises an `ArgumentError` when the
  given `value` cannot be encoded according to `type`.

  ## Examples

      iex> Bincode.serialize!([111], {:list, :u16})
      <<1, 0, 0, 0, 0, 0, 0, 0, 111, 0>>

      iex> Bincode.serialize!(<<>>, {:option, :bool})
      ** (ArgumentError) Cannot serialize value "" into type :bool
  """
  def serialize!(value, type, opts \\ []) do
    case serialize(value, type, opts) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  def deserialize(value, type, opts) do
    if is_atom(type) and function_exported?(type, :deserialize, 2) do
      apply(type, :deserialize, [value, opts])
    else
      {:error, "Cannot deserialize value #{inspect(value)} into type #{inspect(type)}"}
    end
  end

  @doc """
  Same as `deserialize/3` but raises an `ArgumentError` when the
  given `value` cannot be encoded according to `type`.

  ## Examples

      iex> Bincode.deserialize!(<<1, 54, 23>>, {:option, :u16})
      {5942, ""}

      iex> Bincode.deserialize!(<<>>, {:list, :string})
      ** (ArgumentError) Cannot deserialize value "" into type :list
  """
  def deserialize!(value, type, opts \\ []) do
    case deserialize(value, type, opts) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message: message
    end
  end
end
