defmodule Bincode do
  @moduledoc """
  Documentation for `Bincode`.
  """
  # Struct
  defmacro declare_struct(struct, fields, options \\ []) when is_list(fields) do
    %Macro.Env{module: caller_module} = __CALLER__

    struct_module = Module.concat([caller_module, Macro.expand(struct, __CALLER__)])
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
      end

      defimpl Bincode.Serializer, for: unquote(struct_module) do
        def serialize(term) do
          unquote(struct_module).serialize(term)
        end
      end
    end
  end

  # Enum
  defmacro declare_enum(enum, variants) when is_list(variants) do
    %Macro.Env{module: caller_module} = __CALLER__

    enum_module = Module.concat([caller_module, Macro.expand(enum, __CALLER__)])

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

            def deserialize(data) do
              {:error,
               "Cannot deserialize #{inspect(data)} into enum #{unquote(enum_module)} variant"}
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

  # Fallback
  def serialize(value, type) do
    if is_atom(type) and function_exported?(type, :serialize, 1) do
      apply(type, :serialize, [value])
    else
      {:error, "Cannot serialize value #{inspect(value)} into type #{inspect(type)}"}
    end
  end

  def serialize!(value, type) do
    case serialize(value, type) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  def deserialize(value, type) do
    if is_atom(type) and function_exported?(type, :deserialize, 1) do
      apply(type, :deserialize, [value])
    else
      {:error, "Cannot deserialize value #{inspect(value)} into type #{inspect(type)}"}
    end
  end

  def deserialize!(value, type) do
    case deserialize(value, type) do
      {:ok, result} -> result
      {:error, message} -> raise ArgumentError, message: message
    end
  end
end
