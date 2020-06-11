defmodule Bincode.BoolTest do
  use Bincode.BaseCase, async: true

  describe "booleans" do
    test_serialization(true, <<1::size(8)>>, :bool)
    test_serialization(false, <<0::size(8)>>, :bool)

    test_serialization_fail("", "", :bool)
    test_serialization_fail([], [], :bool)
    test_serialization_fail(1, 1, :bool)
    test_serialization_fail({}, {}, :bool)
  end
end
