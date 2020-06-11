defmodule Bincode.SignedTest do
  use Bincode.BaseCase, async: true

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
end
