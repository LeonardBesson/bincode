defmodule Bincode.VarintTest do
  use Bincode.BaseCase, async: true

  # u16
  test_serialization(0, <<0::size(8)>>, :u16, varint: true)
  test_serialization(43, <<43::size(8)>>, :u16, varint: true)
  test_serialization(34561, <<251, 34561::little-integer-size(16)>>, :u16, varint: true)

  test_serialization_fail("", "", :u16, varint: true)
  test_serialization_fail(3.0, 23.0, :u16, varint: true)
  test_serialization_fail(false, true, :u16, varint: true)

  # u32
  test_serialization(0, <<0::size(8)>>, :u32, varint: true)
  test_serialization(999, <<251, 999::little-integer-size(16)>>, :u32, varint: true)
  test_serialization(11_987_534, <<252, 11_987_534::little-integer-size(32)>>, :u32, varint: true)

  test_serialization_fail("", "", :u32, varint: true)
  test_serialization_fail(3.0, 23.0, :u32, varint: true)
  test_serialization_fail(false, true, :u32, varint: true)

  # u64
  test_serialization(0, <<0::size(8)>>, :u64, varint: true)
  test_serialization(123, <<123::size(8)>>, :u64, varint: true)

  test_serialization(124_534_987, <<252, 124_534_987::little-integer-size(32)>>, :u64,
    varint: true
  )

  test_serialization(4_986_543_432_976, <<253, 4_986_543_432_976::little-integer-size(64)>>, :u64,
    varint: true
  )

  test_serialization_fail("", "", :u64, varint: true)
  test_serialization_fail(3.0, 23.0, :u64, varint: true)
  test_serialization_fail(false, true, :u64, varint: true)

  # u128
  test_serialization(0, <<0::size(8)>>, :u128, varint: true)
  test_serialization(444, <<251, 444::little-integer-size(16)>>, :u128, varint: true)

  test_serialization(111_321_089_731, <<253, 111_321_089_731::little-integer-size(64)>>, :u128,
    varint: true
  )

  test_serialization(
    888_111_908_765_498_721_532,
    <<254, 888_111_908_765_498_721_532::little-integer-size(128)>>,
    :u128,
    varint: true
  )

  test_serialization_fail("", "", :u128, varint: true)
  test_serialization_fail(3.0, 23.0, :u128, varint: true)
  test_serialization_fail(false, true, :u128, varint: true)
end
