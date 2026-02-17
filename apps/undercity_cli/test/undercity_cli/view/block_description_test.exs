defmodule UndercityCli.View.BlockDescriptionTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View.BlockDescription

  describe "describe_people/2" do
    test "shows alone message when only the current player is present" do
      people = [%{id: "1", name: "Grimshaw"}]

      assert BlockDescription.describe_people(people, "Grimshaw") == "You are alone here."
    end

    test "shows alone message when no one is present" do
      assert BlockDescription.describe_people([], "Grimshaw") == "You are alone here."
    end

    test "lists other players, excluding the current player" do
      people = [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}]

      assert BlockDescription.describe_people(people, "Grimshaw") == "Present: Mordecai"
    end

    test "lists multiple other players" do
      people = [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}, %{id: "3", name: "Vesper"}]

      result = BlockDescription.describe_people(people, "Grimshaw")

      assert result =~ "Mordecai"
      assert result =~ "Vesper"
      refute result =~ "Grimshaw"
    end
  end
end
