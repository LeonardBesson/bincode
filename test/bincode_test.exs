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

  describe "signed integers" do
    # i8
    test_serialization(0, <<0>>, :i8)
    test_serialization(-12, <<-12>>, :i8)
    test_serialization(127, <<127>>, :i8)

    test_serialization_fail("", "", :i8)
    test_serialization_fail(3.0, 23.0, :i8)
    test_serialization_fail(false, true, :i8)

    # i16
    test_serialization(0, <<0::little-integer-signed-size(16)>>, :i16)
    test_serialization(43, <<43::little-integer-signed-size(16)>>, :i16)
    test_serialization(-24561, <<-24561::little-integer-signed-size(16)>>, :i16)

    test_serialization_fail("", "", :i16)
    test_serialization_fail(3.0, 23.0, :i16)
    test_serialization_fail(false, true, :i16)

    # i32
    test_serialization(0, <<0::little-integer-signed-size(32)>>, :i32)
    test_serialization(-999, <<-999::little-integer-signed-size(32)>>, :i32)
    test_serialization(987_534, <<987_534::little-integer-signed-size(32)>>, :i32)

    test_serialization_fail("", "", :i32)
    test_serialization_fail(3.0, 23.0, :i32)
    test_serialization_fail(false, true, :i32)

    # i64
    test_serialization(0, <<0::little-integer-signed-size(64)>>, :i64)
    test_serialization(-123, <<-123::little-integer-signed-size(64)>>, :i64)
    test_serialization(534_987, <<534_987::little-integer-signed-size(64)>>, :i64)
    test_serialization(-4_986_543_976, <<-4_986_543_976::little-integer-signed-size(64)>>, :i64)

    test_serialization_fail("", "", :i64)
    test_serialization_fail(3.0, 23.0, :i64)
    test_serialization_fail(false, true, :i64)

    # i128
    test_serialization(0, <<0::little-integer-signed-size(128)>>, :i128)
    test_serialization(444, <<444::little-integer-signed-size(128)>>, :i128)
    test_serialization(321_089_731, <<321_089_731::little-integer-signed-size(128)>>, :i128)

    test_serialization(
      -439_246_724_432,
      <<-439_246_724_432::little-integer-signed-size(128)>>,
      :i128
    )

    test_serialization(
      908_765_498_721_532,
      <<908_765_498_721_532::little-integer-signed-size(128)>>,
      :i128
    )

    test_serialization_fail("", "", :i128)
    test_serialization_fail(3.0, 23.0, :i128)
    test_serialization_fail(false, true, :i128)
  end

  describe "floats" do
    # f32
    test_serialization(0.0, <<0.0::little-float-size(32)>>, :f32)
    test_serialization(32131.0, <<32131.0::little-float-size(32)>>, :f32)
    test_serialization(34_983_720.0, <<34_983_720.0::little-float-size(32)>>, :f32)

    test_serialization_fail("", "", :f32)
    test_serialization_fail(3, 23, :f32)
    test_serialization_fail(false, true, :f32)

    # f64
    test_serialization(0.0, <<0.0::little-float-size(64)>>, :f64)
    test_serialization(43.34234, <<43.34234::little-float-size(64)>>, :f64)
    test_serialization(2_136_531.32197, <<2_136_531.32197::little-float-size(64)>>, :f64)

    test_serialization_fail("", "", :f64)
    test_serialization_fail(3, 23, :f64)
    test_serialization_fail(false, true, :f64)
  end

  describe "booleans" do
    test_serialization(true, <<1::size(8)>>, :bool)
    test_serialization(false, <<0::size(8)>>, :bool)

    test_serialization_fail("", "", :bool)
    test_serialization_fail([], [], :bool)
    test_serialization_fail(1, 1, :bool)
    test_serialization_fail({}, {}, :bool)
  end

  describe "strings" do
    test_serialization(
      "hello world",
      <<11, 0, 0, 0, 0, 0, 0, 0, 104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100>>,
      :string
    )

    test_serialization(
      "你好世界",
      <<12, 0, 0, 0, 0, 0, 0, 0, 228, 189, 160, 229, 165, 189, 228, 184, 150, 231, 149, 140>>,
      :string
    )

    test_serialization(
      "γειά σου κόσμος",
      <<28, 0, 0, 0, 0, 0, 0, 0, 206, 179, 206, 181, 206, 185, 206, 172, 32, 207, 131, 206, 191,
        207, 133, 32, 206, 186, 207, 140, 207, 131, 206, 188, 206, 191, 207, 130>>,
      :string
    )

    test_serialization(
      "Здравствуй, мир",
      <<28, 0, 0, 0, 0, 0, 0, 0, 208, 151, 208, 180, 209, 128, 208, 176, 208, 178, 209, 129, 209,
        130, 208, 178, 209, 131, 208, 185, 44, 32, 208, 188, 208, 184, 209, 128>>,
      :string
    )

    test_serialization_fail(1, 1, :string)
    test_serialization_fail(3.14, 3.14, :string)
    test_serialization_fail([], [], :string)
    test_serialization_fail({}, {}, :string)
  end

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
