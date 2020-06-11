defmodule Bincode.FloatTest do
  use Bincode.BaseCase, async: true

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
