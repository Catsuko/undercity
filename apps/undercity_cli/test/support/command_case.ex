defmodule UndercityCli.CommandCase do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case, async: true
      use Mimic

      alias UndercityCli.MessageBuffer
      alias UndercityCli.State
      alias UndercityServer.Gateway
      alias UndercityServer.Vicinity

      @player_id "player1"
      @block_id "block1"
      @state %State{
        player_id: @player_id,
        player_name: "player1",
        vicinity: %Vicinity{id: @block_id},
        ap: 10,
        hp: 10,
        input: "",
        messages: [],
        gateway: Gateway,
        window_width: 80
      }
    end
  end
end
