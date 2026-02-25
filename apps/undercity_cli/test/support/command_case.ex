defmodule UndercityCli.CommandCase do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case, async: true
      use Mimic

      alias UndercityCli.GameState
      alias UndercityCli.MessageBuffer
      alias UndercityServer.Gateway
      alias UndercityServer.Vicinity

      @player_id "player1"
      @block_id "block1"
      @state %GameState{player_id: @player_id, vicinity: %Vicinity{id: @block_id}, ap: 10, hp: 10}
    end
  end
end
