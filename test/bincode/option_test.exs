defmodule Bincode.OptionTest do
  use Bincode.BaseCase, async: true

  test_serialization(nil, <<0>>, {:option, :string})
  test_serialization(nil, <<0>>, {:option, :u8})
  test_serialization(1, <<1, 1>>, {:option, :u8})
  test_serialization(255, <<1, 255>>, {:option, :u8})

  test_serialization(
    "some string",
    <<1, 11, 0, 0, 0, 0, 0, 0, 0, 115, 111, 109, 101, 32, 115, 116, 114, 105, 110, 103>>,
    {:option, :string}
  )

  test_serialization(
    ["optional", "list"],
    <<1, 2, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 111, 112, 116, 105, 111, 110, 97, 108, 4,
      0, 0, 0, 0, 0, 0, 0, 108, 105, 115, 116>>,
    {:option, {:list, :string}}
  )

  test_serialization_fail("", "", {:option, :u8})
  test_serialization_fail([], [], {:option, :string})
  test_serialization_fail(4.5555, {}, {:option, :string})
end
