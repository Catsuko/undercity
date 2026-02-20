defmodule UndercityCli.GameStateTest do
  use ExUnit.Case, async: true

  alias UndercityCli.GameState

  setup do
    state = %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}
    {:ok, state: state}
  end

  describe "acted/1" do
    test "returns :acted tag with unchanged state", %{state: state} do
      assert {:continue, ^state} = GameState.continue(state)
    end
  end

  describe "acted/3" do
    test "returns :acted tag with updated ap and hp", %{state: state} do
      assert {:continue, new_state} = GameState.continue(state, 8, 9)
      assert new_state.ap == 8
      assert new_state.hp == 9
      assert new_state.vicinity == state.vicinity
      assert new_state.player_id == state.player_id
    end
  end

  describe "moved/4" do
    test "returns :moved tag with updated vicinity, ap and hp", %{state: state} do
      new_vicinity = %{id: "block2"}

      assert {:moved, new_state} = GameState.moved(state, new_vicinity, 8, 9)
      assert new_state.vicinity == new_vicinity
      assert new_state.ap == 8
      assert new_state.hp == 9
      assert new_state.player_id == state.player_id
    end
  end
end
