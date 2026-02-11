defmodule UndercityServer.BlockTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Person
  alias UndercityServer.Block
  alias UndercityServer.BlockSupervisor

  setup do
    id = "block_#{:rand.uniform(100_000)}"

    start_supervised!(
      {BlockSupervisor, %{id: id, name: "Test Block", type: :street, exits: %{}}},
      id: id
    )

    on_exit(fn ->
      path = Path.join([File.cwd!(), "data", "blocks", "#{id}.dets"])
      File.rm(path)
    end)

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
    test "adds a person to the block", %{id: id} do
      person = Person.new("Grimshaw")

      {block_id, people} = Block.join(id, person)

      assert block_id == id
      assert length(people) == 1
      assert hd(people).name == "Grimshaw"
    end

    test "multiple people can join", %{id: id} do
      person1 = Person.new("Grimshaw")
      person2 = Person.new("Mordecai")

      Block.join(id, person1)
      Block.join(id, person2)

      {_id, people} = Block.info(id)
      assert length(people) == 2
    end
  end

  describe "leave/2" do
    test "removes a person from the block", %{id: id} do
      person = Person.new("Grimshaw")
      Block.join(id, person)

      assert :ok = Block.leave(id, person)

      {_id, people} = Block.info(id)
      assert people == []
    end

    test "other people remain after someone leaves", %{id: id} do
      grimshaw = Person.new("Grimshaw")
      mordecai = Person.new("Mordecai")
      Block.join(id, grimshaw)
      Block.join(id, mordecai)

      Block.leave(id, grimshaw)

      {_id, people} = Block.info(id)
      assert length(people) == 1
      assert hd(people).name == "Mordecai"
    end
  end
end
