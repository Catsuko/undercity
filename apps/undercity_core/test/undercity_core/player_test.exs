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

  describe "exert/3 (atom action)" do
    test "spends 1 AP when action is an atom" do
      player = player_with_ap(10)
      assert {:ok, result} = Player.exert(player, :scribble, @now)
      assert ActionPoints.current(result.action_points) == 9
    end

    test "returns exhausted when not enough AP" do
      player = player_with_ap(0)
      assert {:error, :exhausted} = Player.exert(player, :scribble, @now)
    end

    test "returns collapsed when HP is zero" do
      player = player_with_hp(0)
      assert {:error, :collapsed} = Player.exert(player, :scribble, @now)
    end
  end

  describe "exert_using/3" do
    setup do
      chalk = Item.build(:chalk)
      player = player_with_ap(10)
      {:ok, inventory} = Inventory.add_item(player.inventory, chalk)
      {:ok, player: %{player | inventory: inventory}}
    end

    test "returns {:ok, player} and decrements item uses", %{player: player} do
      assert {:ok, result} = Player.exert_using(player, :chalk, @now)
      assert [%Item{id: :chalk, uses: 4}] = Inventory.list_items(result.inventory)
    end

    test "spends 1 AP on success", %{player: player} do
      assert {:ok, result} = Player.exert_using(player, :chalk, @now)
      assert ActionPoints.current(result.action_points) == 9
    end

    test "removes item when last use is spent" do
      chalk = Item.build(:chalk, 1)
      player = player_with_ap(10)
      {:ok, inventory} = Inventory.add_item(player.inventory, chalk)
      player = %{player | inventory: inventory}

      assert {:ok, result} = Player.exert_using(player, :chalk, @now)
      assert [] = Inventory.list_items(result.inventory)
    end

    test "non-consumable item remains in inventory" do
      pipe = Item.build(:iron_pipe)
      player = player_with_ap(10)
      {:ok, inventory} = Inventory.add_item(player.inventory, pipe)
      player = %{player | inventory: inventory}

      assert {:ok, result} = Player.exert_using(player, :iron_pipe, @now)
      assert [%Item{id: :iron_pipe}] = Inventory.list_items(result.inventory)
    end

    test "returns :item_missing when item not in inventory" do
      player = player_with_ap(10)
      assert {:error, :item_missing} = Player.exert_using(player, :chalk, @now)
    end

    test "does not spend AP when item is absent" do
      player = player_with_ap(10)
      assert {:error, :item_missing} = Player.exert_using(player, :chalk, @now)
      assert ActionPoints.current(player.action_points) == 10
    end

    test "returns :exhausted when AP insufficient, item use not consumed", %{player: player} do
      player = %{player | action_points: %ActionPoints{ap: 0, updated_at: @now}}
      assert {:error, :exhausted} = Player.exert_using(player, :chalk, @now)
      assert [%Item{id: :chalk, uses: 5}] = Inventory.list_items(player.inventory)
    end

    test "returns :collapsed when HP is zero, item use not consumed", %{player: player} do
      player = %{player | health: %Health{hp: 0}}
      assert {:error, :collapsed} = Player.exert_using(player, :chalk, @now)
      assert [%Item{id: :chalk, uses: 5}] = Inventory.list_items(player.inventory)
    end
  end

  describe "drop/3" do
    setup do
      item = Item.build(:iron_pipe)
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
      item = Item.build(:iron_pipe)
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
      mushroom = Item.build(:mushroom)
      junk = Item.build(:junk)
      player = player_with_ap(10)
      {:ok, inv1} = Inventory.add_item(player.inventory, mushroom)
      {:ok, inv2} = Inventory.add_item(inv1, junk)
      {:ok, player: %{player | inventory: inv2}, mushroom: mushroom, junk: junk}
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
      assert {:error, :not_edible, "Junk"} = Player.eat(player, 1, @now)
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
