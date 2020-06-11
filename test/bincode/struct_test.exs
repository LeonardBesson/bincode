defmodule Bincode.StructTest do
  use Bincode.BaseCase, async: true
  alias Bincode.TestStructs.CompositeStruct
  alias Bincode.TestStructs.SimpleStruct
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
end
