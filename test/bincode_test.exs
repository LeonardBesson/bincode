defmodule BincodeTest do
  use ExUnit.Case
  doctest Bincode

  test "greets the world" do
    assert Bincode.hello() == :world
  end
end
