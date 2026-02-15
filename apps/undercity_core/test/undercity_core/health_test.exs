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

  describe "apply_effect/2" do
    test "heals up to max" do
      assert %Health{hp: 50} = Health.apply_effect(%Health{hp: 48}, {:heal, 5})
    end

    test "heals normally when below max" do
      assert %Health{hp: 30} = Health.apply_effect(%Health{hp: 25}, {:heal, 5})
    end

    test "damages down to zero" do
      assert %Health{hp: 0} = Health.apply_effect(%Health{hp: 3}, {:damage, 5})
    end

    test "damages normally" do
      assert %Health{hp: 20} = Health.apply_effect(%Health{hp: 25}, {:damage, 5})
    end
  end
end
