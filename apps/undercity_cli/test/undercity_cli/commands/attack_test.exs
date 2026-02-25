defmodule UndercityCli.Commands.AttackTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Attack
  alias UndercityCli.View.InventorySelector
  alias UndercityCli.View.TargetSelector

  @target_id "player2"
  @target_name "Zara"
  @target %{id: @target_id, name: @target_name}
  @inventory [%{name: "Iron Pipe"}, %{name: "Junk"}]
  @state_with_people %{
    @state
    | vicinity: %Vicinity{id: @block_id, people: [@target]}
  }

  describe "dispatch/6 with no target" do
    test "opens target selector and cancels" do
      expect(TargetSelector, :select, fn [@target], "Attack who?" -> :cancel end)

      assert {:continue, state} =
               Attack.dispatch("attack", @state_with_people, Gateway, MessageBuffer, InventorySelector, TargetSelector)

      assert state == @state_with_people
    end

    test "opens weapon selector after target selected, cancels" do
      expect(TargetSelector, :select, fn [@target], "Attack who?" -> {:ok, @target} end)
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> :cancel end)

      assert {:continue, state} =
               Attack.dispatch("attack", @state_with_people, Gateway, MessageBuffer, InventorySelector, TargetSelector)

      assert state == @state_with_people
    end

    test "attacks after both selectors used" do
      expect(TargetSelector, :select, fn [@target], "Attack who?" -> {:ok, @target} end)
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:ok, {:hit, @target_id, "Iron Pipe", 4}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Iron Pipe and do 4 damage." -> :ok end)

      assert {:continue, new_state} =
               Attack.dispatch("attack", @state_with_people, Gateway, MessageBuffer, InventorySelector, TargetSelector)

      assert new_state.ap == 7
    end
  end

  describe "dispatch/6 with target name" do
    test "returns continue unchanged when selector is cancelled" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> :cancel end)

      assert {:continue, state} =
               Attack.dispatch({"attack", @target_name}, @state_with_people, Gateway, MessageBuffer, InventorySelector)

      assert state == @state_with_people
    end

    test "hit: success message with weapon, damage, and updated ap" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:ok, {:hit, @target_id, "Iron Pipe", 4}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Iron Pipe and do 4 damage." -> :ok end)

      assert {:continue, new_state} =
               Attack.dispatch({"attack", @target_name}, @state_with_people, Gateway, MessageBuffer, InventorySelector)

      assert new_state.ap == 7
    end

    test "collapsed: same success message as hit" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:ok, {:collapsed, @target_id, "Iron Pipe", 4}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Iron Pipe and do 4 damage." -> :ok end)

      assert {:continue, new_state} =
               Attack.dispatch({"attack", @target_name}, @state_with_people, Gateway, MessageBuffer, InventorySelector)

      assert new_state.ap == 7
    end

    test "miss: warning message, AP spent" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:ok, {:miss, @target_id}, 7}
      end)

      expect(MessageBuffer, :warn, fn "You attack Zara and miss." -> :ok end)

      assert {:continue, new_state} =
               Attack.dispatch({"attack", @target_name}, @state_with_people, Gateway, MessageBuffer, InventorySelector)

      assert new_state.ap == 7
    end

    test "invalid weapon: warning message, state unchanged" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> {:ok, 1} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 1} ->
        {:error, :invalid_weapon}
      end)

      expect(MessageBuffer, :warn, fn "You can't attack with that." -> :ok end)

      assert {:continue, _} =
               Attack.dispatch({"attack", @target_name}, @state_with_people, Gateway, MessageBuffer, InventorySelector)
    end

    test "exhausted: standard exhaustion message" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:error, :exhausted}
      end)

      expect(MessageBuffer, :warn, fn "You are too exhausted to act." -> :ok end)

      assert {:continue, _} =
               Attack.dispatch({"attack", @target_name}, @state_with_people, Gateway, MessageBuffer, InventorySelector)
    end

    test "invalid_target: miss message, state unchanged" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:error, :invalid_target}
      end)

      expect(MessageBuffer, :warn, fn "You miss." -> :ok end)

      assert {:continue, state} =
               Attack.dispatch({"attack", @target_name}, @state_with_people, Gateway, MessageBuffer, InventorySelector)

      assert state == @state_with_people
    end

    test "target not in vicinity: miss message, state unchanged" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(InventorySelector, :select, fn @inventory, "Attack with what?" -> {:ok, 0} end)
      expect(MessageBuffer, :warn, fn "You miss." -> :ok end)

      assert {:continue, state} =
               Attack.dispatch({"attack", @target_name}, @state, Gateway, MessageBuffer, InventorySelector)

      assert state == @state
    end
  end

  describe "dispatch/6 with target and weapon index" do
    test "attacks directly without any selectors" do
      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:ok, {:hit, @target_id, "Iron Pipe", 4}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Iron Pipe and do 4 damage." -> :ok end)

      assert {:continue, new_state} =
               Attack.dispatch({"attack", "#{@target_name} 1"}, @state_with_people, Gateway, MessageBuffer)

      assert new_state.ap == 7
    end

    test "uses trailing number as weapon index, remainder as target name" do
      big_zara = %{id: "big_zara_id", name: "Big Zara"}
      state = %{@state | vicinity: %Vicinity{id: @block_id, people: [big_zara]}}

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {"big_zara_id", 1} ->
        {:ok, {:hit, "big_zara_id", "Junk", 2}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Big Zara with Junk and do 2 damage." -> :ok end)

      assert {:continue, _} =
               Attack.dispatch({"attack", "Big Zara 2"}, state, Gateway, MessageBuffer)
    end
  end
end
