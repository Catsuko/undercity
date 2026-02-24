defmodule UndercityCore.PlayerTest do
  use ExUnit.Case, async: true

  alias UndercityCore.ActionPoints
  alias UndercityCore.Health
  alias UndercityCore.Inventory
  alias UndercityCore.Item
  alias UndercityCore.Player

  @now 100_000

  defp player_with_ap(ap) do
    %Player{
      id: "p1",
      name: "Test",
      inventory: Inventory.new(),
      action_points: %ActionPoints{ap: ap, updated_at: @now},
      health: Health.new()
    }
  end

  defp player_with_hp(hp) do
    %Player{
      id: "p1",
      name: "Test",
      inventory: Inventory.new(),
      action_points: %ActionPoints{ap: 50, updated_at: @now},
      health: %Health{hp: hp}
    }
  end

  describe "new/2" do
    test "returns a player with correct id and name" do
      player = Player.new("p1", "Alice")
      assert player.id == "p1"
      assert player.name == "Alice"
    end

    test "starts with a full inventory, max AP, and max HP" do
      player = Player.new("p1", "Alice")
      assert ActionPoints.current(player.action_points) == ActionPoints.max()
      assert Health.current(player.health) == Health.max()
      assert Inventory.list_items(player.inventory) == []
    end
  end

  describe "exert/3" do
    test "spends AP when player is healthy and has enough AP" do
      player = player_with_ap(10)
      assert {:ok, %Player{} = result} = Player.exert(player, 1, @now)
      assert ActionPoints.current(result.action_points) == 9
    end

    test "returns exhausted when not enough AP" do
      player = player_with_ap(0)
      assert {:error, :exhausted} = Player.exert(player, 1, @now)
    end

    test "returns collapsed when HP is zero" do
      player = player_with_hp(0)
      assert {:error, :collapsed} = Player.exert(player, 1, @now)
    end

    test "collapsed takes priority over exhausted" do
      player = %{player_with_hp(0) | action_points: %ActionPoints{ap: 0, updated_at: @now}}
      assert {:error, :collapsed} = Player.exert(player, 1, @now)
    end
  end

  describe "drop/3" do
    setup do
      item = Item.new("Sword")
      player = player_with_ap(10)
      {:ok, inventory} = Inventory.add_item(player.inventory, item)
      {:ok, player: %{player | inventory: inventory}, item: item}
    end

    test "removes the item and returns its name", %{player: player, item: item} do
      assert {:ok, result, item_name} = Player.drop(player, 0, @now)
      assert item_name == item.name
      assert Inventory.list_items(result.inventory) == []
    end

    test "spends 1 AP on success", %{player: player} do
      assert {:ok, result, _name} = Player.drop(player, 0, @now)
      assert ActionPoints.current(result.action_points) == 9
    end

    test "returns invalid_index for an out-of-bounds index", %{player: player} do
      assert {:error, :invalid_index} = Player.drop(player, 5, @now)
    end

    test "returns exhausted when out of AP" do
      item = Item.new("Sword")
      {:ok, inventory} = Inventory.add_item(Inventory.new(), item)
      player = %{player_with_ap(0) | inventory: inventory}
      assert {:error, :exhausted} = Player.drop(player, 0, @now)
    end

    test "returns collapsed when HP is zero", %{player: player} do
      player = %{player | health: %Health{hp: 0}}
      assert {:error, :collapsed} = Player.drop(player, 0, @now)
    end
  end

  describe "eat/3" do
    setup do
      mushroom = Item.new("Mushroom")
      rock = Item.new("Rock")
      player = player_with_ap(10)
      {:ok, inv1} = Inventory.add_item(player.inventory, mushroom)
      {:ok, inv2} = Inventory.add_item(inv1, rock)
      {:ok, player: %{player | inventory: inv2}, mushroom: mushroom, rock: rock}
    end

    test "applies a health effect and removes the item", %{player: player} do
      assert {:ok, result, item, effect} = Player.eat(player, 0, @now)
      assert item.name == "Mushroom"
      assert effect in [{:heal, 5}, {:damage, 5}]
      assert length(Inventory.list_items(result.inventory)) == 1
    end

    test "spends 1 AP on success", %{player: player} do
      assert {:ok, result, _item, _effect} = Player.eat(player, 0, @now)
      assert ActionPoints.current(result.action_points) == 9
    end

    test "returns not_edible for a non-food item", %{player: player} do
      assert {:error, :not_edible, "Rock"} = Player.eat(player, 1, @now)
    end

    test "does not spend AP when item is not edible", %{player: player} do
      Player.eat(player, 1, @now)
      assert ActionPoints.current(player.action_points) == 10
    end

    test "returns invalid_index for an out-of-bounds index", %{player: player} do
      assert {:error, :invalid_index} = Player.eat(player, 5, @now)
    end

    test "returns exhausted when out of AP", %{player: player} do
      player = %{player | action_points: %ActionPoints{ap: 0, updated_at: @now}}
      assert {:error, :exhausted} = Player.eat(player, 0, @now)
    end

    test "returns collapsed when HP is zero", %{player: player} do
      player = %{player | health: %Health{hp: 0}}
      assert {:error, :collapsed} = Player.eat(player, 0, @now)
    end
  end
end
