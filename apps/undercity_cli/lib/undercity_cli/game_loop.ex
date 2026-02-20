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
          {:moved, new_vicinity, new_ap, new_hp} ->
            View.render_surroundings(new_vicinity)
            View.render_description(new_vicinity, player)
            MessageBuffer.push(Constitution.threshold_messages(ap, new_ap, hp, new_hp))
            loop(player, player_id, new_vicinity, new_ap, new_hp)

          {:acted, new_ap, new_hp} ->
            MessageBuffer.push(Constitution.threshold_messages(ap, new_ap, hp, new_hp))
            loop(player, player_id, vicinity, new_ap, new_hp)
        end
    end
  end
end
