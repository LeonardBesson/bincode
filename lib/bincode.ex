defmodule Bincode do
  @moduledoc ~S"""
  Module defining the functionalities of Bincode.

  Bincode allows you to share data between Elixir and Rust using
  Rust's [Bincode](https://github.com/servo/bincode) binary format.

  You can implement your custom serialization manually, but for most use cases
  you can simply declare the Rust structs and enums using `Bincode.declare_struct/3` and
  `Bincode.declare_enum/3`

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
  the fully qualified module name. See `Bincode.declare_struct/3`.

  The endianness is little since that's the default used by Bincode.
  Tuples are implemented for a max size of 12 by default. That should be enough for
  most practical cases but if you need to serialize tuples with more elements you can
  set `max_tuple_size` in the mix config, like so: `config :bincode, max_tuple_size: 23`

  ## Examples

  Consider the typical example were we want to send data structures across the network.
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

  On the Elixir side you can simply declare the same packet struct and deserialize the received data:

      defmodule Packets do
        import Bincode

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

  @type unsigned :: :u8 | :u16 | :u32 | :u64 | :u128
  @type signed :: :i8 | :i16 | :i32 | :i64 | :i128
  @type floating_point :: :f32 | :f64
  @type primitive ::
          unsigned | signed | floating_point | :bool | :string | tuple | {:option, bincode_type}
  @type collection :: {:list, bincode_type} | {:map, bincode_type} | {:set, bincode_type}
  @type user_defined :: module
  @type bincode_type :: primitive | collection | user_defined

  # Struct
  @doc """
  Declares a new struct. This macro generates a struct with serialization and
  deserialization methods according to the given fields.

  ## Options

  * `absolute` - When set to true, the given struct name is interpreted as the absolute module name.
  When set to false, the given struct name is appended to the caller's module. Defaults to false.

  ## Example

      defmodule MyStructs do
        import Bincode

        declare_struct(Person,
          first_name: :string,
          last_name: :string,
          age: :u8
        )
      end

      alias MyStructs.Person

      person = %Person{first_name: "John", last_name: "Doe", age: 44}
      {:ok, <<4, 0, 0, 0, 0, 0, 0, 0, 74, 111, 104, 110, 3, 0, 0, 0, 0, 0, 0, 0, 68, 111, 101, 44>>} = Bincode.serialize(person, Person)

  It's also possible to call `serialize` and `deserialize` from the struct module directly.

      {:ok, {%Person{age: 44, first_name: "John", last_name: "Doe"}, ""}} = Person.deserialize(<<4, 0, 0, 0, 0, 0, 0, 0, 74, 111, 104, 110, 3, 0, 0, 0, 0, 0, 0, 0, 68, 111, 101, 44>>)

  Structs and enums can be nested. In this case the type is the fully qualified module. For example:
      defmodule MyStructs do
        import Bincode

        declare_struct(Person,
          first_name: :string,
          last_name: :string,
          age: :u8
        )

        declare_struct(Employee,
          employee_number: :u64,
          person: MyStructs.Person,
          job_title: :string,
        )
      end
  """
  defmacro declare_struct(struct, fields, options \\ []) when is_list(fields) do
    %Macro.Env{module: caller_module} = __CALLER__

    struct_module =
      if Keyword.get(options, :absolute, false) do
        Macro.expand(struct, __CALLER__)
      else
        Module.concat([caller_module, Macro.expand(struct, __CALLER__)])
      end

    struct_data = for {field_name, _} <- fields, do: {field_name, nil}
    field_names = for {field_name, _} <- fields, do: field_name
    field_types = for {_, field_type} <- fields, do: field_type

    types =
      for type <- field_types do
        case type do
          # This field is a struct
          {:__aliases__, _, _} -> Macro.expand(type, __CALLER__)
          _ -> type
        end
      end

    value_variables =
      for {field_name, _} <- fields do
        quote do: var!(struct).unquote(Macro.var(field_name, nil))
      end

    prefix = Keyword.get(options, :prefix, <<>>)

    quote do
      defmodule unquote(struct_module) do
        defstruct unquote(struct_data)

        def serialize(%__MODULE__{} = var!(struct)) do
          serialized_fields =
            Enum.reduce_while(
              Enum.zip([unquote_splicing(value_variables)], [unquote_splicing(types)]),
              [unquote(prefix)],
              fn {value_var, type}, result ->
                case Bincode.serialize(value_var, type) do
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

        def serialize(value) do
          {:error,
           "Cannot serialize value #{inspect(value)} into struct #{unquote(struct_module)}"}
        end

        def serialize!(value) do
          case serialize(value) do
            {:ok, result} -> result
            {:error, message} -> raise ArgumentError, message: message
          end
        end

        def deserialize(<<unquote(prefix), rest::binary>>) do
          deserialized_fields =
            Enum.reduce_while(
              Enum.zip([unquote_splicing(field_names)], [unquote_splicing(types)]),
              {[], rest},
              fn {field_name, type}, {fields, rest} ->
                case Bincode.deserialize(rest, type) do
                  {:ok, {deserialized, rest}} ->
                    {:cont, {[{field_name, deserialized} | fields], rest}}

                  {:error, msg} ->
                    {:halt, {:error, msg}}
                end
              end
            )

          case deserialized_fields do
            {:error, msg} ->
              {:error, msg}

            {fields, rest} ->
              struct = struct!(unquote(struct_module), fields)
              {:ok, {struct, rest}}
          end
        end

        def deserialize(data) do
          {:error,
           "Cannot deserialize value #{inspect(data)} into struct #{unquote(struct_module)}"}
        end

        def deserialize!(data) do
          case deserialize(data) do
            {:ok, result} -> result
            {:error, message} -> raise ArgumentError, message: message
          end
        end
      end

      defimpl Bincode.Serializer, for: unquote(struct_module) do
        def serialize(term) do
          unquote(struct_module).serialize(term)
        end
      end
    end
  end

  # Enum
  @doc """
  Declares a new enum. This macro generates a module for the enum, plus a struct for each variant
  with serialization and deserialization methods according to the given fields.

  ## Options

  * `absolute` - When set to true, the given struct name is interpreted as the absolute module name.
  When set to false, the given struct name is appended to the caller's module. Defaults to false.

  ## Example

      defmodule MyEnums do
        import Bincode

        declare_enum(IpAddr,
          V4: [tuple: {:u8, :u8, :u8, :u8}],
          V6: [addr: :string]
        )
      end

      alias MyEnums.IpAddr

      ip_v4 = %IpAddr.V4{tuple: {127, 0, 0, 1}}
      {:ok, <<0, 0, 0, 0, 127, 0, 0, 1>>} = Bincode.serialize(ip_v4, IpAddr)

      ip_v6 = %IpAddr.V6{addr: "::1"}
      {:ok, <<1, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 58, 58, 49>>} = Bincode.serialize(ip_v6, IpAddr)

  It's also possible to call `serialize` and `deserialize` from the struct module directly.

      {:ok, {%IpAddr.V4{tuple: {127, 0, 0, 1}}, ""}} = IpAddr.deserialize(<<0, 0, 0, 0, 127, 0, 0, 1>>)
      {:ok, {%IpAddr.V6{addr: "::1"}, ""}} = IpAddr.deserialize(<<1, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 58, 58, 49>>)

  Enums can be nested and contain structs. See `Bincode.declare_struct/3`.
  """
  defmacro declare_enum(enum, variants, options \\ []) when is_list(variants) do
    %Macro.Env{module: caller_module} = __CALLER__

    enum_module =
      if Keyword.get(options, :absolute, false) do
        Macro.expand(enum, __CALLER__)
      else
        Module.concat([caller_module, Macro.expand(enum, __CALLER__)])
      end

    quote do
      defmodule unquote(enum_module) do
        unquote do
          variants_definition =
            for {{variant, fields}, i} <- Enum.with_index(variants) do
              serialized_variant = <<i::little-integer-size(32)>>
              variant_module = Module.concat([enum_module, Macro.expand(variant, __CALLER__)])

              quote do
                Bincode.declare_struct(
                  unquote(variant),
                  unquote(fields),
                  prefix: unquote(serialized_variant)
                )

                def serialize(%unquote(variant_module){} = variant) do
                  unquote(variant_module).serialize(variant)
                end

                def deserialize(<<unquote(serialized_variant), _::binary>> = data) do
                  unquote(variant_module).deserialize(data)
                end
              end
            end

          quote do
            unquote(variants_definition)

            def serialize(value) do
              {:error,
               "Cannot serialize variant #{inspect(value)} into enum #{unquote(enum_module)}"}
            end

            def serialize!(value) do
              case serialize(value) do
                {:ok, result} -> result
                {:error, message} -> raise ArgumentError, message: message
              end
            end

            def deserialize(data) do
              {:error,
               "Cannot deserialize #{inspect(data)} into enum #{unquote(enum_module)} variant"}
            end

            def deserialize!(data) do
              case deserialize(data) do
                {:ok, result} -> result
                {:error, message} -> raise ArgumentError, message: message
              end
            end
          end
        end
      end
    end
  end

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

  defp serialize([], length, result, {:list, _inner}) do
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

  defp serialize(_map, [], length, result, {:map, {_, _}}) do
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

  # Option
  def serialize(nil, {:option, _}) do
    {:ok, <<0>>}
  end

  def serialize(value, {:option, inner}) do
    case serialize(value, inner) do
      {:ok, serialized} -> {:ok, <<1::size(8), serialized::binary>>}
      {:error, msg} -> {:error, msg}
    end
  end

  def deserialize(<<0::size(8), rest::binary>>, {:option, _}) do
    {:ok, {nil, rest}}
  end

  def deserialize(<<1::size(8), rest::binary>>, {:option, inner}) do
    case deserialize(rest, inner) do
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

    def serialize({unquote_splicing(value_variables)}, {unquote_splicing(type_variables)}) do
      serialized_fields =
        Enum.reduce_while(
          Enum.zip([unquote_splicing(value_variables)], [unquote_splicing(type_variables)]),
          [],
          fn {value_var, type_var}, result ->
            case serialize(value_var, type_var) do
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

    def deserialize(<<rest::binary>>, {unquote_splicing(type_variables)}) do
      deserialized_fields =
        Enum.reduce_while(
          [unquote_splicing(type_variables)],
          {[], rest},
          fn type_var, {fields, rest} ->
            case deserialize(rest, type_var) do
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

  @doc """
  Serializes the given `term` in binary representation according to the
  given `type`.

  Returns `{:ok, serialized_term}` when successful or `{:error, error_message}`
  otherwise.

  ## Examples

      iex> Bincode.serialize(255, :u8)
      {:ok, <<255>>}

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
  @spec serialize(term, bincode_type) :: {:ok, binary} | {:error, String.t()}
  def serialize(value, type) do
    if is_atom(type) and function_exported?(type, :serialize, 1) do
      apply(type, :serialize, [value])
    else
      {:error, "Cannot serialize value #{inspect(value)} into type #{inspect(type)}"}
    end
  end

  @doc """
  Same as `serialize/2` but raises an `ArgumentError` when the
  given `value` cannot be encoded according to `type`.

  ## Examples

      iex> Bincode.serialize!([111], {:list, :u16})
      <<1, 0, 0, 0, 0, 0, 0, 0, 111, 0>>

      iex> Bincode.serialize!(<<>>, {:option, :bool})
      ** (ArgumentError) Cannot serialize value "" into type :bool
  """
  def serialize!(value, type) do
    case serialize(value, type) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  @doc """
  Deserializes the given `binary` data into an Elixir term according to the
  given `type`.

  Returns `{:ok, {term, rest}}` when successful or `{:error, error_message}`
  otherwise. The remaining binary data is returned.

  ## Examples
      iex> Bincode.deserialize(<<255>>, :u8)
      {:ok, {255, ""}}

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
  @spec deserialize(binary, bincode_type) :: {:ok, {term, binary}} | {:error, String.t()}
  def deserialize(value, type) do
    if is_atom(type) and Code.ensure_loaded?(type) and function_exported?(type, :deserialize, 1) do
      apply(type, :deserialize, [value])
    else
      {:error, "Cannot deserialize value #{inspect(value)} into type #{inspect(type)}"}
    end
  end

  @doc """
  Same as `deserialize/2` but raises an `ArgumentError` when the
  given `value` cannot be encoded according to `type`.

  ## Examples

      iex> Bincode.deserialize!(<<1, 54, 23>>, {:option, :u16})
      {5942, ""}

      iex> Bincode.deserialize!(<<>>, {:list, :string})
      ** (ArgumentError) Cannot deserialize value "" into type :list
  """
  def deserialize!(value, type) do
    case deserialize(value, type) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message: message
    end
  end
end
