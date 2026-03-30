defmodule UndercityCli.Commands.SearchTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Search

  test "search returns model with updated ap" do
    expect(Gateway, :perform, fn @player_id, @block_id, :search, _ -> {:ok, 9} end)
    result = Search.dispatch("search", @state)
    assert result.ap == 9
  end
end
