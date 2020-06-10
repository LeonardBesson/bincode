defmodule BincodeTest do
  use ExUnit.Case
  import Bincode.TestUtils

  doctest Bincode

  describe "unsigned integers" do
    # u8
    test_serialization(0, <<0>>, :u8)
    test_serialization(12, <<12>>, :u8)
    test_serialization(255, <<255>>, :u8)

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
    test_serialization(987534, <<987534::little-integer-size(32)>>, :u32)

    test_serialization_fail("", "", :u32)
    test_serialization_fail(3.0, 23.0, :u32)
    test_serialization_fail(false, true, :u32)

    # u64
    test_serialization(0, <<0::little-integer-size(64)>>, :u64)
    test_serialization(123, <<123::little-integer-size(64)>>, :u64)
    test_serialization(534987, <<534987::little-integer-size(64)>>, :u64)
    test_serialization(4986543432976, <<4986543432976::little-integer-size(64)>>, :u64)

    test_serialization_fail("", "", :u64)
    test_serialization_fail(3.0, 23.0, :u64)
    test_serialization_fail(false, true, :u64)

    # u128
    test_serialization(0, <<0::little-integer-size(128)>>, :u128)
    test_serialization(444, <<444::little-integer-size(128)>>, :u128)
    test_serialization(321089731, <<321089731::little-integer-size(128)>>, :u128)
    test_serialization(439246724432, <<439246724432::little-integer-size(128)>>, :u128)
    test_serialization(908765498721532, <<908765498721532::little-integer-size(128)>>, :u128)

    test_serialization_fail("", "", :u128)
    test_serialization_fail(3.0, 23.0, :u128)
    test_serialization_fail(false, true, :u128)
  end
end
