defmodule UndercityCli.Commands.AttackTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Attack

  @target_id "player2"
  @target_name "Zara"
  @target %{id: @target_id, name: @target_name}
  @inventory [%{name: "Iron Pipe"}, %{name: "Junk"}]
  @state_with_people %{@state | vicinity: %Vicinity{id: @block_id, people: [@target]}}

  describe "bare attack" do
    test "nil people warns and returns model unchanged" do
      expect(MessageBuffer, :warn, fn "There is no one else here." -> :ok end)
      assert Attack.dispatch("attack", @state) == @state
    end

    test "empty people warns and returns model unchanged" do
      expect(MessageBuffer, :warn, fn "There is no one else here." -> :ok end)
      state = %{@state | vicinity: %Vicinity{id: @block_id, people: []}}
      assert Attack.dispatch("attack", state) == state
    end

    test "with people sets pending for target selection" do
      result = Attack.dispatch("attack", @state_with_people)
      assert result.pending.command == "attack"
      assert result.pending.args == []
      assert result.pending.label == "Attack who?"
      assert result.pending.choices == [@target]
    end
  end

  describe "re-dispatch after target overlay" do
    test "sets pending for weapon selection" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      result = Attack.dispatch({"attack", 0}, @state_with_people)
      assert result.pending.command == "attack"
      assert result.pending.args == [@target_name]
      assert result.pending.label == "Attack with what?"
      assert result.pending.choices == @inventory
    end

    test "empty inventory warns and returns model unchanged" do
      expect(Gateway, :check_inventory, fn @player_id -> [] end)
      expect(MessageBuffer, :warn, fn "You have nothing to attack with." -> :ok end)
      assert Attack.dispatch({"attack", 0}, @state_with_people) == @state_with_people
    end
  end

  describe "fully specified attack" do
    test "hit: success message with weapon, damage, and updated ap" do
      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0, _} ->
        {:ok, {:hit, @target_id, "Iron Pipe", 4}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Iron Pipe and do 4 damage." -> :ok end)
      result = Attack.dispatch({"attack", @target_name, 0}, @state_with_people)
      assert result.ap == 7
    end

    test "miss: warning message, ap spent" do
      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0, _} ->
        {:ok, {:miss, @target_id}, 7}
      end)

      expect(MessageBuffer, :warn, fn "You attack Zara and miss." -> :ok end)
      result = Attack.dispatch({"attack", @target_name, 0}, @state_with_people)
      assert result.ap == 7
    end

    test "invalid weapon: warning, model unchanged" do
      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 1, _} ->
        {:error, :invalid_weapon}
      end)

      expect(MessageBuffer, :warn, fn "You can't attack with that." -> :ok end)
      assert Attack.dispatch({"attack", @target_name, 1}, @state_with_people) == @state_with_people
    end

    test "exhausted: standard exhaustion message" do
      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0, _} ->
        {:error, :exhausted}
      end)

      expect(MessageBuffer, :warn, fn "You are too exhausted to act." -> :ok end)
      assert Attack.dispatch({"attack", @target_name, 0}, @state_with_people) == @state_with_people
    end

    test "target not in vicinity: miss message, model unchanged" do
      expect(MessageBuffer, :warn, fn "You miss." -> :ok end)
      assert Attack.dispatch({"attack", @target_name, 0}, @state) == @state
    end
  end

  describe "string weapon index" do
    test "valid index executes attack" do
      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0, _} ->
        {:ok, {:hit, @target_id, "Iron Pipe", 4}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Iron Pipe and do 4 damage." -> :ok end)
      result = Attack.dispatch({"attack", @target_name, "1"}, @state_with_people)
      assert result.ap == 7
    end

    test "non-numeric index falls back to weapon selection" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      result = Attack.dispatch({"attack", @target_name, "notanumber"}, @state_with_people)
      assert result.pending.command == "attack"
      assert result.pending.args == [@target_name]
    end

    test "zero index falls back to weapon selection" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      result = Attack.dispatch({"attack", @target_name, "0"}, @state_with_people)
      assert result.pending.command == "attack"
      assert result.pending.args == [@target_name]
    end
  end

  describe "typed attack with rest string" do
    test "attack goblin 1 executes directly without overlay" do
      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 0, _} ->
        {:ok, {:hit, @target_id, "Iron Pipe", 4}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Iron Pipe and do 4 damage." -> :ok end)
      result = Attack.dispatch({"attack", "#{@target_name} 1"}, @state_with_people)
      assert result.ap == 7
    end

    test "attack goblin sets up weapon selection overlay" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      result = Attack.dispatch({"attack", @target_name}, @state_with_people)
      assert result.pending.command == "attack"
      assert result.pending.args == [@target_name]
    end

    test "uses trailing number as weapon index" do
      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {@target_id, 1, _} ->
        {:ok, {:hit, @target_id, "Junk", 2}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Junk and do 2 damage." -> :ok end)
      result = Attack.dispatch({"attack", "#{@target_name} 2"}, @state_with_people)
      assert result.ap == 7
    end
  end
end
