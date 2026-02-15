defmodule UndercityCore.FoodTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Food

  describe "effect/1" do
    test "mushroom returns heal or damage" do
      results = for _ <- 1..100, do: Food.effect("Mushroom")
      assert Enum.all?(results, &(match?({:heal, 5}, &1) or match?({:damage, 5}, &1)))
      assert Enum.any?(results, &match?({:heal, 5}, &1))
      assert Enum.any?(results, &match?({:damage, 5}, &1))
    end

    test "non-edible item returns :not_edible" do
      assert :not_edible = Food.effect("Junk")
    end
  end

  describe "edible?/1" do
    test "mushroom is edible" do
      assert Food.edible?("Mushroom")
    end

    test "junk is not edible" do
      refute Food.edible?("Junk")
    end
  end
end
