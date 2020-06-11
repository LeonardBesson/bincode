defmodule Bincode.TupleTest do
  use Bincode.BaseCase, async: true

  test_serialization({255}, <<255>>, {:u8})
  test_serialization({1, 1}, <<1, 1>>, {:u8, :u8})

  test_serialization(
    {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12},
    <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12>>,
    {:u8, :u8, :u8, :u8, :u8, :u8, :u8, :u8, :u8, :u8, :u8, :u8}
  )

  test_serialization({888, 999}, <<120, 3, 231, 3>>, {:u16, :u16})

  test_serialization(
    {[true, true], %{"map" => "in tuple"}},
    <<2, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 109, 97, 112,
      8, 0, 0, 0, 0, 0, 0, 0, 105, 110, 32, 116, 117, 112, 108, 101>>,
    {{:list, :bool}, {:map, {:string, :string}}}
  )

  test_serialization_fail(1, 1, {:u8})
  test_serialization_fail("valid", "invalid", {:string, :u64})
  test_serialization_fail(true, [], {:bool, {:list, :u8}})
end
