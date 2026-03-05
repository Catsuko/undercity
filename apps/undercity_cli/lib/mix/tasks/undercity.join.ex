defmodule Mix.Tasks.Undercity.Join do
  @shortdoc "Join an Undercity game server"

  @moduledoc false
  use Mix.Task

  alias UndercityCli.App
  alias UndercityCli.Spinner
  alias UndercityCli.State
  alias UndercityServer.Vicinity

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [player: :string])
    player = opts[:player] || "anonymous"

    Spinner.start()

    case UndercityServer.Gateway.connect(player) do
      {:ok, {player_id, vicinity, constitution}} ->
        Spinner.success("Woke up in #{Vicinity.name(vicinity)} as #{player}")
        Spinner.dismiss()

        state = %State{
          player_id: player_id,
          player_name: player,
          vicinity: vicinity,
          ap: constitution.ap,
          hp: constitution.hp,
          input: "",
          messages: [],
          gateway: UndercityServer.Gateway,
          window_width: 80
        }

        Application.put_env(:undercity_cli, :context, %{
          player: player,
          game_state: state,
          gateway: UndercityServer.Gateway
        })

        Ratatouille.run(App)

      {:error, :server_not_found} ->
        Spinner.failure("Could not reach the server")

      {:error, :server_down} ->
        Spinner.failure("Could not reach the server")
    end
  end
end
