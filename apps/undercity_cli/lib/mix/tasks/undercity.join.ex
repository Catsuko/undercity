defmodule Mix.Tasks.Undercity.Join do
  @shortdoc "Join an Undercity game server"

  @moduledoc """
  Mix task that connects to a running Undercity server and launches the CLI.

  - Accepts `--player <name>` to set the player name (defaults to `"anonymous"`)
  - Displays an animated spinner while connecting via `UndercityServer.Gateway.connect/1`
  - On success, configures application env and starts the Ratatouille runtime with `UndercityCli.App`
  - On failure, prints an error via the spinner and exits
  """
  use Mix.Task

  alias UndercityCli.App
  alias UndercityCli.Spinner
  alias UndercityCli.State
  alias UndercityServer.Vicinity

  @doc false
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
          message_log: [],
          gateway: UndercityServer.Gateway,
          window_width: 80
        }

        Application.put_env(:undercity_cli, :context, %{
          player: player,
          game_state: state,
          gateway: UndercityServer.Gateway
        })

        Ratatouille.run(App)

      {:error, :invalid_name} ->
        Spinner.failure("Player name must be alphanumeric (letters and numbers only)")

      {:error, :server_not_found} ->
        Spinner.failure("Could not reach the server")

      {:error, :server_down} ->
        Spinner.failure("Could not reach the server")
    end
  end
end
