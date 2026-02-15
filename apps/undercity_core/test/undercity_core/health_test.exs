defmodule UndercityCore.HealthTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Health

  describe "new/0" do
    test "returns a struct at max HP" do
      assert %Health{hp: 50} = Health.new()
    end
  end

  describe "max/0" do
    test "returns 50" do
      assert 50 = Health.max()
    end
  end

  describe "current/1" do
    test "returns the HP value" do
      assert 42 = Health.current(%Health{hp: 42})
    end
  end
end
