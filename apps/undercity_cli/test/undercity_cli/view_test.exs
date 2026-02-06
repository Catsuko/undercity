defmodule UndercityCli.ViewTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View
  alias UndercityCore.Person

  describe "describe_block/2" do
    test "includes description and people" do
      block_info = %{
        description: "The central gathering place.",
        people: [Person.new("Grimshaw"), Person.new("Mordecai")]
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "The central gathering place."
      assert result =~ "Mordecai"
      refute result =~ "Grimshaw"
    end

    test "shows alone message when only current player is present" do
      block_info = %{
        description: "A dark corridor.",
        people: [Person.new("Grimshaw")]
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "A dark corridor."
      assert result =~ "You are alone here."
    end
  end

  describe "describe_people/2" do
    test "shows alone message when only the current player is present" do
      people = [Person.new("Grimshaw")]

      assert View.describe_people(people, "Grimshaw") == "You are alone here."
    end

    test "shows alone message when no one is present" do
      assert View.describe_people([], "Grimshaw") == "You are alone here."
    end

    test "lists other players, excluding the current player" do
      people = [Person.new("Grimshaw"), Person.new("Mordecai")]

      assert View.describe_people(people, "Grimshaw") == "Present: Mordecai"
    end

    test "lists multiple other players" do
      people = [Person.new("Grimshaw"), Person.new("Mordecai"), Person.new("Vesper")]

      result = View.describe_people(people, "Grimshaw")

      assert result =~ "Mordecai"
      assert result =~ "Vesper"
      refute result =~ "Grimshaw"
    end
  end
end
