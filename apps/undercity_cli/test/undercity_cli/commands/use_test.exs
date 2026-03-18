defmodule UndercityCli.Commands.UseTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Use

  @salve %{name: "Salve"}
  @junk %{name: "Junk"}
  @inventory [@salve, @junk]

  @target_id "player2"
  @target_name "Zara"
  @target %{id: @target_id, name: @target_name}
  @self %{id: @player_id, name: "player1"}

  @state_with_people %{@state | vicinity: %Vicinity{id: @block_id, people: [@self, @target]}}

  describe "bare use" do
    test "with empty inventory warns and returns state unchanged" do
      expect(Gateway, :check_inventory, fn @player_id -> [] end)
      expect(MessageBuffer, :warn, fn "Your inventory is empty." -> :ok end)
      assert Use.dispatch("use", @state) == @state
    end

    test "with items opens item selection overlay" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      result = Use.dispatch("use", @state_with_people)
      assert result.selection.label == "Use which item?"
      assert result.selection.choices == @inventory
    end
  end

  describe "re-dispatch after inventory selector" do
    test "opens target selector" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      result = Use.dispatch({"use", 0}, @state_with_people)
      assert result.selection.label == "Use on who?"
      assert result.selection.choices == [@self, @target]
    end

    test "out-of-range index warns and returns state unchanged" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert Use.dispatch({"use", 5}, @state_with_people) == @state_with_people
    end
  end

  describe "selector path — self-heal" do
    test "success: updates ap and hp" do
      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@player_id, 0, "player1"} ->
        {:ok, {:healed, @player_id, 9, 15}}
      end)

      expect(MessageBuffer, :success, fn "You healed yourself for 15." -> :ok end)
      result = Use.dispatch({"use", 0, 0}, @state_with_people)
      assert result.ap == 9
      assert result.hp == @state_with_people.hp + 15
    end

    test "heals 0 when already full: ap spent, hp unchanged" do
      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@player_id, 0, "player1"} ->
        {:ok, {:healed, @player_id, 9, 0}}
      end)

      expect(MessageBuffer, :success, fn "You healed yourself for 0." -> :ok end)
      result = Use.dispatch({"use", 0, 0}, @state_with_people)
      assert result.ap == 9
      assert result.hp == @state_with_people.hp
    end

    test "collapsed uses uniform message" do
      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@player_id, 0, "player1"} ->
        {:error, :collapsed}
      end)

      expect(MessageBuffer, :warn, fn "Your body has given out." -> :ok end)
      assert Use.dispatch({"use", 0, 0}, @state_with_people) == @state_with_people
    end

    test "item missing warns" do
      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@player_id, 0, "player1"} ->
        {:error, :item_missing}
      end)

      expect(MessageBuffer, :warn, fn "You don't have that anymore." -> :ok end)
      assert Use.dispatch({"use", 0, 0}, @state_with_people) == @state_with_people
    end

    test "exhausted uses uniform message" do
      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@player_id, 0, "player1"} ->
        {:error, :exhausted}
      end)

      expect(MessageBuffer, :warn, fn "You are too exhausted to act." -> :ok end)
      assert Use.dispatch({"use", 0, 0}, @state_with_people) == @state_with_people
    end
  end

  describe "selector path — other-heal" do
    test "success: updates ap only (not hp)" do
      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@target_id, 0, "player1"} ->
        {:ok, {:healed, @target_id, 9, 15}}
      end)

      expect(MessageBuffer, :success, fn "You healed Zara for 15." -> :ok end)
      result = Use.dispatch({"use", 0, 1}, @state_with_people)
      assert result.ap == 9
      assert result.hp == @state_with_people.hp
    end

    test "heals 0 when target already full: ap spent" do
      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@target_id, 0, "player1"} ->
        {:ok, {:healed, @target_id, 9, 0}}
      end)

      expect(MessageBuffer, :success, fn "You healed Zara for 0." -> :ok end)
      result = Use.dispatch({"use", 0, 1}, @state_with_people)
      assert result.ap == 9
    end

    test "collapsed target: returns invalid_target" do
      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@target_id, 0, "player1"} ->
        {:error, :invalid_target}
      end)

      expect(MessageBuffer, :warn, fn "Zara can't be healed." -> :ok end)
      assert Use.dispatch({"use", 0, 1}, @state_with_people) == @state_with_people
    end

    test "item missing warns" do
      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@target_id, 0, "player1"} ->
        {:error, :item_missing}
      end)

      expect(MessageBuffer, :warn, fn "You don't have that anymore." -> :ok end)
      assert Use.dispatch({"use", 0, 1}, @state_with_people) == @state_with_people
    end
  end

  describe "typed use — use <n>" do
    test "resolves item and opens target selector" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      result = Use.dispatch({"use", "1"}, @state_with_people)
      assert result.selection.label == "Use on who?"
    end

    test "out-of-range index warns" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert Use.dispatch({"use", "9"}, @state_with_people) == @state_with_people
    end

    test "zero index warns" do
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert Use.dispatch({"use", "0"}, @state_with_people) == @state_with_people
    end
  end

  describe "typed use — use <n> <target>" do
    test "executes directly: self-heal" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)

      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@player_id, 0, "player1"} ->
        {:ok, {:healed, @player_id, 9, 15}}
      end)

      expect(MessageBuffer, :success, fn "You healed yourself for 15." -> :ok end)
      result = Use.dispatch({"use", "1 player1"}, @state_with_people)
      assert result.ap == 9
      assert result.hp == @state_with_people.hp + 15
    end

    test "executes directly: other-heal" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)

      expect(Gateway, :perform, fn @player_id, @block_id, :heal, {@target_id, 0, "player1"} ->
        {:ok, {:healed, @target_id, 9, 15}}
      end)

      expect(MessageBuffer, :success, fn "You healed Zara for 15." -> :ok end)
      result = Use.dispatch({"use", "1 #{@target_name}"}, @state_with_people)
      assert result.ap == 9
    end

    test "target not in vicinity warns" do
      expect(Gateway, :check_inventory, fn @player_id -> @inventory end)
      expect(MessageBuffer, :warn, fn "Unknown can't be healed." -> :ok end)
      assert Use.dispatch({"use", "1 Unknown"}, @state_with_people) == @state_with_people
    end
  end
end
