defmodule Bincode.TestStructs do
  @moduledoc """
  Custom structs used during tests.
  """
  import Bincode

  declare_enum(SomeEnum,
    VariantA: [],
    VariantB: [tuple: {:u32, :f64, :string}],
    VariantC: [a_byte: :u8, a_string: :string]
  )

  declare_enum(NestedEnum,
    VariantA: [an_enum: Bincode.TestStructs.SomeEnum],
    VariantB: [tuple: {:u8, :u8}]
  )

  declare_struct(SimpleStruct,
    a_string: :string,
    a_list: {:list, :u8},
    a_tuple: {:u32, :string, :bool}
  )

  declare_struct(StructWithEnum, an_enum: Bincode.TestStructs.SomeEnum)

  declare_enum(EnumWithStruct, VariantA: [a_struct: Bincode.TestStructs.SimpleStruct])

  declare_struct(NestedStruct,
    a_byte: :u8,
    a_struct: Bincode.TestStructs.SimpleStruct
  )

  declare_struct(CompositeStruct,
    a_list_of_struct: {:list, Bincode.TestStructs.NestedStruct},
    a_map_of_struct: {:map, {:u64, Bincode.TestStructs.SimpleStruct}}
  )
end
