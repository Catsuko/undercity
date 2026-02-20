defmodule Mix.Tasks.Undercity.Join do
  @shortdoc "Join an Undercity game server"

  @moduledoc false
  use Mix.Task

  alias UndercityCli.GameLoop
  alias UndercityCli.GameState
  alias UndercityCli.Spinner
  alias UndercityServer.Vicinity

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [player: :string])
    player = opts[:player] || "anonymous"

    Spinner.start()

    case UndercityServer.Gateway.connect(player) do
      {:ok, {player_id, vicinity, constitution}} ->
        Spinner.success("Woke up in #{Vicinity.name(vicinity)} as #{player}")
        Spinner.dismiss()
        state = %GameState{player_id: player_id, vicinity: vicinity, ap: constitution.ap, hp: constitution.hp}
        GameLoop.run(player, state)

      {:error, :server_not_found} ->
        Spinner.failure("Could not reach the server")

      {:error, :server_down} ->
        Spinner.failure("Could not reach the server")
    end
  end
end
