defmodule UndercityCli.ViewTest do
  use ExUnit.Case, async: true

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

  describe "render/3" do
    test "updates LiveScreen blocks without crashing" do
      View.render(@vicinity, @player)
    end

    test "accepts messages" do
      View.render(@vicinity, @player, [{"Hello", :info}])
    end
  end

  describe "render_move/5" do
    test "renders on successful move" do
      new_vicinity = %{@vicinity | id: "alley"}
      View.render_move({:ok, {:ok, new_vicinity}, 8}, @vicinity, @player, 10, 5)
    end

    test "renders warning when no exit" do
      View.render_move({:ok, {:error, :no_exit}, 8}, @vicinity, @player, 10, 5)
    end

    test "renders inability message on error" do
      View.render_move({:error, :exhausted}, @vicinity, @player, 10, 5)
    end
  end

  describe "render_search/5" do
    test "renders found item" do
      View.render_search({:ok, {:found, %{name: "Junk"}}, 8}, @vicinity, @player, 10, 5)
    end

    test "renders found but inventory full" do
      View.render_search({:ok, {:found_but_full, %{name: "Junk"}}, 8}, @vicinity, @player, 10, 5)
    end

    test "renders nothing found" do
      View.render_search({:ok, :nothing, 8}, @vicinity, @player, 10, 5)
    end

    test "renders inability message on error" do
      View.render_search({:error, :collapsed}, @vicinity, @player, 10, 5)
    end
  end

  describe "render_inventory/3" do
    test "renders empty inventory" do
      View.render_inventory([], @vicinity, @player)
    end

    test "renders items" do
      View.render_inventory([%{name: "Junk"}, %{name: "Chalk"}], @vicinity, @player)
    end
  end

  describe "render_drop/5" do
    test "renders dropped item" do
      View.render_drop({:ok, "Junk", 8}, @vicinity, @player, 10, 5)
    end

    test "renders invalid index" do
      View.render_drop({:error, :invalid_index}, @vicinity, @player, 10, 5)
    end

    test "renders inability message on error" do
      View.render_drop({:error, :exhausted}, @vicinity, @player, 10, 5)
    end
  end

  describe "render_eat/5" do
    test "renders eaten item" do
      View.render_eat({:ok, %{name: "Bread"}, :restore, 8, 6}, @vicinity, @player, 10, 5)
    end

    test "renders not edible" do
      View.render_eat({:error, :not_edible, "Junk"}, @vicinity, @player, 10, 5)
    end

    test "renders invalid index" do
      View.render_eat({:error, :invalid_index}, @vicinity, @player, 10, 5)
    end

    test "renders inability message on error" do
      View.render_eat({:error, :collapsed}, @vicinity, @player, 10, 5)
    end
  end

  describe "render_scribble/5" do
    test "renders successful scribble" do
      View.render_scribble({:ok, 8}, @vicinity, @player, 10, 5)
    end

    test "renders scribble on tombstone for graveyard" do
      graveyard = %{@vicinity | type: :graveyard}
      View.render_scribble({:ok, 8}, graveyard, @player, 10, 5)
    end

    test "renders empty message scribble" do
      View.render_scribble({:error, :empty_message}, @vicinity, @player, 10, 5)
    end

    test "renders no chalk" do
      View.render_scribble({:error, :item_missing}, @vicinity, @player, 10, 5)
    end

    test "renders inability message on error" do
      View.render_scribble({:error, :exhausted}, @vicinity, @player, 10, 5)
    end
  end

  describe "render_unknown_command/2" do
    test "renders help text" do
      View.render_unknown_command(@vicinity, @player)
    end
  end
end
