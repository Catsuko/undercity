defmodule UndercityServer.Player.StoreTest do
  use ExUnit.Case

  alias UndercityServer.Player.Store, as: PlayerStore

  defp player_id, do: "store_test_#{:erlang.unique_integer([:positive])}"

  defp player_data(name) do
    %{
      id: player_id(),
      name: name,
      inventory: UndercityCore.Inventory.new(),
      action_points: UndercityCore.ActionPoints.new(),
      health: UndercityCore.Health.new()
    }
  end

  setup do
    on_exit(fn -> :ok end)
  end

  describe "register/2" do
    test "saves and returns :ok for a valid alphanumeric name" do
      id = player_id()
      data = player_data("Grimshaw")
      assert :ok = PlayerStore.register(id, data)
      :dets.delete(:player_store, id)
    end

    test "saves and returns :ok for numbers in name" do
      id = player_id()
      data = player_data("player42")
      assert :ok = PlayerStore.register(id, data)
      :dets.delete(:player_store, id)
    end

    test "returns :invalid_name for a name with spaces" do
      assert {:error, :invalid_name} = PlayerStore.register(player_id(), player_data("Big Zara"))
    end

    test "returns :invalid_name for a name with special characters" do
      assert {:error, :invalid_name} = PlayerStore.register(player_id(), player_data("zara!"))
    end

    test "returns :invalid_name for an empty name" do
      assert {:error, :invalid_name} = PlayerStore.register(player_id(), player_data(""))
    end
  end
end
