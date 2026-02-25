defmodule UndercityServer.PlayerIdleTest do
  use ExUnit.Case, async: true

  alias UndercityCore.ActionPoints
  alias UndercityCore.Health
  alias UndercityCore.Inventory
  alias UndercityServer.Player
  alias UndercityServer.Player.Store, as: PlayerStore
  alias UndercityServer.Player.Supervisor, as: PlayerSupervisor
  alias UndercityServer.Test.Helpers

  describe "idle timeout" do
    setup do
      %{id: Helpers.start_player!()}
    end

    test "player process exits normally when idle", %{id: id} do
      pid = GenServer.whereis(:"player_#{id}")
      ref = Process.monitor(pid)

      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 500
    end
  end

  describe "on-demand start" do
    test "calling Player transparently starts an inactive process" do
      id = "player_#{:erlang.unique_integer([:positive])}"

      PlayerStore.save(id, %{
        id: id,
        name: "Grimshaw",
        inventory: Inventory.new(),
        action_points: ActionPoints.new(),
        health: Health.new(),
        block_id: nil
      })

      on_exit(fn -> :dets.delete(:player_store, id) end)

      assert Player.constitution(id).hp == 50
    end
  end

  describe "reconnect after idle shutdown" do
    test "PlayerSupervisor can restart a stopped player" do
      id = "player_#{:erlang.unique_integer([:positive])}"
      :dets.delete(:player_store, id)
      on_exit(fn -> :dets.delete(:player_store, id) end)

      {:ok, pid} = PlayerSupervisor.start_player(id, "Test Player")
      ref = Process.monitor(pid)

      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}, 500

      assert {:ok, new_pid} = PlayerSupervisor.start_player(id, "Test Player")
      assert new_pid != pid
    end
  end
end
