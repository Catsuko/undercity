defmodule UndercityServer.Actions.SearchTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityServer.Actions.Search
  alias UndercityServer.Player
  alias UndercityServer.Test.Helpers

  # :graveyard has [{0.20, "Mushroom"}] — roll < 0.20 finds, roll >= 0.20 misses
  defp always_finds, do: fn -> 0.05 end
  defp always_misses, do: fn -> 0.99 end

  defp start_block(random_fn) do
    Helpers.start_block!(type: :graveyard, random: random_fn)
  end

  setup do
    player_id = Helpers.start_player!()
    %{player_id: player_id}
  end

  describe "search/2" do
    test "adds found item to the player's inventory and returns ap", %{player_id: player_id} do
      block_id = start_block(always_finds())

      assert {:ok, _ap} = Search.search(player_id, block_id)

      assert [%Item{name: "Mushroom"}] = Player.check_inventory(player_id)
    end

    test "sends :found inbox message with item name", %{player_id: player_id} do
      block_id = start_block(always_finds())
      :timer.sleep(10)
      Player.fetch_inbox(player_id)

      Search.search(player_id, block_id)
      :timer.sleep(10)

      assert [{:success, "You found Mushroom!"}] = Player.fetch_inbox(player_id)
    end

    test "returns ap and does not change inventory when roll misses", %{player_id: player_id} do
      block_id = start_block(always_misses())

      assert {:ok, _ap} = Search.search(player_id, block_id)
      assert [] = Player.check_inventory(player_id)
    end

    test "sends :nothing inbox message on miss", %{player_id: player_id} do
      block_id = start_block(always_misses())
      :timer.sleep(10)
      Player.fetch_inbox(player_id)

      Search.search(player_id, block_id)
      :timer.sleep(10)

      assert [{:warning, "You find nothing."}] = Player.fetch_inbox(player_id)
    end

    test "does not add item when inventory is full", %{player_id: player_id} do
      block_id = start_block(always_finds())
      for _ <- 1..15, do: Player.add_item(player_id, Item.new("Junk"))

      assert {:ok, _ap} = Search.search(player_id, block_id)

      inventory = Player.check_inventory(player_id)
      assert length(inventory) == 15
      assert Enum.all?(inventory, &match?(%Item{name: "Junk"}, &1))
    end

    test "sends :found_but_full inbox message when inventory is full", %{player_id: player_id} do
      block_id = start_block(always_finds())
      for _ <- 1..15, do: Player.add_item(player_id, Item.new("Junk"))
      :timer.sleep(10)
      Player.fetch_inbox(player_id)

      Search.search(player_id, block_id)
      :timer.sleep(10)

      assert [{:warning, "You found Mushroom, but your inventory is full."}] = Player.fetch_inbox(player_id)
    end

    test "returns :exhausted when player has no AP", %{player_id: player_id} do
      block_id = start_block(always_finds())
      for _ <- 1..50, do: Player.perform(player_id, fn -> :ok end)

      assert {:error, :exhausted} = Search.search(player_id, block_id)
    end
  end
end
