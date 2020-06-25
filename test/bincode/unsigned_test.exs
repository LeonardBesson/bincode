defmodule Bincode.UnsignedTest do
  use Bincode.BaseCase, async: true

  # u8
  test_serialization(0, <<0>>, :u8)
  test_serialization(12, <<12>>, :u8)
  test_serialization(255, <<255>>, :u8)
  # Varint ignored for :u8
  test_serialization(254, <<254>>, :u8, varint: true)

  test_serialization_fail("", "", :u8)
  test_serialization_fail(3.0, 23.0, :u8)
  test_serialization_fail(false, true, :u8)

  # u16
  test_serialization(0, <<0::little-integer-size(16)>>, :u16)
  test_serialization(43, <<43::little-integer-size(16)>>, :u16)
  test_serialization(34561, <<34561::little-integer-size(16)>>, :u16)

  test_serialization_fail("", "", :u16)
  test_serialization_fail(3.0, 23.0, :u16)
  test_serialization_fail(false, true, :u16)

  # u32
  test_serialization(0, <<0::little-integer-size(32)>>, :u32)
  test_serialization(999, <<999::little-integer-size(32)>>, :u32)
  test_serialization(987_534, <<987_534::little-integer-size(32)>>, :u32)

  test_serialization_fail("", "", :u32)
  test_serialization_fail(3.0, 23.0, :u32)
  test_serialization_fail(false, true, :u32)

  # u64
  test_serialization(0, <<0::little-integer-size(64)>>, :u64)
  test_serialization(123, <<123::little-integer-size(64)>>, :u64)
  test_serialization(534_987, <<534_987::little-integer-size(64)>>, :u64)
  test_serialization(4_986_543_432_976, <<4_986_543_432_976::little-integer-size(64)>>, :u64)

  test_serialization_fail("", "", :u64)
  test_serialization_fail(3.0, 23.0, :u64)
  test_serialization_fail(false, true, :u64)

  # u128
  test_serialization(0, <<0::little-integer-size(128)>>, :u128)
  test_serialization(444, <<444::little-integer-size(128)>>, :u128)
  test_serialization(321_089_731, <<321_089_731::little-integer-size(128)>>, :u128)
  test_serialization(439_246_724_432, <<439_246_724_432::little-integer-size(128)>>, :u128)

  test_serialization(
    908_765_498_721_532,
    <<908_765_498_721_532::little-integer-size(128)>>,
    :u128
  )

  test_serialization_fail("", "", :u128)
  test_serialization_fail(3.0, 23.0, :u128)
  test_serialization_fail(false, true, :u128)
end
