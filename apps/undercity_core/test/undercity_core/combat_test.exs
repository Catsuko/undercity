defmodule UndercityCore.CombatTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Combat

  @iron_pipe %{damage_min: 2, damage_max: 6, hit_modifier: 0.0}

  describe "resolve/3" do
    test "returns {:hit, damage} on a hit" do
      assert {:hit, 2} = Combat.resolve(@iron_pipe, 0.0, 0.0)
    end

    test "returns :miss on a miss" do
      assert :miss = Combat.resolve(@iron_pipe, 1.0, 0.0)
    end
  end
end
