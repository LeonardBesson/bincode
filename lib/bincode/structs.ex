defmodule Bincode.Structs do
  @moduledoc """
  Module defining macros related to structs and enums.
  """

  @doc """
  Declares a new struct. This macro generates a struct with serialization and
  deserialization methods according to the given fields.

  ## Options

  * `absolute` - When set to true, the given struct name is interpreted as the absolute module name.
  When set to false, the given struct name is appended to the caller's module. Defaults to false.

  ## Example

      defmodule MyStructs do
        import Bincode.Structs

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
        import Bincode.Structs

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

    prefix = Keyword.get(options, :prefix, {nil, nil})

    quoted_prefix_serialization =
      case prefix do
        {nil, nil} ->
          {:ok, <<>>}

        {prefix_value, prefix_type} ->
          quote do: Bincode.serialize(unquote(prefix_value), unquote(prefix_type), var!(opts))
      end

    quoted_prefix_deserialization =
      case prefix do
        {nil, nil} ->
          quote do: {:ok, {<<>>, var!(rest)}}

        {prefix_value, prefix_type} ->
          quote do: Bincode.deserialize(var!(rest), unquote(prefix_type), var!(opts))
      end

    quote do
      defmodule unquote(struct_module) do
        defstruct unquote(struct_data)

        def serialize(struct, opts \\ [])

        def serialize(%__MODULE__{} = var!(struct), var!(opts)) do
          with {:ok, serialized_prefix} = unquote(quoted_prefix_serialization) do
            serialized_fields =
              Enum.reduce_while(
                Enum.zip([unquote_splicing(value_variables)], [unquote_splicing(types)]),
                [serialized_prefix],
                fn {value_var, type}, result ->
                  case Bincode.serialize(value_var, type, var!(opts)) do
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
        end

        def serialize(value, _opts) do
          {:error,
           "Cannot serialize value #{inspect(value)} into struct #{unquote(struct_module)}"}
        end

        def serialize!(value, opts) do
          case serialize(value, opts) do
            {:ok, result} -> result
            {:error, message} -> raise ArgumentError, message: message
          end
        end

        def deserialize(data, opts \\ [])

        def deserialize(<<var!(rest)::binary>>, var!(opts)) do
          with {:ok, {deserialized_variant, rest}} <- unquote(quoted_prefix_deserialization) do
            deserialized_fields =
              Enum.reduce_while(
                Enum.zip([unquote_splicing(field_names)], [unquote_splicing(types)]),
                {[], rest},
                fn {field_name, type}, {fields, rest} ->
                  case Bincode.deserialize(rest, type, var!(opts)) do
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
        end

        def deserialize(data, _opts) do
          {:error,
           "Cannot deserialize value #{inspect(data)} into struct #{unquote(struct_module)}"}
        end

        def deserialize!(data, opts) do
          case deserialize(data, opts) do
            {:ok, result} -> result
            {:error, message} -> raise ArgumentError, message: message
          end
        end
      end

      defimpl Bincode.Serializer, for: unquote(struct_module) do
        def serialize(term, opts) do
          unquote(struct_module).serialize(term, opts)
        end
      end
    end
  end

  @doc """
  Declares a new enum. This macro generates a module for the enum, plus a struct for each variant
  with serialization and deserialization methods according to the given fields.

  ## Options

  * `absolute` - When set to true, the given struct name is interpreted as the absolute module name.
  When set to false, the given struct name is appended to the caller's module. Defaults to false.

  ## Example

      defmodule MyEnums do
        import Bincode.Structs

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

  Enums can be nested and contain structs. See `Bincode.Structs.declare_struct/3`.
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
              variant_module = Module.concat([enum_module, Macro.expand(variant, __CALLER__)])

              quote do
                Bincode.Structs.declare_struct(
                  unquote(variant),
                  unquote(fields),
                  prefix: {unquote(i), :u32}
                )

                def serialize(%unquote(variant_module){} = variant, opts) do
                  unquote(variant_module).serialize(variant, opts)
                end

                defp deserialize(unquote(i), <<data::binary>>, opts) do
                  unquote(variant_module).deserialize(data, opts)
                end
              end
            end

          quote do
            unquote(variants_definition)

            def serialize(value, _opts) do
              {:error,
               "Cannot serialize variant #{inspect(value)} into enum #{unquote(enum_module)}"}
            end

            def serialize!(value, opts) do
              case serialize(value, opts) do
                {:ok, result} -> result
                {:error, message} -> raise ArgumentError, message: message
              end
            end

            def deserialize(<<data::binary>>, opts) do
              case Bincode.deserialize(data, :u32, opts) do
                {:ok, {deserialized_variant, _}} ->
                  deserialize(deserialized_variant, data, opts)

                {:error, _} ->
                  {:error,
                   "Cannot serialize variant #{inspect(data)} into enum #{unquote(enum_module)}"}
              end
            end

            def deserialize(data, _opts) do
              {:error,
               "Cannot deserialize #{inspect(data)} into enum #{unquote(enum_module)} variant"}
            end

            defp deserialize(_unknown_variant, data, _opts) do
              {:error,
               "Cannot deserialize #{inspect(data)} into enum #{unquote(enum_module)} variant"}
            end

            def deserialize!(data, opts) do
              case deserialize(data, opts) do
                {:ok, result} -> result
                {:error, message} -> raise ArgumentError, message: message
              end
            end
          end
        end
      end
    end
  end
end
