defmodule UndercityCore.Item.RemedyTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item.Remedy

  describe "effect/1" do
    test "salve returns {:heal, 15}" do
      assert {:heal, 15} = Remedy.effect("Salve")
    end

    test "non-remedy item returns :not_a_remedy" do
      assert :not_a_remedy = Remedy.effect("Junk")
    end
  end

  describe "remedy?/1" do
    test "salve is a remedy" do
      assert Remedy.remedy?("Salve")
    end

    test "junk is not a remedy" do
      refute Remedy.remedy?("Junk")
    end
  end
end
