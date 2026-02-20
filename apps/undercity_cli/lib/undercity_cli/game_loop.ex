defmodule UndercityCli.GameLoop do
  @moduledoc """
  Interactive command loop for the CLI game.
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View
  alias UndercityCli.View.Constitution
  alias UndercityServer.Gateway

  def run(player, %GameState{} = state) do
    View.init(state.vicinity, player, state.ap, state.hp)
    loop(player, state)
  end

  defp loop(player, state) do
    View.render_messages(MessageBuffer.flush())
    input = View.read_input() |> String.trim() |> String.downcase()

    case input do
      x when x in ["quit", "q"] ->
        :ok

      _ ->
        case Commands.dispatch(input, state, Gateway, MessageBuffer) do
          {:moved, new_state} ->
            View.render_surroundings(new_state.vicinity)
            View.render_description(new_state.vicinity, player)
            MessageBuffer.push(Constitution.threshold_messages(state.ap, new_state.ap, state.hp, new_state.hp))
            loop(player, new_state)

          {:continue, new_state} ->
            MessageBuffer.push(Constitution.threshold_messages(state.ap, new_state.ap, state.hp, new_state.hp))
            loop(player, new_state)
        end
    end
  end
end
