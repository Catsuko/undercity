defmodule UndercityCore.ActionPointsTest do
  use ExUnit.Case, async: true

  alias UndercityCore.ActionPoints

  describe "new/1" do
    test "returns a struct at max AP with the given timestamp" do
      assert %ActionPoints{ap: 50, updated_at: 1000} = ActionPoints.new(1000)
    end
  end

  describe "regenerate/2" do
    test "no regen when less than one interval has passed" do
      ap = %ActionPoints{ap: 10, updated_at: 100_000 - 1799}
      assert %ActionPoints{ap: 10} = ActionPoints.regenerate(ap, 100_000)
    end

    test "regens 1 AP per 30-minute interval" do
      ap = %ActionPoints{ap: 10, updated_at: 100_000 - 1800}
      assert %ActionPoints{ap: 11} = ActionPoints.regenerate(ap, 100_000)
    end

    test "regens multiple AP for multiple intervals" do
      ap = %ActionPoints{ap: 10, updated_at: 100_000 - 5400}
      assert %ActionPoints{ap: 13} = ActionPoints.regenerate(ap, 100_000)
    end

    test "caps at max AP" do
      ap = %ActionPoints{ap: 45, updated_at: 100_000 - 360_000}
      assert %ActionPoints{ap: 50} = ActionPoints.regenerate(ap, 100_000)
    end

    test "already at max stays at max" do
      ap = %ActionPoints{ap: 50, updated_at: 100_000 - 3600}
      assert %ActionPoints{ap: 50} = ActionPoints.regenerate(ap, 100_000)
    end

    test "zero AP regens normally" do
      ap = %ActionPoints{ap: 0, updated_at: 100_000 - 3600}
      assert %ActionPoints{ap: 2} = ActionPoints.regenerate(ap, 100_000)
    end
  end

  describe "spend/3" do
    test "succeeds when enough AP" do
      ap = %ActionPoints{ap: 10, updated_at: 1000}
      assert {:ok, %ActionPoints{ap: 9}} = ActionPoints.spend(ap, 1, 1000)
    end

    test "succeeds when spending exactly remaining AP" do
      ap = %ActionPoints{ap: 3, updated_at: 1000}
      assert {:ok, %ActionPoints{ap: 0}} = ActionPoints.spend(ap, 3, 1000)
    end

    test "updates the timestamp on spend" do
      ap = %ActionPoints{ap: 10, updated_at: 1000}
      assert {:ok, %ActionPoints{updated_at: 2000}} = ActionPoints.spend(ap, 1, 2000)
    end

    test "returns exhausted when not enough AP" do
      ap = %ActionPoints{ap: 2, updated_at: 1000}
      assert {:error, :exhausted} = ActionPoints.spend(ap, 3, 1000)
    end

    test "returns exhausted at zero AP" do
      ap = %ActionPoints{ap: 0, updated_at: 1000}
      assert {:error, :exhausted} = ActionPoints.spend(ap, 1, 1000)
    end
  end

  describe "current/1" do
    test "returns the AP value" do
      assert 42 = ActionPoints.current(%ActionPoints{ap: 42, updated_at: 0})
    end
  end
end
