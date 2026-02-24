defmodule UndercityCore.Combat.ResolutionTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Combat.Resolution

  @iron_pipe %{damage_min: 2, damage_max: 6, hit_modifier: 0.0}

  describe "hit?/2" do
    test "returns true when roll is below base hit chance" do
      assert Resolution.hit?(@iron_pipe, 0.0)
      assert Resolution.hit?(@iron_pipe, 0.64)
    end

    test "returns false when roll meets or exceeds base hit chance" do
      refute Resolution.hit?(@iron_pipe, 0.65)
      refute Resolution.hit?(@iron_pipe, 1.0)
    end

    test "hit_modifier shifts the hit threshold up" do
      boosted = %{@iron_pipe | hit_modifier: 0.20}

      assert Resolution.hit?(boosted, 0.80)
      refute Resolution.hit?(boosted, 0.90)
    end

    test "hit_modifier shifts the hit threshold down" do
      penalised = %{@iron_pipe | hit_modifier: -0.20}

      refute Resolution.hit?(penalised, 0.45)
      assert Resolution.hit?(penalised, 0.44)
    end
  end

  describe "roll_damage/2" do
    test "returns minimum damage when roll is 0.0" do
      assert Resolution.roll_damage(@iron_pipe, 0.0) == 2
    end

    test "returns maximum damage when roll is 1.0" do
      assert Resolution.roll_damage(@iron_pipe, 1.0) == 6
    end

    test "returns damage within range for mid rolls" do
      damage = Resolution.roll_damage(@iron_pipe, 0.5)
      assert damage >= 2 and damage <= 6
    end

    test "returns minimum when damage_min equals damage_max" do
      flat = %{@iron_pipe | damage_min: 4, damage_max: 4}
      assert Resolution.roll_damage(flat, 0.0) == 4
      assert Resolution.roll_damage(flat, 1.0) == 4
    end
  end

  describe "roll/3" do
    test "returns {:hit, damage} when roll hits" do
      assert {:hit, 2} = Resolution.roll(@iron_pipe, 0.0, 0.0)
    end

    test "returns :miss when roll misses" do
      assert :miss = Resolution.roll(@iron_pipe, 1.0, 0.0)
    end

    test "damage reflects the damage roll on a hit" do
      assert {:hit, 6} = Resolution.roll(@iron_pipe, 0.0, 1.0)
    end
  end
end
