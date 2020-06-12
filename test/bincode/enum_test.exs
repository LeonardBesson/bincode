defmodule Bincode.EnumTest do
  use Bincode.BaseCase, async: true
  alias Bincode.TestStructs.SimpleStruct
  alias Bincode.TestStructs.SomeEnum
  alias Bincode.TestStructs.NestedEnum
  alias Bincode.TestStructs.EnumWithStruct

  test_struct_serialization(
    %SomeEnum.VariantA{},
    <<0, 0, 0, 0>>
  )

  test_struct_serialization(
    %SomeEnum.VariantB{tuple: {87_653_213, 303_213.123873, "Variant B!"}},
    <<1, 0, 0, 0, 93, 123, 57, 5, 79, 144, 216, 126, 180, 129, 18, 65, 10, 0, 0, 0, 0, 0, 0, 0,
      86, 97, 114, 105, 97, 110, 116, 32, 66, 33>>
  )

  test_struct_serialization(
    %SomeEnum.VariantC{a_byte: 255, a_string: "Variant C"},
    <<2, 0, 0, 0, 255, 9, 0, 0, 0, 0, 0, 0, 0, 86, 97, 114, 105, 97, 110, 116, 32, 67>>
  )

  test_struct_serialization_fail(SomeEnum, [], [])
  test_struct_serialization_fail(SomeEnum, true, false)
  test_struct_serialization_fail(SomeEnum, {}, 1..14)

  test_struct_serialization(
    %NestedEnum.VariantA{an_enum: %SomeEnum.VariantC{a_byte: 1, a_string: "!"}},
    <<0, 0, 0, 0, 2, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 33>>
  )

  test_struct_serialization(
    %NestedEnum.VariantB{tuple: {34, 43}},
    <<1, 0, 0, 0, 34, 43>>
  )

  test_struct_serialization_fail(NestedEnum, [], [])
  test_struct_serialization_fail(NestedEnum, true, false)
  test_struct_serialization_fail(NestedEnum, {}, 1..14)

  test_struct_serialization(
    %EnumWithStruct.VariantA{
      a_struct: %SimpleStruct{
        a_list: [11, 22, 33, 44],
        a_string: "string in a struct",
        a_tuple: {555_555, "", false}
      }
    },
    <<0, 0, 0, 0, 18, 0, 0, 0, 0, 0, 0, 0, 115, 116, 114, 105, 110, 103, 32, 105, 110, 32, 97, 32,
      115, 116, 114, 117, 99, 116, 4, 0, 0, 0, 0, 0, 0, 0, 11, 22, 33, 44, 35, 122, 8, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0>>
  )

  test_struct_serialization_fail(EnumWithStruct, [], [])
  test_struct_serialization_fail(EnumWithStruct, true, false)
  test_struct_serialization_fail(EnumWithStruct, {}, 1..14)
end
