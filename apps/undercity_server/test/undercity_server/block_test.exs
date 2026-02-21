defmodule UndercityServer.BlockTest do
  use ExUnit.Case, async: true

  alias UndercityServer.Block
  alias UndercityServer.Test.Helpers

  setup do
    id = Helpers.start_block!()
    %{id: id}
  end

  describe "info/1" do
    test "returns block id and people", %{id: id} do
      {block_id, people} = Block.info(id)

      assert block_id == id
      assert people == []
    end
  end

  describe "join/2" do
    test "adds a player id to the block", %{id: id} do
      player_id = "player_#{:rand.uniform(100_000)}"

      {block_id, people} = Block.join(id, player_id)

      assert block_id == id
      assert length(people) == 1
      assert player_id in people
    end

    test "multiple players can join", %{id: id} do
      player1 = "player_#{:rand.uniform(100_000)}"
      player2 = "player_#{:rand.uniform(100_000)}"

      Block.join(id, player1)
      Block.join(id, player2)

      {_id, people} = Block.info(id)
      assert length(people) == 2
    end
  end

  describe "leave/2" do
    test "removes a player id from the block", %{id: id} do
      player_id = "player_#{:rand.uniform(100_000)}"
      Block.join(id, player_id)

      assert :ok = Block.leave(id, player_id)

      {_id, people} = Block.info(id)
      assert people == []
    end

    test "other players remain after someone leaves", %{id: id} do
      player1 = "player_#{:rand.uniform(100_000)}"
      player2 = "player_#{:rand.uniform(100_000)}"
      Block.join(id, player1)
      Block.join(id, player2)

      Block.leave(id, player1)

      {_id, people} = Block.info(id)
      assert length(people) == 1
      assert player2 in people
    end
  end

  describe "search/1" do
    test "returns :nothing or {:found, item}", %{id: id} do
      result = Block.search(id)

      assert result == :nothing or match?({:found, _item}, result)
    end
  end

  describe "scribble/2" do
    test "sets a scribble on the block", %{id: id} do
      assert :ok = Block.scribble(id, "hello world")
      assert "hello world" = Block.get_scribble(id)
    end

    test "overwrites an existing scribble", %{id: id} do
      Block.scribble(id, "first")
      Block.scribble(id, "second")

      assert "second" = Block.get_scribble(id)
    end

    test "scribble defaults to nil", %{id: id} do
      assert nil == Block.get_scribble(id)
    end
  end

  describe "has_person?/2" do
    test "returns true when player is in the block", %{id: id} do
      player_id = "player_#{:rand.uniform(100_000)}"
      Block.join(id, player_id)

      assert Block.has_person?(id, player_id)
    end

    test "returns false when player is not in the block", %{id: id} do
      refute Block.has_person?(id, "nonexistent")
    end
  end
end
