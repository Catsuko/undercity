defmodule UndercityServer.Actions.SearchTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityServer.Actions.Search
  alias UndercityServer.Block.Supervisor, as: BlockSupervisor
  alias UndercityServer.Player

  # :graveyard has [{0.20, "Mushroom"}] — roll < 0.20 finds, roll >= 0.20 misses
  defp always_finds, do: fn -> 0.05 end
  defp always_misses, do: fn -> 0.99 end

  defp unique_id, do: "test_#{:rand.uniform(100_000_000)}"

  defp start_block(random_fn) do
    block_id = unique_id()

    start_supervised!(
      {BlockSupervisor, %{id: block_id, name: "Test Block", type: :graveyard, exits: %{}, random: random_fn}},
      id: block_id
    )

    on_exit(fn ->
      File.rm(Path.join([File.cwd!(), "data", "blocks", "#{block_id}.dets"]))
    end)

    block_id
  end

  setup do
    player_id = unique_id()
    start_supervised!({Player, id: player_id, name: "test_#{player_id}"}, id: player_id)

    on_exit(fn ->
      File.rm(Path.join([File.cwd!(), "data", "players", "players.dets"]))
    end)

    %{player_id: player_id}
  end

  describe "search/2" do
    test "adds found item to the player's inventory", %{player_id: player_id} do
      block_id = start_block(always_finds())

      assert {:ok, {:found, %Item{name: "Mushroom"}}, _ap} =
               Search.search(player_id, block_id)

      assert [%Item{name: "Mushroom"}] = Player.check_inventory(player_id)
    end

    test "returns :nothing and does not change inventory when roll misses", %{
      player_id: player_id
    } do
      block_id = start_block(always_misses())

      assert {:ok, :nothing, _ap} = Search.search(player_id, block_id)
      assert [] = Player.check_inventory(player_id)
    end

    test "returns {:found_but_full, item} and does not add item when inventory is full", %{
      player_id: player_id
    } do
      block_id = start_block(always_finds())
      for _ <- 1..15, do: Player.add_item(player_id, Item.new("Junk"))

      assert {:ok, {:found_but_full, %Item{name: "Mushroom"}}, _ap} =
               Search.search(player_id, block_id)

      inventory = Player.check_inventory(player_id)
      assert length(inventory) == 15
      assert Enum.all?(inventory, &match?(%Item{name: "Junk"}, &1))
    end

    test "returns :exhausted when player has no AP", %{player_id: player_id} do
      block_id = start_block(always_finds())
      for _ <- 1..50, do: Player.perform(player_id, fn -> :ok end)

      assert {:error, :exhausted} = Search.search(player_id, block_id)
    end
  end
end
