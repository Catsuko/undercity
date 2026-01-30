defmodule UndercityCliTest do
  use ExUnit.Case
  doctest UndercityCli

  test "greets the world" do
    assert UndercityCli.hello() == :world
  end
end
