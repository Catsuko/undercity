defmodule UndercityCoreTest do
  use ExUnit.Case
  doctest UndercityCore

  test "greets the world" do
    assert UndercityCore.hello() == :world
  end
end
