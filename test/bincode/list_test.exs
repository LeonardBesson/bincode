defmodule Bincode.ListTest do
  use Bincode.BaseCase, async: true

  describe "lists" do
    test_serialization([], <<0, 0, 0, 0, 0, 0, 0, 0>>, {:list, :f32})
    test_serialization([1, 2, 3], <<3, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3>>, {:list, :u8})

    test_serialization(
      [1, 2, 3],
      <<3, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0>>,
      {:list, :u32}
    )

    test_serialization(
      [true, true, false, true],
      <<4, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1>>,
      {:list, :bool}
    )

    test_serialization(
      [[], ["a", "list"], ["of"], ["list", "of", "string"]],
      <<4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
        0, 0, 97, 4, 0, 0, 0, 0, 0, 0, 0, 108, 105, 115, 116, 1, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0,
        0, 0, 0, 0, 111, 102, 3, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 108, 105, 115, 116,
        2, 0, 0, 0, 0, 0, 0, 0, 111, 102, 6, 0, 0, 0, 0, 0, 0, 0, 115, 116, 114, 105, 110, 103>>,
      {:list, {:list, :string}}
    )

    test_serialization_fail(1, 1, {:list, :u16})
    test_serialization_fail("aaaaaaa", "aaaaaa", {:list, :bool})
    test_serialization_fail({}, {}, {:list, :string})
  end
end
