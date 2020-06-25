defmodule Bincode.StructTest do
  use Bincode.BaseCase, async: true
  alias Bincode.TestStructs.CompositeStruct
  alias Bincode.TestStructs.SimpleStruct
  alias Bincode.TestStructs.StructWithEnum
  alias Bincode.TestStructs.SomeEnum
  alias Bincode.TestStructs.NestedStruct

  test_struct_serialization(
    %SimpleStruct{
      a_list: [11, 22, 33, 44],
      a_string: "string in a struct",
      a_tuple: {555_555, "", false}
    },
    <<18, 0, 0, 0, 0, 0, 0, 0, 115, 116, 114, 105, 110, 103, 32, 105, 110, 32, 97, 32, 115, 116,
      114, 117, 99, 116, 4, 0, 0, 0, 0, 0, 0, 0, 11, 22, 33, 44, 35, 122, 8, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0>>
  )

  test_struct_serialization_fail(SimpleStruct, [], [])
  test_struct_serialization_fail(SimpleStruct, true, false)
  test_struct_serialization_fail(SimpleStruct, {}, 1..14)

  test_struct_serialization(
    %StructWithEnum{an_enum: %SomeEnum.VariantA{}},
    <<0, 0, 0, 0>>
  )

  test_struct_serialization(
    %StructWithEnum{
      an_enum: %SomeEnum.VariantB{tuple: {22, 303_213.123873, "Variant B!"}}
    },
    <<1, 0, 0, 0, 22, 0, 0, 0, 79, 144, 216, 126, 180, 129, 18, 65, 10, 0, 0, 0, 0, 0, 0, 0, 86,
      97, 114, 105, 97, 110, 116, 32, 66, 33>>
  )

  test_struct_serialization(
    %StructWithEnum{
      an_enum: %SomeEnum.VariantB{tuple: {22, 303_213.123873, "Variant B!"}}
    },
    <<1, 22, 79, 144, 216, 126, 180, 129, 18, 65, 10, 86, 97, 114, 105, 97, 110, 116, 32, 66,
      33>>,
    varint: true
  )

  test_struct_serialization(
    %StructWithEnum{an_enum: %SomeEnum.VariantC{a_byte: 255, a_string: "Variant C"}},
    <<2, 0, 0, 0, 255, 9, 0, 0, 0, 0, 0, 0, 0, 86, 97, 114, 105, 97, 110, 116, 32, 67>>
  )

  test_struct_serialization(
    %StructWithEnum{an_enum: %SomeEnum.VariantC{a_byte: 255, a_string: "Variant C"}},
    <<2, 255, 9, 86, 97, 114, 105, 97, 110, 116, 32, 67>>,
    varint: true
  )

  test_struct_serialization_fail(StructWithEnum, [], [])
  test_struct_serialization_fail(StructWithEnum, true, false)
  test_struct_serialization_fail(StructWithEnum, {}, 1..14)

  test_struct_serialization(
    %NestedStruct{
      a_byte: 255,
      a_struct: %SimpleStruct{
        a_list: [11, 22, 33, 44],
        a_string: "string in a struct",
        a_tuple: {555_555, "", false}
      }
    },
    <<255, 18, 0, 0, 0, 0, 0, 0, 0, 115, 116, 114, 105, 110, 103, 32, 105, 110, 32, 97, 32, 115,
      116, 114, 117, 99, 116, 4, 0, 0, 0, 0, 0, 0, 0, 11, 22, 33, 44, 35, 122, 8, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0>>
  )

  test_struct_serialization_fail(NestedStruct, [1, 2, 3], [])
  test_struct_serialization_fail(NestedStruct, "", false)
  test_struct_serialization_fail(NestedStruct, {}, %{})

  test_struct_serialization(
    %CompositeStruct{
      a_list_of_struct: [
        %NestedStruct{
          a_byte: 2,
          a_struct: %SimpleStruct{
            a_list: [],
            a_string: "string in a struct",
            a_tuple: {555_555, "", false}
          }
        },
        %NestedStruct{
          a_byte: 123,
          a_struct: %SimpleStruct{a_list: [3, 2, 1], a_string: "", a_tuple: {0, "s", true}}
        }
      ],
      a_map_of_struct: %{
        11_111_111_111 => %SimpleStruct{
          a_list: [11, 22, 33, 44, 55, 66, 77, 88],
          a_string: "hello world",
          a_tuple: {432_786, "--1'[.````.;;./", false}
        },
        0 => %SimpleStruct{a_list: [0, 11, 222], a_string: "", a_tuple: {9, "", true}},
        789 => %SimpleStruct{
          a_list: [99],
          a_string: "",
          a_tuple: {321_754, "42&@$#&%@#)*@)#", false}
        }
      }
    },
    <<2, 0, 0, 0, 0, 0, 0, 0, 2, 18, 0, 0, 0, 0, 0, 0, 0, 115, 116, 114, 105, 110, 103, 32, 105,
      110, 32, 97, 32, 115, 116, 114, 117, 99, 116, 0, 0, 0, 0, 0, 0, 0, 0, 35, 122, 8, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 123, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 2, 1, 0, 0, 0,
      0, 1, 0, 0, 0, 0, 0, 0, 0, 115, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 11, 222, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
      21, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 99, 218, 232, 4, 0,
      15, 0, 0, 0, 0, 0, 0, 0, 52, 50, 38, 64, 36, 35, 38, 37, 64, 35, 41, 42, 64, 41, 35, 0, 199,
      25, 70, 150, 2, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0, 104, 101, 108, 108, 111, 32, 119, 111,
      114, 108, 100, 8, 0, 0, 0, 0, 0, 0, 0, 11, 22, 33, 44, 55, 66, 77, 88, 146, 154, 6, 0, 15,
      0, 0, 0, 0, 0, 0, 0, 45, 45, 49, 39, 91, 46, 96, 96, 96, 96, 46, 59, 59, 46, 47, 0>>
  )

  test_struct_serialization_fail(CompositeStruct, %{}, %{})
  test_struct_serialization_fail(CompositeStruct, {"", false}, 890)
  test_struct_serialization_fail(CompositeStruct, 0x32, [[], []])
end
