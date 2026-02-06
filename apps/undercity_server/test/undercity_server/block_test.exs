defmodule UndercityServer.BlockTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Person
  alias UndercityServer.Block

  setup do
    id = "block_#{:rand.uniform(100_000)}"

    start_supervised!(
      {Block, id: id, name: "Test Block", description: "A test block."},
      id: id
    )

    %{id: id}
  end

  describe "info/1" do
    test "returns block info", %{id: id} do
      info = Block.info(id)

      assert info.id == id
      assert info.name == "Test Block"
      assert info.description == "A test block."
      assert info.people == []
    end
  end

  describe "join/2" do
    test "adds a person to the block", %{id: id} do
      person = Person.new("Grimshaw")

      assert :ok = Block.join(id, person)

      info = Block.info(id)
      assert length(info.people) == 1
      assert hd(info.people).name == "Grimshaw"
    end

    test "multiple people can join", %{id: id} do
      person1 = Person.new("Grimshaw")
      person2 = Person.new("Mordecai")

      Block.join(id, person1)
      Block.join(id, person2)

      info = Block.info(id)
      assert length(info.people) == 2
    end
  end
end
