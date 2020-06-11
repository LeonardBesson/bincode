defmodule Bincode.SetTest do
  use Bincode.BaseCase, async: true

  describe "sets" do
    test_serialization(MapSet.new([]), <<0, 0, 0, 0, 0, 0, 0, 0>>, {:set, :string})

    test_serialization(
      MapSet.new([1, 2, 3, 4, 5]),
      <<5, 0, 0, 0, 0, 0, 0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0>>,
      {:set, :u16}
    )

    test_serialization(
      MapSet.new(["1", "set", "of", "string"]),
      <<4, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 49, 2, 0, 0, 0, 0, 0, 0, 0, 111, 102, 3,
        0, 0, 0, 0, 0, 0, 0, 115, 101, 116, 6, 0, 0, 0, 0, 0, 0, 0, 115, 116, 114, 105, 110,
        103>>,
      {:set, :string}
    )

    test_serialization(
      MapSet.new([[], [1, 3], [5, 5], [], [0, 55, 66]]),
      <<4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 55, 66, 2, 0,
        0, 0, 0, 0, 0, 0, 1, 3, 2, 0, 0, 0, 0, 0, 0, 0, 5, 5>>,
      {:set, {:list, :u8}}
    )

    test_serialization(
      MapSet.new([MapSet.new([]), MapSet.new([1, 2, 3])]),
      <<2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3>>,
      {:set, {:set, :u8}}
    )

    test_serialization_fail(1, 3, {:set, :string})
    test_serialization_fail([], [], {:set, :u8})
    test_serialization_fail(true, false, {:set, :bool})
  end
end
