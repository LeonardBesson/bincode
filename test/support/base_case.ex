defmodule Bincode.BaseCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Bincode.TestUtils
    end
  end
end
