defmodule Bincode.MapTest do
  use Bincode.BaseCase, async: true

  describe "maps" do
    test_serialization(%{}, <<0, 0, 0, 0, 0, 0, 0, 0>>, {:map, {:u32, :string}})

    test_serialization(
      %{33 => "thirty three"},
      <<1, 0, 0, 0, 0, 0, 0, 0, 33, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 116, 104, 105, 114, 116,
        121, 32, 116, 104, 114, 101, 101>>,
      {:map, {:u32, :string}}
    )

    test_serialization(
      %{"a key" => "value of key", "another key" => "value of another key"},
      <<2, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 97, 32, 107, 101, 121, 12, 0, 0, 0, 0, 0,
        0, 0, 118, 97, 108, 117, 101, 32, 111, 102, 32, 107, 101, 121, 11, 0, 0, 0, 0, 0, 0, 0,
        97, 110, 111, 116, 104, 101, 114, 32, 107, 101, 121, 20, 0, 0, 0, 0, 0, 0, 0, 118, 97,
        108, 117, 101, 32, 111, 102, 32, 97, 110, 111, 116, 104, 101, 114, 32, 107, 101, 121>>,
      {:map, {:string, :string}}
    )

    test_serialization(
      %{"a" => ["a", "aa", "aaa"], "b" => [], "d" => ["dddd", "dd"]},
      <<3, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 97, 3, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
        0, 0, 0, 97, 2, 0, 0, 0, 0, 0, 0, 0, 97, 97, 3, 0, 0, 0, 0, 0, 0, 0, 97, 97, 97, 1, 0, 0,
        0, 0, 0, 0, 0, 98, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 100, 2, 0, 0, 0, 0, 0,
        0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 100, 100, 100, 100, 2, 0, 0, 0, 0, 0, 0, 0, 100, 100>>,
      {:map, {:string, {:list, :string}}}
    )

    test_serialization_fail(1, 1, {:map, {:u8, :u32}})
    test_serialization_fail("", "", {:map, {:string, :bool}})
    test_serialization_fail([], [], {:map, {:u32, {:list, :string}}})
  end
end
