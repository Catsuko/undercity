defmodule UndercityCli.ViewTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias UndercityCli.View
  alias UndercityServer.Vicinity

  @vicinity %Vicinity{
    id: "plaza",
    type: :square,
    people: [],
    neighbourhood: [[nil, nil, nil], [nil, "plaza", nil], [nil, nil, nil]],
    building_type: nil
  }

  @player "Grimshaw"

  describe "render/2" do
    test "renders surroundings and block description" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}],
        neighbourhood: [
          ["ashwell", "north_alley", "wormgarden"],
          ["west_street", "plaza", "east_street"],
          ["the_stray", "south_alley", "lame_horse"]
        ],
        building_type: nil
      }

      output = capture_io(fn -> View.render(vicinity, "Grimshaw") end)

      # Grid
      assert output =~ "┌"
      assert output =~ "The Plaza"
      # Description
      assert output =~ "You are at"
      assert output =~ "A wide, open space"
      # People
      assert output =~ "Mordecai"
    end

    test "clears screen before rendering" do
      output = capture_io(fn -> View.render(@vicinity, @player) end)

      assert output =~ "\e[2J"
    end
  end

  describe "render_message/1" do
    test "prints formatted message" do
      output = capture_io(fn -> View.render_message({"You found Junk!", :success}) end)

      assert output =~ "▸ You found Junk!"
    end

    test "does nothing for nil" do
      output = capture_io(fn -> View.render_message(nil) end)

      assert output == ""
    end
  end

  describe "render_move/5" do
    test "renders new vicinity on successful move" do
      new_vicinity = %{@vicinity | id: "alley"}

      output =
        capture_io(fn ->
          View.render_move({:ok, {:ok, new_vicinity}, 8}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You are at"
    end

    test "renders warning when no exit" do
      output =
        capture_io(fn ->
          View.render_move({:ok, {:error, :no_exit}, 8}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You can't go that way."
    end

    test "renders inability message on error" do
      output =
        capture_io(fn ->
          View.render_move({:error, :exhausted}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You are too exhausted to act."
    end
  end

  describe "render_search/5" do
    test "renders found item" do
      output =
        capture_io(fn ->
          View.render_search({:ok, {:found, %{name: "Junk"}}, 8}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You found Junk!"
    end

    test "renders found but inventory full" do
      output =
        capture_io(fn ->
          View.render_search(
            {:ok, {:found_but_full, %{name: "Junk"}}, 8},
            @vicinity,
            @player,
            10,
            5
          )
        end)

      assert output =~ "but your inventory is full"
    end

    test "renders nothing found" do
      output =
        capture_io(fn ->
          View.render_search({:ok, :nothing, 8}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You find nothing."
    end

    test "renders inability message on error" do
      output =
        capture_io(fn ->
          View.render_search({:error, :collapsed}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "Your body has given out."
    end
  end

  describe "render_inventory/3" do
    test "renders empty inventory" do
      output = capture_io(fn -> View.render_inventory([], @vicinity, @player) end)

      assert output =~ "Your inventory is empty."
    end

    test "renders items" do
      items = [%{name: "Junk"}, %{name: "Chalk"}]
      output = capture_io(fn -> View.render_inventory(items, @vicinity, @player) end)

      assert output =~ "Inventory: Junk, Chalk"
    end
  end

  describe "render_drop/5" do
    test "renders dropped item" do
      output =
        capture_io(fn ->
          View.render_drop({:ok, "Junk", 8}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You dropped Junk."
    end

    test "renders invalid index" do
      output =
        capture_io(fn ->
          View.render_drop({:error, :invalid_index}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "Invalid item selection."
    end

    test "renders inability message on error" do
      output =
        capture_io(fn ->
          View.render_drop({:error, :exhausted}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You are too exhausted to act."
    end
  end

  describe "render_eat/5" do
    test "renders eaten item" do
      output =
        capture_io(fn ->
          View.render_eat({:ok, %{name: "Bread"}, :restore, 8, 6}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "Ate a Bread."
    end

    test "renders not edible" do
      output =
        capture_io(fn ->
          View.render_eat({:error, :not_edible, "Junk"}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You can't eat Junk."
    end

    test "renders invalid index" do
      output =
        capture_io(fn ->
          View.render_eat({:error, :invalid_index}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "Invalid item selection."
    end

    test "renders inability message on error" do
      output =
        capture_io(fn ->
          View.render_eat({:error, :collapsed}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "Your body has given out."
    end
  end

  describe "render_scribble/5" do
    test "renders successful scribble" do
      output =
        capture_io(fn ->
          View.render_scribble({:ok, 8}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You scribble on the ground."
    end

    test "renders scribble on tombstone for graveyard" do
      graveyard = %{@vicinity | type: :graveyard}

      output =
        capture_io(fn ->
          View.render_scribble({:ok, 8}, graveyard, @player, 10, 5)
        end)

      assert output =~ "You scribble on a tombstone."
    end

    test "renders empty message scribble" do
      output =
        capture_io(fn ->
          View.render_scribble({:error, :empty_message}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You scribble on the ground."
    end

    test "renders no chalk" do
      output =
        capture_io(fn ->
          View.render_scribble({:error, :item_missing}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You have no chalk."
    end

    test "renders inability message on error" do
      output =
        capture_io(fn ->
          View.render_scribble({:error, :exhausted}, @vicinity, @player, 10, 5)
        end)

      assert output =~ "You are too exhausted to act."
    end
  end

  describe "render_unknown_command/2" do
    test "renders help text" do
      output = capture_io(fn -> View.render_unknown_command(@vicinity, @player) end)

      assert output =~ "Unknown command"
      assert output =~ "look"
      assert output =~ "search"
    end
  end
end
