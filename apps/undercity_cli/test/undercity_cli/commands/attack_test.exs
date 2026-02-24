defmodule UndercityCli.Commands.AttackTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Attack
  alias UndercityCli.View.InventorySelector

  @target_id "player2"
  @target_name "Zara"
  @inventory [%{name: "Iron Pipe"}, %{name: "Junk"}]
  @state_with_people %{
    @state
    | vicinity: %{id: @block_id, people: [%{id: @target_id, name: @target_name}]}
  }

  describe "dispatch/5 with no target" do
    test "warns to specify a target" do
      expect(MessageBuffer, :warn, fn "Attack who?" -> :ok end)
      assert {:continue, _} = Attack.dispatch("attack", @state_with_people, Gateway, MessageBuffer)
    end
  end

  describe "dispatch/5 with target name" do
    test "warns when target not in vicinity" do
      expect(MessageBuffer, :warn, fn "Ghost is not here." -> :ok end)

      assert {:continue, _} =
               Attack.dispatch({"attack", "Ghost"}, @state_with_people, Gateway, MessageBuffer)
    end

    test "warns when target is self" do
      self_state = %{
        @state
        | vicinity: %{id: @block_id, people: [%{id: @player_id, name: "Me"}]}
      }

      expect(MessageBuffer, :warn, fn "You can't attack yourself." -> :ok end)
      assert {:continue, _} = Attack.dispatch({"attack", "Me"}, self_state, Gateway, MessageBuffer)
    end

    test "returns continue unchanged when selector is cancelled" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)

      expect(InventorySelector, :select, fn @inventory, "Attack with which weapon?" -> :cancel end)

      assert {:continue, state} =
               Attack.dispatch(
                 {"attack", @target_name},
                 @state_with_people,
                 Gateway,
                 MessageBuffer,
                 InventorySelector
               )

      assert state == @state_with_people
    end

    test "hit: success message with weapon, damage, and updated ap" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)

      expect(InventorySelector, :select, fn @inventory, "Attack with which weapon?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:ok, {:hit, @target_name, "Iron Pipe", 4}, 7}
      end)

      expect(MessageBuffer, :success, fn "You strike Zara with Iron Pipe for 4 damage." -> :ok end)

      assert {:continue, new_state} =
               Attack.dispatch(
                 {"attack", @target_name},
                 @state_with_people,
                 Gateway,
                 MessageBuffer,
                 InventorySelector
               )

      assert new_state.ap == 7
    end

    test "collapsed: same success message as hit" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)

      expect(InventorySelector, :select, fn @inventory, "Attack with which weapon?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:ok, {:collapsed, @target_name, "Iron Pipe", 4}, 7}
      end)

      expect(MessageBuffer, :success, fn "You strike Zara with Iron Pipe for 4 damage." -> :ok end)

      assert {:continue, new_state} =
               Attack.dispatch(
                 {"attack", @target_name},
                 @state_with_people,
                 Gateway,
                 MessageBuffer,
                 InventorySelector
               )

      assert new_state.ap == 7
    end

    test "miss: warning message and updated ap" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)

      expect(InventorySelector, :select, fn @inventory, "Attack with which weapon?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:ok, {:miss, @target_name}, 7}
      end)

      expect(MessageBuffer, :warn, fn "You swing at Zara but miss." -> :ok end)

      assert {:continue, new_state} =
               Attack.dispatch(
                 {"attack", @target_name},
                 @state_with_people,
                 Gateway,
                 MessageBuffer,
                 InventorySelector
               )

      assert new_state.ap == 7
    end

    test "invalid weapon: warning message, state unchanged" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)

      expect(InventorySelector, :select, fn @inventory, "Attack with which weapon?" -> {:ok, 1} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 1} ->
        {:error, :invalid_weapon}
      end)

      expect(MessageBuffer, :warn, fn "You can't attack with that." -> :ok end)

      assert {:continue, _} =
               Attack.dispatch(
                 {"attack", @target_name},
                 @state_with_people,
                 Gateway,
                 MessageBuffer,
                 InventorySelector
               )
    end

    test "exhausted: standard exhaustion message" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)

      expect(InventorySelector, :select, fn @inventory, "Attack with which weapon?" -> {:ok, 0} end)

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0} ->
        {:error, :exhausted}
      end)

      expect(MessageBuffer, :warn, fn "You are too exhausted to act." -> :ok end)

      assert {:continue, _} =
               Attack.dispatch(
                 {"attack", @target_name},
                 @state_with_people,
                 Gateway,
                 MessageBuffer,
                 InventorySelector
               )
    end
  end
end
