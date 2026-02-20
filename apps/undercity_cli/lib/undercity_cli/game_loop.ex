defmodule UndercityCli.GameLoop do
  @moduledoc """
  Interactive command loop for the CLI game.
  """

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View
  alias UndercityCli.View.Constitution

  def run(player, player_id, vicinity, ap, hp) do
    View.init(vicinity, player, ap, hp)
    loop(player, player_id, vicinity, ap, hp)
  end

  defp loop(player, player_id, vicinity, ap, hp) do
    View.render_messages(MessageBuffer.flush())
    input = View.read_input() |> String.trim() |> String.downcase()

    case input do
      x when x in ["quit", "q"] ->
        :ok

      _ ->
        case Commands.dispatch(input, player_id, vicinity, ap, hp) do
          {:moved, new_state} ->
            View.render_surroundings(new_state.vicinity)
            View.render_description(new_state.vicinity, player)
            MessageBuffer.push(Constitution.threshold_messages(ap, new_state.ap, hp, new_state.hp))
            loop(player, player_id, new_state.vicinity, new_state.ap, new_state.hp)

          {:continue, new_state} ->
            MessageBuffer.push(Constitution.threshold_messages(ap, new_state.ap, hp, new_state.hp))
            loop(player, player_id, new_state.vicinity, new_state.ap, new_state.hp)
        end
    end
  end
end
