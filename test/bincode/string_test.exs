defmodule Bincode.StringTest do
  use Bincode.BaseCase, async: true

  test_serialization(
    "hello world",
    <<11, 0, 0, 0, 0, 0, 0, 0, 104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100>>,
    :string
  )

  test_serialization(
    "variable encoded length string",
    <<30, 118, 97, 114, 105, 97, 98, 108, 101, 32, 101, 110, 99, 111, 100, 101, 100, 32, 108, 101,
      110, 103, 116, 104, 32, 115, 116, 114, 105, 110, 103>>,
    :string,
    varint: true
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
